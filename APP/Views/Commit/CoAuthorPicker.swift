import GitOKUI
import GitOKSupportKit
import ProjectSupportKit
import SwiftUI

/// 合作者选择器：允许用户添加和选择共同作者
struct CoAuthorPicker: View {
    @Binding var selectedCoAuthors: [CoAuthor]
    @State private var showAddSheet = false

    var body: some View {
        HStack(spacing: 8) {
            // 已选择的合作者徽章
            ForEach(selectedCoAuthors) { coauthor in
                CoAuthorBadge(
                    coauthor: coauthor,
                    onRemove: {
                        selectedCoAuthors.removeAll { $0.id == coauthor.id }
                    }
                )
            }

            // 添加合作者按钮
            AppIconButton(systemImage: "plus.circle.fill", tint: .secondary, size: .compact) {
                showAddSheet = true
            }
            .help("添加合作者")
        }
        .sheet(isPresented: $showAddSheet) {
            CoAuthorSheet(
                selectedCoAuthors: $selectedCoAuthors,
                isPresented: $showAddSheet
            )
        }
    }
}

/// 合作者徽章：显示已选择的合作者
struct CoAuthorBadge: View {
    let coauthor: CoAuthor
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.system(size: 10))
                .foregroundColor(.white)

            Text(coauthor.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)

            AppIconButton(systemImage: "xmark", tint: .white, size: .compact) {
                onRemove()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .gitOKUISurface(style: .custom(.blue), cornerRadius: 12)
    }
}

/// 合作者添加表单
struct CoAuthorSheet: View {
    @Binding var selectedCoAuthors: [CoAuthor]
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var availableCoAuthors: [CoAuthor] = []
    @State private var showCustomAdd = false

    private let store = CoAuthorStore.shared

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            Text("添加合作者")
                .font(.headline)

            // 快速选择常用合作者
            if !availableCoAuthors.isEmpty && !showCustomAdd {
                VStack(alignment: .leading, spacing: 8) {
                    Text("常用合作者")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(availableCoAuthors) { coauthor in
                            CoAuthorQuickSelectButton(
                                coauthor: coauthor,
                                isSelected: selectedCoAuthors.contains(where: { $0.id == coauthor.id }),
                                onSelect: {
                                    toggleCoAuthor(coauthor)
                                }
                            )
                        }
                    }
                }

                Divider()

                AppButton("添加新的合作者", systemImage: "plus", style: .secondary, size: .small) {
                    showCustomAdd = true
                }
            }

            // 自定义添加表单
            if showCustomAdd {
                VStack(alignment: .leading, spacing: 12) {
                    Text("新合作者信息")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    AppInputField("姓名", text: $name)

                    AppInputField("邮箱", text: $email)

                    HStack(spacing: 12) {
                        AppButton("取消", style: .secondary, size: .small) {
                            showCustomAdd = false
                            name = ""
                            email = ""
                        }
                        .keyboardShortcut(.cancelAction)

                        AppButton("添加", systemImage: "plus", style: .primary, size: .small) {
                            addNewCoAuthor()
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(name.isEmpty || email.isEmpty)
                    }
                }
            }

            Divider()

            // 已选择的合作者
            if !selectedCoAuthors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已选择 (\(selectedCoAuthors.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(selectedCoAuthors) { coauthor in
                        HStack {
                            Text(coauthor.displayText)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            AppIconButton(systemImage: "minus.circle.fill", tint: .red, size: .compact) {
                                selectedCoAuthors.removeAll { $0.id == coauthor.id }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // 底部操作按钮
            HStack(spacing: 12) {
                AppButton("取消", style: .secondary) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                AppButton("确定", systemImage: "checkmark", style: .primary) {
                    // 保存新添加的合作者到常用列表
                    for coauthor in selectedCoAuthors {
                        store.addCoAuthor(coauthor)
                    }
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
        .onAppear {
            availableCoAuthors = store.loadCoAuthors()
        }
    }

    private func toggleCoAuthor(_ coauthor: CoAuthor) {
        if selectedCoAuthors.contains(where: { $0.id == coauthor.id }) {
            selectedCoAuthors.removeAll { $0.id == coauthor.id }
        } else {
            selectedCoAuthors.append(coauthor)
        }
    }

    private func addNewCoAuthor() {
        let newCoAuthor = CoAuthor(name: name, email: email)
        selectedCoAuthors.append(newCoAuthor)
        store.addCoAuthor(newCoAuthor)

        // 重置表单
        name = ""
        email = ""
        showCustomAdd = false
    }
}

/// 快速选择按钮
struct CoAuthorQuickSelectButton: View {
    let coauthor: CoAuthor
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        AppSelectionTile(
            isSelected: isSelected,
            cornerRadius: 6,
            selectedBackgroundColor: Color.blue.opacity(0.1),
            action: onSelect
        ) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(coauthor.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(coauthor.email)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(8)
        }
    }
}

// MARK: - Preview

#Preview("CoAuthor Picker") {
    CoAuthorPicker(selectedCoAuthors: .constant([]))
        .padding()
}

#Preview("CoAuthor Sheet") {
    CoAuthorSheet(
        selectedCoAuthors: .constant([]),
        isPresented: .constant(true)
    )
}
