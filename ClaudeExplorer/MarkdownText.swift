import SwiftUI

/// Renders a string with basic markdown formatting using SwiftUI's native AttributedString markdown support.
struct MarkdownText: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .textSelection(.enabled)
        } else {
            Text(text)
                .textSelection(.enabled)
        }
    }
}

/// Renders markdown text with full block-level support including code blocks.
/// Splits on code fences and renders code blocks with a distinct background.
struct RichMarkdownText: View {
    let text: String

    var body: some View {
        let blocks = parseBlocks(text)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let content):
                    if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        MarkdownText(text: content)
                            .font(.body)
                    }
                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                }
            }
        }
    }

    // MARK: - Parsing

    private enum Block {
        case text(String)
        case codeBlock(language: String, code: String)
    }

    private func parseBlocks(_ input: String) -> [Block] {
        var blocks: [Block] = []
        let lines = input.components(separatedBy: "\n")
        var currentText = ""
        var inCodeBlock = false
        var codeLanguage = ""
        var codeContent = ""

        for line in lines {
            if !inCodeBlock && line.hasPrefix("```") {
                // Start of code block — flush any accumulated text
                if !currentText.isEmpty {
                    blocks.append(.text(currentText))
                    currentText = ""
                }
                codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeContent = ""
                inCodeBlock = true
            } else if inCodeBlock && line.hasPrefix("```") {
                // End of code block
                blocks.append(.codeBlock(language: codeLanguage, code: codeContent))
                inCodeBlock = false
                codeLanguage = ""
                codeContent = ""
            } else if inCodeBlock {
                if !codeContent.isEmpty { codeContent += "\n" }
                codeContent += line
            } else {
                if !currentText.isEmpty { currentText += "\n" }
                currentText += line
            }
        }

        // Flush remaining
        if inCodeBlock && !codeContent.isEmpty {
            // Unclosed code block — treat as code anyway
            blocks.append(.codeBlock(language: codeLanguage, code: codeContent))
        }
        if !currentText.isEmpty {
            blocks.append(.text(currentText))
        }

        return blocks
    }
}

struct CodeBlockView: View {
    let language: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                Text(language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, language.isEmpty ? 10 : 4)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}
