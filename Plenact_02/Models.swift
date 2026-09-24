import Foundation

struct KanbanCard: Identifiable, Hashable {
    let id: Int
    let word: String
    let listTitle: String

    var subtitle: String {
        ["A small idea with suspiciously large ambitions", "Make progress before the coffee gets cold", "A practical plan, lightly seasoned with chaos", "One more useful thing for today's board", "Future success, pending a snack break"][id % 5]
    }

    var checklistItems: [String] {
        ["Gather the important bits", "Make it look intentional", "Celebrate the surprisingly good result"]
    }

    var completedChecklistItems: Int {
        id % 4
    }

    var commentCount: Int {
        id % 4
    }

    var hasDueDate: Bool {
        id % 3 != 1
    }

    var funParagraph: String {
        let templates: [(String, String) -> String] = [
            { word, title in
                "Deep within the \(title) list, a \(word) staged a one-creature protest, demanding better lighting and a snack table. Management is 'reviewing the request', which is corporate for 'ignoring it politely'."
            },
            { word, title in
                "Legend has it that this \(word) was smuggled onto the \(title) board during a coffee run and has since filed three noise complaints against the stapler."
            },
            { word, title in
                "Nobody remembers hiring the \(word), yet here it sits on the \(title) list, quietly rearranging sticky notes into passive-aggressive haiku."
            },
            { word, title in
                "According to office folklore, the \(word) on the \(title) list once won a staring contest with the printer and hasn't blinked since."
            },
            { word, title in
                "The \(word) insists it is 'just visiting' the \(title) list, despite having set up a tiny desk, a tinier chair, and a nameplate that reads 'Regional Manager'."
            },
            { word, title in
                "Reports from the \(title) list describe a \(word) attempting to unionize the paperclips, citing 'unbearable working conditions near the shredder'."
            },
            { word, title in
                "This \(word) arrived on the \(title) list via interoffice mail, addressed to 'Whoever Needs the Most Chaos Today', and promptly took over the group chat."
            },
            { word, title in
                "Witnesses on the \(title) list swear the \(word) can predict meetings that will run long, mostly because it brings its own pillow."
            },
            { word, title in
                "The \(word) has been spotted on the \(title) list rehearsing an acceptance speech for an award that does not exist, in front of an audience that also does not exist."
            },
            { word, title in
                "Somewhere between the third and fourth cup of coffee, a \(word) wandered onto the \(title) list and decided it was now in charge of snack inventory."
            }
        ]
        let template = templates[id % templates.count]
        return template(word, listTitle)
    }
}

struct KanbanList: Identifiable {
    let id: Int
    let title: String
    let cards: [KanbanCard]

    var subtitle: String {
        ["Ideas taking shape", "Ready for a little momentum", "Currently in progress", "Nearly across the finish line", "Done, or at least confidently presented"][id]
    }
}

enum SampleData {
    static let words: [String] = [
        "rabbit", "toaster", "kazoo", "lampshade", "spatula",
        "narwhal", "cactus", "bagpipe", "waffle", "penguin",
        "gnome", "trombone", "pickle", "yeti", "flamingo",
        "banjo", "pretzel", "octopus", "unicorn", "turnip",
        "walrus", "accordion", "hedgehog", "kettle", "tumbleweed",
        "platypus", "harmonica", "meatball", "raccoon", "umbrella",
        "otter", "xylophone", "dumpling", "chinchilla", "teapot",
        "armadillo", "clarinet", "burrito", "mongoose", "whisk",
        "llama", "ukulele", "croissant", "wombat", "colander",
        "ferret", "tambourine", "avocado", "meerkat", "spork"
    ]

    static let listTitles = ["First", "Second", "Third", "Fourth", "Fifth"]

    static let lists: [KanbanList] = {
        var globalIndex = 0
        return listTitles.enumerated().map { listIndex, title in
            let cards = (0..<10).map { _ -> KanbanCard in
                let card = KanbanCard(id: globalIndex, word: words[globalIndex % words.count], listTitle: title)
                globalIndex += 1
                return card
            }
            return KanbanList(id: listIndex, title: title, cards: cards)
        }
    }()
}
