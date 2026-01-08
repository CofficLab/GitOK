
import SwiftUI

struct GitignoreOrganizerView: View {
    @EnvironmentObject var data: DataProvider

    @Binding var content: String
    @Binding var isLoading: Bool
    @Binding var isApplyingTemplate: Bool
    @Binding var isOrganizing: Bool
    @Binding var statusMessage: String?

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Xcode") {
                    applyTemplate(.xcode)
                }
                Button("Flutter") {
                    applyTemplate(.flutter)
                }
            } label: {
                Label("添加忽略", systemImage: "plus.circle")
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderedButton)
            .controlSize(.small)
            .fixedSize()
            .disabled(isApplyingTemplate || isOrganizing || isLoading)

            Button("整理分组") {
                organizeGitignore()
            }
            .controlSize(.small)
            .disabled(isApplyingTemplate || isOrganizing || isLoading)
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
                    self.isApplyingTemplate = false
                    self.statusMessage = "\(template.header) 已添加"
                }
            } catch {
                await MainActor.run {
                    self.isApplyingTemplate = false
                    self.statusMessage = "写入 .gitignore 失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
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
                    self.statusMessage = "已整理分组"
                }
            } catch {
                await MainActor.run {
                    self.isOrganizing = false
                    self.statusMessage = "整理失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Helpers

extension GitignoreOrganizerView {
    private func normalizedKey(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespaces)
    }

    private func mergeGitignore(existing: String, template: GitignoreTemplate) -> String {
        let templateKeys = Set(template.lines.map(normalizedKey) + [normalizedKey(template.header)])

        var seen = Set<String>()
        var kept: [String] = []

        for line in existing.components(separatedBy: .newlines) {
            let key = normalizedKey(line)

            // 跳过模板中已有的行，稍后统一追加
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

        let headerKey = normalizedKey(template.header)
        if kept.last?.isEmpty == false {
            additions.append("")
        }
        if seen.contains(headerKey) == false {
            additions.append(template.header)
            seen.insert(headerKey)
        }
        additions.append(contentsOf: newEntries)

        // 折叠空行
        var final = kept
        for line in additions {
            if line.trimmingCharacters(in: .whitespaces).isEmpty, final.last?.isEmpty == true {
                continue
            }
            final.append(line)
        }

        return final.joined(separator: "\n")
    }

    private func organizeContent(existing: String) -> String {
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

                    if key != normalizedKey(template.header) {
                        var lines = templateBuckets[template] ?? []
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

        // 清理未知项：折叠空行并去重
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

        // 折叠尾部空行
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

