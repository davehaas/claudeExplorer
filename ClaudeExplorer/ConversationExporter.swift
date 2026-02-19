import Foundation
import AppKit

/// Extracts, formats, and exports conversation content as markdown.
enum ConversationExporter {

    // MARK: - Token Estimation

    /// Rough token estimate: ~4 characters per token for English text.
    /// This is a conservative approximation matching Claude's tokenizer behavior.
    static func estimateTokens(_ text: String) -> Int {
        max(1, text.count / 4)
    }

    static func tokenCountLabel(_ count: Int) -> String {
        if count < 1_000 {
            return "\(count) tokens"
        } else if count < 1_000_000 {
            let k = Double(count) / 1_000.0
            return String(format: "%.1fK tokens", k)
        } else {
            let m = Double(count) / 1_000_000.0
            return String(format: "%.1fM tokens", m)
        }
    }

    // MARK: - Full Markdown Export

    /// Generate a full cleaned markdown transcript of the conversation.
    /// Includes all human and assistant text turns, attachments, and code blocks.
    /// Strips thinking, tool_use, tool_result, and token_budget content.
    static func fullMarkdown(from conversation: ExportedConversation) -> String {
        var lines: [String] = []

        lines.append("# \(conversation.name.isEmpty ? "Untitled Conversation" : conversation.name)")
        lines.append("")
        lines.append("**Date:** \(DateUtility.displayString(from: conversation.createdAt))")
        lines.append("**Messages:** \(conversation.chatMessages.count)")
        lines.append("")
        lines.append("---")
        lines.append("")

        for message in conversation.chatMessages {
            let sender = message.isHuman ? "**Human**" : "**Assistant**"
            lines.append("### \(sender)")
            lines.append("")

            // Attachments
            for attachment in message.attachments {
                lines.append("> **Attachment:** \(attachment.fileName)")
                if let content = attachment.extractedContent,
                   !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lines.append(">")
                    // Include attachment content in a code block
                    lines.append("```")
                    lines.append(content)
                    lines.append("```")
                }
                lines.append("")
            }

            // Text content only
            for item in message.content {
                guard item.type == "text",
                      let text = item.text,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continue
                }
                lines.append(text)
                lines.append("")
            }

            lines.append("---")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Context Brief Export

    /// Generate a condensed context brief suitable for pasting into a new Claude session.
    /// Focuses on: what was discussed, key decisions, code snippets, and outcomes.
    /// Much shorter than the full transcript — omits back-and-forth pleasantries and
    /// repetitive iterations, keeping the essential substance.
    static func contextBrief(from conversation: ExportedConversation) -> String {
        var lines: [String] = []

        lines.append("# Context Brief: \(conversation.name.isEmpty ? "Untitled" : conversation.name)")
        lines.append("")
        lines.append("*Exported from Claude conversation on \(DateUtility.displayString(from: conversation.createdAt))*")
        lines.append("*\(conversation.chatMessages.count) messages in original conversation*")
        lines.append("")
        lines.append("---")
        lines.append("")

        // Extract the first human message as the "original request"
        if let firstHuman = conversation.chatMessages.first(where: { $0.isHuman }) {
            lines.append("## Original Request")
            lines.append("")
            let text = extractText(from: firstHuman)
            lines.append(truncate(text, maxLength: 2000))
            lines.append("")
        }

        // Collect all attachment filenames for context
        let attachments = conversation.chatMessages.flatMap { $0.attachments }
        if !attachments.isEmpty {
            lines.append("## Files/Attachments Referenced")
            lines.append("")
            let uniqueNames = Array(Set(attachments.map { $0.fileName })).sorted()
            for name in uniqueNames {
                lines.append("- \(name)")
            }
            lines.append("")
        }

        // Extract key exchanges — first and last human messages, plus all assistant
        // text content, condensed
        lines.append("## Key Discussion Points")
        lines.append("")

        var turnNumber = 0
        for message in conversation.chatMessages {
            let text = extractText(from: message)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            turnNumber += 1

            let sender = message.isHuman ? "Human" : "Claude"
            let preview = truncate(text, maxLength: 800)

            lines.append("**\(sender) (turn \(turnNumber)):**")
            lines.append(preview)
            lines.append("")
        }

        // Extract any code blocks from assistant messages
        let codeBlocks = extractCodeBlocks(from: conversation)
        if !codeBlocks.isEmpty {
            lines.append("## Code Produced")
            lines.append("")
            for (index, block) in codeBlocks.prefix(10).enumerated() {
                lines.append("### Snippet \(index + 1)\(block.language.isEmpty ? "" : " (\(block.language))")")
                lines.append("")
                lines.append("```\(block.language)")
                lines.append(truncate(block.code, maxLength: 3000))
                lines.append("```")
                lines.append("")
            }
            if codeBlocks.count > 10 {
                lines.append("*(\(codeBlocks.count - 10) additional code blocks omitted)*")
                lines.append("")
            }
        }

        // Final assistant message as "outcome"
        if let lastAssistant = conversation.chatMessages.last(where: { $0.isAssistant }) {
            let text = extractText(from: lastAssistant)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("## Final Response / Outcome")
                lines.append("")
                lines.append(truncate(text, maxLength: 2000))
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Clipboard

    static func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Save to File

    static func saveToFile(_ text: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.title = "Save Conversation Export"
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.plainText]
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("ConversationExporter: Failed to save file: \(error)")
        }
    }

    // MARK: - Helpers

    /// Extract all text content from a message, joining multiple text blocks.
    private static func extractText(from message: ChatMessage) -> String {
        message.content
            .filter { $0.type == "text" }
            .compactMap { $0.text }
            .joined(separator: "\n\n")
    }

    /// Truncate text to a max character length, appending ellipsis if truncated.
    private static func truncate(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<endIndex]) + "\n\n*[...truncated]*"
    }

    /// Extract code blocks from all assistant messages.
    private static func extractCodeBlocks(from conversation: ExportedConversation) -> [(language: String, code: String)] {
        var blocks: [(language: String, code: String)] = []

        for message in conversation.chatMessages where message.isAssistant {
            for item in message.content where item.type == "text" {
                guard let text = item.text else { continue }
                let parsed = parseCodeBlocks(text)
                blocks.append(contentsOf: parsed)
            }
        }

        return blocks
    }

    private static func parseCodeBlocks(_ input: String) -> [(language: String, code: String)] {
        var blocks: [(language: String, code: String)] = []
        let lines = input.components(separatedBy: "\n")
        var inCodeBlock = false
        var language = ""
        var code = ""

        for line in lines {
            if !inCodeBlock && line.hasPrefix("```") {
                language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                code = ""
                inCodeBlock = true
            } else if inCodeBlock && line.hasPrefix("```") {
                if !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append((language: language, code: code))
                }
                inCodeBlock = false
            } else if inCodeBlock {
                if !code.isEmpty { code += "\n" }
                code += line
            }
        }

        return blocks
    }

    // MARK: - Sanitized filename

    static func sanitizedFilename(from name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let truncated = String(cleaned.prefix(80))
        return truncated.isEmpty ? "conversation" : truncated
    }
}
