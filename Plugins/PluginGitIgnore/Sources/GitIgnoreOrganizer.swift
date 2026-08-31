import Foundation

enum GitIgnoreOrganizer {
    static func merge(existing: String, template: GitIgnoreTemplate) -> String {
        let templateKeys = Set(template.lines.map(normalizedKey) + [normalizedKey(template.header)])

        var seen = Set<String>()
        var kept: [String] = []

        for line in existing.components(separatedBy: .newlines) {
            let key = normalizedKey(line)

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

        var final = kept
        for line in additions {
            if line.trimmingCharacters(in: .whitespaces).isEmpty, final.last?.isEmpty == true {
                continue
            }
            final.append(line)
        }

        return final.joined(separator: "\n")
    }

    static func organize(existing: String) -> String {
        let templates: [GitIgnoreTemplate] = [.xcode, .flutter]

        var templateBuckets: [GitIgnoreTemplate: [String]] = [:]
        var templateSeen: [GitIgnoreTemplate: Set<String>] = [:]
        var unknown: [String] = []
        var unknownSeen = Set<String>()

        var templateLookup: [String: GitIgnoreTemplate] = [:]
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
            } else if unknownSeen.contains(key) == false {
                unknownSeen.insert(key)
                unknown.append(rawLine)
            }
        }

        var result: [String] = []
        for template in templates {
            if let lines = templateBuckets[template], lines.isEmpty == false {
                appendSection(template.header, lines: lines, to: &result)
            }
        }

        let cleanedUnknown = unknown.filter { normalizedKey($0).isEmpty == false }
        appendSection("# Other", lines: cleanedUnknown, to: &result)

        return collapseBlankLines(result).joined(separator: "\n")
    }

    private static func normalizedKey(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespaces)
    }

    private static func appendSection(_ header: String, lines: [String], to result: inout [String]) {
        guard lines.isEmpty == false else { return }
        if result.last?.isEmpty == false {
            result.append("")
        }
        result.append(header)
        for line in lines where normalizedKey(line).isEmpty == false {
            result.append(line)
        }
    }

    private static func collapseBlankLines(_ lines: [String]) -> [String] {
        var final: [String] = []
        for line in lines {
            if normalizedKey(line).isEmpty, final.last?.isEmpty == true {
                continue
            }
            final.append(line)
        }
        if final.last?.isEmpty == true {
            final.removeLast()
        }
        return final
    }
}
