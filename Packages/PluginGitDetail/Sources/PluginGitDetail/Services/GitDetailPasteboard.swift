import AppKit

public enum GitDetailPasteboard {
    @discardableResult
    public static func writeString(
        _ text: String,
        pasteboard: NSPasteboard = .general
    ) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}

public enum GitDetailImageFactory {
    public static func image(from data: Data?) -> NSImage? {
        data.flatMap(NSImage.init(data:))
    }
}
