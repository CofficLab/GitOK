import Foundation

struct Doc {
    var uuid: String
    var title: String
    var image: String
    
    init(uuid: String, title: String, image: String) {
        self.uuid = uuid
        self.title = title
        self.image = image
    }
}

extension Doc: Hashable {
    static func == (lhs: Doc, rhs: Doc) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

extension Doc: Identifiable {
    var id: String {
        self.uuid
    }
}
