import SwiftUI
import MagicCore

/**
 经典模板的透明度编辑器
 专门为经典布局定制的透明度控制组件
 */
struct MinimalOpacityEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider
    
    @State private var opacity: Double = 1.0
    
    var body: some View {
        GroupBox("透明度设置") {
            VStack(spacing: 12) {
                HStack {
                    Slider(
                        value: Binding(
                            get: { opacity },
                            set: { newValue in
                                opacity = newValue
                                updateOpacity(newValue)
                            }
                        ),
                        in: 0.0...1.0,
                        step: 0.05
                    )
                    
                    Text("\(Int(opacity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .padding(8)
        }
        .onAppear {
            loadCurrentOpacity()
        }
    }
    
    private func loadCurrentOpacity() {
        opacity = b.banner.opacity
    }
    
    private func updateOpacity(_ newOpacity: Double) {
        try? b.updateBanner { banner in
            banner.opacity = newOpacity
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
