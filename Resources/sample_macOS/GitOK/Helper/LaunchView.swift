import SwiftUI

struct LanuchView: View {
    var errorMessage: String? = nil

    var body: some View {
        VStack {
            if errorMessage == nil {
                CardView(background: BackgroundView.type2) {
                    VStack {
                        Spacer()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()

                        let welcomeLabel = UILabel()
                        welcomeLabel.text = NSLocalizedString("welcome_message", comment: "Welcome message displayed on the home screen")

                        Text(welcomeLabel.text).font(.title).foregroundStyle(.white)
                        
                        Spacer()
                    }
                }.frame(width: 150, height: 150)
            } else {
                Text(errorMessage!)
            }
        }
    }
}

#Preview {
    VStack {
        LanuchView()

        Divider()

        LanuchView(errorMessage: "启动出现错误")
    }
}
