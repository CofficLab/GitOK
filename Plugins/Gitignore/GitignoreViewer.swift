import MagicCore
import OSLog
import SwiftUI

struct GitignoreViewer: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var content: String = ""
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    @State private var isApplyingTemplate: Bool = false
    @State private var isOrganizing: Bool = false
    @State private var statusMessage: String?

    private let verbose = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                if isLoading {
                    loadingView
                } else if hasError || content.isEmpty {
                    emptyView
                } else {
                    ScrollView([.vertical, .horizontal]) {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: loadGitignore)
        .onChange(of: data.project, loadGitignore)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.primary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(".gitignore")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let project = data.project {
                        Text(project.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                GitignoreOrganizerView(
                    content: $content,
                    isLoading: $isLoading,
                    isApplyingTemplate: $isApplyingTemplate,
                    isOrganizing: $isOrganizing,
                    statusMessage: $statusMessage
                )

                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("正在加载 .gitignore ...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("未找到 .gitignore 文件")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("当前项目中没有找到 .gitignore 文件")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
    }

    private func loadGitignore() {
        guard let project = data.project else {
            content = ""
            isLoading = false
            hasError = true
            return
        }

        isLoading = true
        hasError = false

        Task {
            do {
                let fileContent = try await project.getGitignoreContent()
                await MainActor.run {
                    self.content = fileContent
                    self.isLoading = false
                    self.hasError = false
                }
            } catch {
                await MainActor.run {
                    self.content = ""
                    self.isLoading = false
                    self.hasError = true
                }

                if verbose {
                    os_log(.info, "\(self.t)No .gitignore found or error reading: \(error.localizedDescription)")
                }
            }
        }
    }

    private func applyTemplate(_ template: GitignoreTemplate) {
        guard let project = data.project else {
            return
        }

        isApplyingTemplate = true
        statusMessage = nil

        Task {
            let url = URL(fileURLWithPath: project.path).appendingPathComponent(".gitignore")
            let fileManager = FileManager.default

            do {
                var existing = ""
                if fileManager.fileExists(atPath: url.path) {
                    existing = try String(contentsOf: url, encoding: .utf8)
                }

                let merged = mergeGitignore(existing: existing, template: template)
                try merged.write(to: url, atomically: true, encoding: .utf8)

                await MainActor.run {
                    self.content = merged
                    self.isLoading = false
                    self.hasError = false
                    self.isApplyingTemplate = false
                    self.statusMessage = "\(template.header) 已添加"
                }
            } catch {
                await MainActor.run {
                    self.isApplyingTemplate = false
                    self.statusMessage = "写入 .gitignore 失败：\(error.localizedDescription)"
                    self.hasError = true
                }

                if verbose {
                    os_log(.info, "\(self.t)Failed to apply template: \(error.localizedDescription)")
                }
            }
        }
    }

    private func mergeGitignore(existing: String, template: GitignoreTemplate) -> String {
        func normalizedKey(_ line: String) -> String {
            line.trimmingCharacters(in: .whitespaces)
        }

        let templateKeys = Set(template.lines.map(normalizedKey) + [normalizedKey(template.header)])

        var seen = Set<String>()
        var kept: [String] = []

        for line in existing.components(separatedBy: .newlines) {
            let key = normalizedKey(line)

            // 跳过模板中已有的行（无论出现在何处），等会统一追加到模板分组
            if templateKeys.contains(key) {
                continue
            }

            if key.isEmpty {
                if kept.last?.isEmpty == true {
                    continue
                }
                kept.append("")
                continue
            }

            if seen.contains(key) {
                continue
            }

            seen.insert(key)
            kept.append(line)
        }

        var additions: [String] = []
        var newEntries: [String] = []
        var templateSeen = Set<String>()

        for line in template.lines {
            let key = normalizedKey(line)
            if key.isEmpty || templateSeen.contains(key) {
                continue
            }
            templateSeen.insert(key)
            newEntries.append(line)
        }

        if newEntries.isEmpty {
            return kept.joined(separator: "\n")
        }

        if kept.last?.isEmpty == false {
            additions.append("")
        }

        let headerKey = normalizedKey(template.header)
        if seen.contains(headerKey) == false {
            additions.append(template.header)
            seen.insert(headerKey)
        }
        additions.append(contentsOf: newEntries)

        // 折叠添加部分内的空行重复
        var final = kept
        for line in additions {
            if line.trimmingCharacters(in: .whitespaces).isEmpty, final.last?.isEmpty == true {
                continue
            }
            final.append(line)
        }

        return final.joined(separator: "\n")
    }

    private func organizeGitignore() {
        guard let project = data.project else { return }

        isOrganizing = true
        statusMessage = nil

        Task {
            do {
                let url = URL(fileURLWithPath: project.path).appendingPathComponent(".gitignore")
                let fileManager = FileManager.default
                var existing = ""
                if fileManager.fileExists(atPath: url.path) {
                    existing = try String(contentsOf: url, encoding: .utf8)
                }

                let organized = organizeContent(existing: existing)
                try organized.write(to: url, atomically: true, encoding: .utf8)

                await MainActor.run {
                    self.content = organized
                    self.isOrganizing = false
                    self.isLoading = false
                    self.hasError = false
                    self.statusMessage = "已整理分组"
                }
            } catch {
                await MainActor.run {
                    self.isOrganizing = false
                    self.statusMessage = "整理失败：\(error.localizedDescription)"
                    self.hasError = true
                }
            }
        }
    }

    private func organizeContent(existing: String) -> String {
        func normalizedKey(_ line: String) -> String {
            line.trimmingCharacters(in: .whitespaces)
        }

        let templates: [GitignoreTemplate] = [.xcode, .flutter]

        var templateBuckets: [GitignoreTemplate: [String]] = [:]
        var templateSeen: [GitignoreTemplate: Set<String>] = [:]

        var unknown: [String] = []
        var unknownSeen = Set<String>()

        var templateLookup: [String: GitignoreTemplate] = [:]
        for template in templates {
            templateLookup[normalizedKey(template.header)] = template
            for line in template.lines {
                templateLookup[normalizedKey(line)] = template
            }
        }

        for rawLine in existing.components(separatedBy: .newlines) {
            let key = normalizedKey(rawLine)

            if key.isEmpty {
                unknown.append("")
                continue
            }

            if let template = templateLookup[key] {
                var seen = templateSeen[template] ?? []
                if seen.contains(key) == false {
                    seen.insert(key)
                    templateSeen[template] = seen

                    var lines = templateBuckets[template] ?? []
                    if key != normalizedKey(template.header) {
                        lines.append(rawLine)
                        templateBuckets[template] = lines
                    }
                }
            } else {
                if unknownSeen.contains(key) == false {
                    unknownSeen.insert(key)
                    unknown.append(rawLine)
                }
            }
        }

        func appendSection(_ header: String, lines: [String], to result: inout [String]) {
            guard lines.isEmpty == false else { return }
            if result.last?.isEmpty == false {
                result.append("")
            }
            result.append(header)
            for line in lines {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    continue
                }
                result.append(line)
            }
        }

        var result: [String] = []

        for template in templates {
            if let lines = templateBuckets[template], lines.isEmpty == false {
                appendSection(template.header, lines: lines, to: &result)
            }
        }

        // Clean up unknown: collapse consecutive blanks and dedup
        var cleanedUnknown: [String] = []
        var seenUnknown = Set<String>()
        for line in unknown {
            let key = normalizedKey(line)
            if key.isEmpty {
                if cleanedUnknown.last?.isEmpty == true { continue }
                cleanedUnknown.append("")
                continue
            }
            if seenUnknown.contains(key) { continue }
            seenUnknown.insert(key)
            cleanedUnknown.append(line)
        }

        appendSection("# Other", lines: cleanedUnknown.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }, to: &result)

        // collapse trailing/duplicate blanks
        var final: [String] = []
        for line in result {
            if line.trimmingCharacters(in: .whitespaces).isEmpty, final.last?.isEmpty == true {
                continue
            }
            final.append(line)
        }
        if final.last?.isEmpty == true {
            final.removeLast()
        }

        return final.joined(separator: "\n")
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

