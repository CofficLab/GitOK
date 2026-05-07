import SwiftUI

import MagicAlert

/**
 经典模板的特性编辑器
 专门为经典布局定制的特性列表编辑组件
 */
struct ClassicFeaturesEditor: View {
    @EnvironmentObject var b: BannerProvider
    
    
    @State private var features: [String] = []
    @State private var newFeature: String = ""
    
    var body: some View {
        GroupBox("特性列表") {
            VStack(spacing: 12) {
                // 添加新特性
                HStack {
                    TextField("添加新特性", text: $newFeature)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addFeature()
                        }
                    
                    Button("添加", action: addFeature)
                        .disabled(newFeature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // 特性列表
                if !features.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            HStack {
                                Text("• \(feature)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    removeFeature(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } else {
                    Text("暂无特性")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(8)
        }
        .onAppear {
            loadCurrentFeatures()
        }
    }
    
    private func loadCurrentFeatures() {
        if let classicData = b.banner.classicData {
            features = classicData.features
        }
    }
    
    private func addFeature() {
        let trimmedFeature = newFeature.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFeature.isEmpty else { return }
        
        features.append(trimmedFeature)
        newFeature = ""
        updateFeatures()
    }
    
    private func removeFeature(at index: Int) {
        guard index < features.count else { return }
        features.remove(at: index)
        updateFeatures()
    }
    
    private func updateFeatures() {
        try? b.updateBanner { banner in
            var classicData = banner.classicData ?? ClassicBannerData()
            classicData.features = features
            banner.classicData = classicData
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
