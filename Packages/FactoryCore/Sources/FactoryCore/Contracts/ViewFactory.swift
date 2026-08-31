import KernelCore
import SwiftUI

/// Lumi-shaped view assembly boundary. Main and settings windows receive the
/// same kernel so Provider state and plugin contributions stay coherent.
@MainActor
public protocol ViewFactory {
    func makeMainView(kernel: KernelCoreContainer) throws -> AnyView
    func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView
}
