import Foundation

protocol TaskItem: Hashable, Identifiable {
    var title: String { get }
    var uuid: String {get}
}

