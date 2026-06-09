import GitOKFoundationKit
import SwiftUI
import OSLog

/// 用于展示当前应用所有 UserDefaults 键值对的视图
public struct MagicUserDefaultsView: View, SuperLog {
    nonisolated public static let emoji = "🔍"
    
    @State private var keyValuePairs: [(key: String, value: String)] = []
    @State private var searchText: String
    @State private var showingICloudValues: Bool = false
    
    /// 初始化方法
    /// - Parameter defaultSearchText: 默认的搜索文本，如果提供则在视图加载时自动填充到搜索框
    public init(defaultSearchText: String = "") {
        // 使用 _searchText 初始化 @State 变量
        self._searchText = State(initialValue: defaultSearchText)
    }
    
    var filteredPairs: [(key: String, value: String)] {
        if searchText.isEmpty {
            return keyValuePairs
        } else {
            return keyValuePairs.filter { pair in
                pair.key.localizedCaseInsensitiveContains(searchText) ||
                pair.value.localizedCaseInsensitiveContains(searchText)
            }
    }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UserDefaults 调试视图").font(.headline)
            
            HStack {
                TextField("搜索键或值", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Toggle("显示 iCloud 值", isOn: $showingICloudValues)
                    .onChange(of: showingICloudValues) { _ in
                        refreshData()
                    }
            }
            
            Divider()
            
            if filteredPairs.isEmpty {
                Text("没有找到匹配的键值对")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(filteredPairs, id: \.key) { pair in
                        VStack(alignment: .leading) {
                            Text(pair.key)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(pair.value)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            Divider()
            
            HStack {
                Button("刷新数据") {
                    refreshData()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Text("共 \(filteredPairs.count) 项")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            refreshData()
        }
    }
    
    /// 刷新显示的数据
    private func refreshData() {
        var pairs: [(key: String, value: String)] = []
        
        if showingICloudValues {
            // 获取 iCloud 键值对
            let store = NSUbiquitousKeyValueStore.default
            store.synchronize() // 确保获取最新数据
            
            let dictionary = store.dictionaryRepresentation
            for key in dictionary.keys.sorted() {
                if let value = dictionary[key] {
                    pairs.append((key: key, value: String(describing: value)))
                }
            }
        } else {
            // 获取 UserDefaults 键值对
            let defaults = UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            
            for key in dictionary.keys.sorted() {
                if let value = dictionary[key] {
                    pairs.append((key: key, value: String(describing: value)))
                }
            }
        }
        
        self.keyValuePairs = pairs
    }
}

