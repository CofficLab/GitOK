import LumiUI
import ProviderProjects
import SwiftUI

/// LICENSE 查看器：等宽字体展示内容，可选中复制；不存在时可新建空文件。
public struct LicenseViewer: View {
    let projects: any ProjectProviding
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isLoading = true
    @State private var exists = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView([.vertical, .horizontal]) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.plaintext")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("LICENSE")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(projects.currentProject?.title ?? "")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            if !exists {
                AppButton("Create", systemImage: "plus", style: .secondary, size: .small) {
                    createLicense()
                }
            }
            AppButton("Close", style: .secondary, size: .small) {
                dismiss()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func load() {
        guard let url = projects.currentProject?.url else {
            content = ""
            isLoading = false
            return
        }
        let license = url.appendingPathComponent("LICENSE")
        Task.detached(priority: .userInitiated) {
            let fileExists = FileManager.default.fileExists(atPath: license.path)
            let text = fileExists ? ((try? String(contentsOf: license, encoding: .utf8)) ?? "") : ""
            await MainActor.run {
                exists = fileExists
                content = text
                isLoading = false
            }
        }
    }

    private func createLicense() {
        guard let url = projects.currentProject?.url else { return }
        let license = url.appendingPathComponent("LICENSE")
        let placeholder = """
        Copyright (c) \(Calendar.current.component(.year, from: Date())) Your Name

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software...
        """
        do {
            try placeholder.write(to: license, atomically: true, encoding: .utf8)
            content = placeholder
            exists = true
        } catch {
            // 保持现状；用户在 Finder 中手动处理。
        }
    }

    @LumiTheme private var theme: LumiUITheme
}
