import Foundation

enum LicenseTemplate: String, CaseIterable, Identifiable {
    case mit
    case apache2
    case gpl3

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mit: return PluginLicenseLocalization.string("MIT License")
        case .apache2: return PluginLicenseLocalization.string("Apache License 2.0")
        case .gpl3: return PluginLicenseLocalization.string("GPL v3")
        }
    }

    var content: String {
        switch self {
        case .mit: return MITLicense.template
        case .apache2: return Apache2License.template
        case .gpl3: return GPL3License.template
        }
    }

    var description: String {
        switch self {
        case .mit: return MITLicense.description
        case .apache2: return Apache2License.description
        case .gpl3: return GPL3License.description
        }
    }
}
