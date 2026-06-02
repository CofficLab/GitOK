import SwiftUI

public enum GitOKTransition {
    public static func messageInsertion(reduceMotion: Bool) -> AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            )
    }

    public static func disclosureContent(reduceMotion: Bool) -> AnyTransition {
        reduceMotion
            ? .opacity
            : .opacity.combined(with: .move(edge: .top))
    }

    public static func statusPresentation(reduceMotion: Bool) -> AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)),
                removal: .opacity
            )
    }

    public static func messageInsertion(preference: GitOKMotionPreference) -> AnyTransition {
        messageInsertion(reduceMotion: !preference.allowsListMotion)
    }

    public static func disclosureContent(preference: GitOKMotionPreference) -> AnyTransition {
        disclosureContent(reduceMotion: !preference.allowsMotion)
    }

    public static func statusPresentation(preference: GitOKMotionPreference) -> AnyTransition {
        statusPresentation(reduceMotion: !preference.allowsMotion)
    }
}

public extension View {
    func appMessageInsertionTransition(reduceMotion: Bool) -> some View {
        transition(GitOKTransition.messageInsertion(reduceMotion: reduceMotion))
    }

    func appMessageInsertionTransition(preference: GitOKMotionPreference) -> some View {
        transition(GitOKTransition.messageInsertion(preference: preference))
    }

    func appDisclosureContentTransition(reduceMotion: Bool) -> some View {
        transition(GitOKTransition.disclosureContent(reduceMotion: reduceMotion))
    }

    func appDisclosureContentTransition(preference: GitOKMotionPreference) -> some View {
        transition(GitOKTransition.disclosureContent(preference: preference))
    }

    func appStatusPresentationTransition(reduceMotion: Bool) -> some View {
        transition(GitOKTransition.statusPresentation(reduceMotion: reduceMotion))
    }

    func appStatusPresentationTransition(preference: GitOKMotionPreference) -> some View {
        transition(GitOKTransition.statusPresentation(preference: preference))
    }
}
