import SwiftUI

public struct GitOKMotionPreference: Equatable, Sendable {
    public var reduceMotion: Bool
    public var disableAnimations: Bool
    public var disableListAnimations: Bool

    public init(
        reduceMotion: Bool = false,
        disableAnimations: Bool = false,
        disableListAnimations: Bool = false
    ) {
        self.reduceMotion = reduceMotion
        self.disableAnimations = disableAnimations
        self.disableListAnimations = disableListAnimations
    }

    public var allowsMotion: Bool {
        !reduceMotion && !disableAnimations
    }

    public var allowsListMotion: Bool {
        allowsMotion && !disableListAnimations
    }
}

private struct GitOKMotionPreferenceKey: EnvironmentKey {
    static let defaultValue = GitOKMotionPreference()
}

public extension EnvironmentValues {
    var gitOKMotionPreference: GitOKMotionPreference {
        get { self[GitOKMotionPreferenceKey.self] }
        set { self[GitOKMotionPreferenceKey.self] = newValue }
    }
}

@propertyWrapper
public struct GitOKMotionPreferenceReader: DynamicProperty {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.gitOKMotionPreference) private var preference

    public init() {}

    public var wrappedValue: GitOKMotionPreference {
        GitOKMotionPreference(
            reduceMotion: systemReduceMotion || preference.reduceMotion,
            disableAnimations: preference.disableAnimations,
            disableListAnimations: preference.disableListAnimations
        )
    }
}

public extension View {
    func gitOKMotionPreference(_ preference: GitOKMotionPreference) -> some View {
        environment(\.gitOKMotionPreference, preference)
    }

    func gitOKDisableAnimations(_ disabled: Bool = true) -> some View {
        transformEnvironment(\.gitOKMotionPreference) { preference in
            preference.disableAnimations = disabled
        }
    }

    func gitOKDisableListAnimations(_ disabled: Bool = true) -> some View {
        transformEnvironment(\.gitOKMotionPreference) { preference in
            preference.disableListAnimations = disabled
        }
    }
}
