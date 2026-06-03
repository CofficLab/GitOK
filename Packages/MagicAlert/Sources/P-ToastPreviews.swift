#if DEBUG
    import SwiftUI

    struct MagicToastExampleView: View {
        var body: some View {
            let L = MagicAlertLocalization.self

            VStack(spacing: 20) {
                Text(L.string("Global Function Demo"))
                    .font(.title)
                    .padding(.bottom)

                Button(L.string("Info - Short Text")) {
                    alert_info("This is info", subtitle: "Detailed description")
                }

                Button(L.string("Info - Long Text")) {
                    alert_info("Start downloading your selected document")
                }

                Button(L.string("Success")) {
                    alert_success("Operation successful")
                }

                Button(L.string("Warning")) {
                    alert_warning("Please note")
                }

                Button(L.string("Error - Toast View")) {
                    alert_error("Operation failed", autoDismiss: false)
                }

                Button(L.string("Error - Detail View")) {
                    let customError = NSError(
                        domain: "com.magickit.test",
                        code: 1001,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Network connection failed, unable to access server endpoint",
                            NSLocalizedFailureReasonErrorKey: "Server response timed out, possibly due to network instability, server maintenance, or firewall blocking",
                            NSLocalizedRecoverySuggestionErrorKey: "Please check your network connection status, confirm VPN settings, and try again later. If the problem persists, contact the technical support team.",
                            NSHelpAnchorErrorKey: "Visit the help center for more network troubleshooting information and FAQs",
                        ]
                    )
                    alert_error(customError, title: "Network Request Failed")
                }

                Button(L.string("Loading")) {
                    alert_loading("Processing...")
                }

                Button(L.string("Hide Loading")) {
                    alert_dismiss_loading()
                }

                Button(L.string("Dismiss All")) {
                    alert_dismiss_all()
                }
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
#endif

#if DEBUG
    #Preview("Normal Width") {
        MagicToastExampleView()
            .withMagicToast()
            .frame(width: 600, height: 600)
    }

    #Preview("Narrow Width") {
        MagicToastExampleView()
            .withMagicToast()
            .frame(width: 320, height: 600)
    }

    #Preview("iPad Width") {
        MagicToastExampleView()
            .withMagicToast()
            .frame(width: 800, height: 600)
    }
#endif
