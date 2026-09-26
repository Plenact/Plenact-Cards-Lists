// --------------------------------------------------------------------------------------------------
// @file       PhotoAttachments.swift
// @brief      Photo attachment model, local file storage, and picker/gallery components
// @details    Imports image selections, stores photo bytes in the app container, and presents attached photos
//
// @author     Justin Reina, Firmware/Systems Engineering
// @created    9/26/26
// @last rev   9/26/26
//
// @notes      Cards persist attachment metadata and IDs; image data remains outside the board JSON
//
// --------------------------------------------------------------------------------------------------
import Foundation
import PhotosUI
import SwiftUI
import UIKit


///
/// Identifies one locally stored photo attached to a card
///
/// @section    Purpose
///     Persist the photo's stable identity, relative filename, and import date without embedding its bytes in the board
///
struct KanbanAttachment: Identifiable, Hashable, Codable {

    let id: UUID
    let fileName: String
    let addedAt: Date

    ///
    /// @fcn        KanbanAttachment.init(id:fileName:addedAt:)
    /// @brief      Initialize metadata for one stored photo attachment
    /// @details    Stores a stable attachment identity, its app-container filename, and its import timestamp
    ///
    /// @param[in]  id        Stable identifier for the attachment; generated when omitted
    /// @param[in]  fileName  Filename of the image data in the app's attachment directory
    /// @param[in]  addedAt   Import timestamp; defaults to the current date and time
    ///
    /// @return     (KanbanAttachment) configured photo attachment metadata
    ///
    /// @pre        fileName refers to the image data stored by CardAttachmentStore
    /// @post       The attachment metadata contains the supplied identity, path name, and timestamp
    ///
    init(id: UUID = UUID(), fileName: String, addedAt: Date = .now) {
        self.id = id
        self.fileName = fileName
        self.addedAt = addedAt
    }
}


///
/// Stores imported card photos in the app's private Documents directory
///
/// @section    Purpose
///     Keep image data out of UserDefaults while allowing board JSON to retain small attachment records
///
/// @note       Files no longer referenced by any card can be removed with removeUnreferencedFiles(keeping:)
///
enum CardAttachmentStore {

    private static let directoryName = "CardAttachments"

    ///
    /// @fcn        CardAttachmentStore.saveImage(_:)
    /// @brief      Save selected image data to the app's private attachment directory
    /// @details    Writes the image atomically under a unique filename and returns metadata referencing that file
    ///
    /// @param[in]  imageData  Encoded image data transferred from the system photo picker
    ///
    /// @return     (KanbanAttachment) metadata for the newly stored image
    ///
    /// @pre        imageData contains transferable image bytes
    /// @post       A new image file exists in the app's Documents/CardAttachments directory
    ///
    /// @throws     File-system error if the Documents directory cannot be obtained, created, or written
    ///
    static func saveImage(_ imageData: Data) throws -> KanbanAttachment {

        let attachmentID = UUID()
        let fileName     = "\(attachmentID.uuidString).image"
        let directoryURL = try attachmentsDirectory()
        let fileURL      = directoryURL.appendingPathComponent(fileName, isDirectory: false)

        try imageData.write(to: fileURL, options: .atomic)

        return KanbanAttachment(id: attachmentID, fileName: fileName)
    }

    ///
    /// @fcn        CardAttachmentStore.imageURL(for:)
    /// @brief      Resolve an attachment record to its local image URL
    /// @details    Combines the app's Documents directory, attachment subdirectory, and stored filename
    ///
    /// @param[in]  attachment  Metadata identifying the stored photo file
    ///
    /// @return     (URL?) local image URL, or nil when the Documents directory is unavailable
    ///
    /// @pre        attachment.fileName is the filename returned when the image was saved
    /// @post       No file data or attachment metadata is modified
    ///
    static func imageURL(for attachment: KanbanAttachment) -> URL? {

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        return documentsURL
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(attachment.fileName, isDirectory: false)
    }

    ///
    /// @fcn        CardAttachmentStore.removeUnreferencedFiles(keeping:)
    /// @brief      Remove stored image files no longer referenced by any card
    /// @details    Scans the attachment directory and deletes filenames absent from the supplied reference set
    ///
    /// @param[in]  fileNames  Filenames still referenced by the current board cards
    ///
    /// @return     (Void) removes unreferenced files when the attachment directory can be read
    ///
    /// @pre        fileNames represents the current persisted card attachment references
    /// @post       Referenced files remain; unreferenced files are removed when possible
    ///
    static func removeUnreferencedFiles(keeping fileNames: Set<String>) {

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let directoryURL = documentsURL.appendingPathComponent(directoryName, isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in files where !fileNames.contains(fileURL.lastPathComponent) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    ///
    /// @fcn        CardAttachmentStore.attachmentsDirectory
    /// @brief      Return the app's photo attachment directory
    /// @details    Resolves Documents/CardAttachments and creates the directory if it does not already exist
    ///
    /// @return     (URL) directory used to store imported card images
    ///
    /// @pre        The app has access to its user Documents directory
    /// @post       The returned directory exists and is ready to receive files
    ///
    /// @throws     CocoaError when the Documents directory is unavailable or directory creation fails
    ///
    private static func attachmentsDirectory() throws -> URL {

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let directoryURL = documentsURL.appendingPathComponent(directoryName, isDirectory: true)

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        return directoryURL
    }
}


///
/// Provides the Quick Action tile that opens the system photo picker
///
/// @section    Purpose
///     Let users select multiple images from their photo library for attachment to the open card
///
struct CardPhotoPickerTile: View {

    @Binding var selection: [PhotosPickerItem]

    ///
    /// @fcn        CardPhotoPickerTile.body
    /// @brief      Build the Add Attachment photo-picker tile
    /// @details    Presents the system photo library and allows selection of up to twelve images
    ///
    /// @return     (some View) styled Quick Action tile that updates the bound PhotosPickerItem selection
    ///
    /// @pre        selection is bound to the owning card detail view's import state
    /// @post       Chosen image items are returned through selection; no image files are written by this view
    ///
    var body: some View {

        PhotosPicker(selection: $selection, maxSelectionCount: 12, matching: .images) {

            Label("Add Attachment", systemImage: "paperclip")
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .tint(.cyan)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add photos to card")
    }
}


///
/// Displays a square thumbnail for an attached photo
///
/// @section    Purpose
///     Provide a compact preview for the attachment gallery in card details
///
struct CardAttachmentThumbnail: View {

    let attachment: KanbanAttachment

    ///
    /// @fcn        CardAttachmentThumbnail.body
    /// @brief      Build a square preview for an attached photo
    /// @details    Loads the local image file and displays a cropped thumbnail, or a photo placeholder if unavailable
    ///
    /// @return     (some View) square attachment thumbnail or missing-photo fallback
    ///
    /// @pre        attachment contains metadata for a local image file
    /// @post       Rendering does not modify the attachment or stored image data
    ///
    var body: some View {

        Group {

            if let imageURL = CardAttachmentStore.imageURL(for: attachment),
               let image = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}


///
/// Displays an attached photo at a larger size
///
/// @section    Purpose
///     Allow users to inspect a photo after opening its card-detail thumbnail
///
struct CardAttachmentPreview: View {

    let attachment: KanbanAttachment        /* The photo attachment to be previewed */

    @Environment(\.dismiss) private var dismiss

    ///
    /// @fcn        CardAttachmentPreview.body
    /// @brief      Build a large preview for an attached photo
    /// @details    Displays the local image scaled to fit, with a fallback view if the file is unavailable
    ///
    /// @return     (some View) navigable image preview with a Done action
    ///
    /// @pre        attachment identifies a photo previously imported for a card
    /// @post       The preview is shown without modifying the image or its metadata
    ///
    var body: some View {

        NavigationStack {
            Group {
        
                if let imageURL = CardAttachmentStore.imageURL(for: attachment),
                   let image = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ContentUnavailableView("Photo unavailable", systemImage: "photo")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Attachment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
