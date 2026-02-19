import SwiftUI

struct ConversationDetailView: View {
    let conversation: ExportedConversation
    @State private var showCopiedFeedback = false
    @State private var copiedLabel = ""

    private var fullMarkdown: String {
        ConversationExporter.fullMarkdown(from: conversation)
    }

    private var contextBrief: String {
        ConversationExporter.contextBrief(from: conversation)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.name.isEmpty ? "Untitled" : conversation.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(DateUtility.displayString(from: conversation.createdAt))
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        if conversation.chatMessages.count > 0 {
                            Text("\(conversation.chatMessages.count) messages")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        let fullTokens = ConversationExporter.estimateTokens(fullMarkdown)
                        Text("~\(ConversationExporter.tokenCountLabel(fullTokens)) full")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 24)

                // Messages
                ForEach(conversation.chatMessages) { message in
                    MessageBubble(message: message)
                }
            }
            .padding(.bottom, 40)
        }
        .overlay(alignment: .top) {
            if showCopiedFeedback {
                Text(copiedLabel)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCopiedFeedback)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ExportMenu(conversation: conversation,
                           fullMarkdown: fullMarkdown,
                           contextBrief: contextBrief) { label in
                    showCopied(label)
                }
            }
        }
    }

    private func showCopied(_ label: String) {
        copiedLabel = label
        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedFeedback = false
        }
    }
}

struct ExportMenu: View {
    let conversation: ExportedConversation
    let fullMarkdown: String
    let contextBrief: String
    var onCopied: (String) -> Void

    private var fullTokens: Int { ConversationExporter.estimateTokens(fullMarkdown) }
    private var briefTokens: Int { ConversationExporter.estimateTokens(contextBrief) }
    private var filename: String { ConversationExporter.sanitizedFilename(from: conversation.name) }

    var body: some View {
        Menu {
            Section("Copy to Clipboard") {
                Button(action: {
                    ConversationExporter.copyToClipboard(fullMarkdown)
                    onCopied("Copied full markdown (~\(ConversationExporter.tokenCountLabel(fullTokens)))")
                }) {
                    Label("Copy as Markdown (~\(ConversationExporter.tokenCountLabel(fullTokens)))",
                          systemImage: "doc.on.doc")
                }

                Button(action: {
                    ConversationExporter.copyToClipboard(contextBrief)
                    onCopied("Copied context brief (~\(ConversationExporter.tokenCountLabel(briefTokens)))")
                }) {
                    Label("Copy as Context Brief (~\(ConversationExporter.tokenCountLabel(briefTokens)))",
                          systemImage: "text.badge.star")
                }
            }

            Divider()

            Section("Save to File") {
                Button(action: {
                    ConversationExporter.saveToFile(fullMarkdown, suggestedName: "\(filename).md")
                }) {
                    Label("Save Full Markdown…", systemImage: "square.and.arrow.down")
                }

                Button(action: {
                    ConversationExporter.saveToFile(contextBrief, suggestedName: "\(filename)-brief.md")
                }) {
                    Label("Save Context Brief…", systemImage: "square.and.arrow.down")
                }
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .help("Export conversation as markdown or context brief")
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sender label
            HStack(spacing: 6) {
                Image(systemName: message.isHuman ? "person.circle.fill" : "sparkle")
                    .foregroundStyle(message.isHuman ? .blue : .purple)
                    .font(.callout)

                Text(message.isHuman ? "You" : "Claude")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(message.isHuman ? .blue : .purple)

                Spacer()

                Text(DateUtility.displayString(from: message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 6)

            // Attachments
            if !message.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(message.attachments) { attachment in
                        AttachmentChip(attachment: attachment)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(message.content) { item in
                    ContentItemView(item: item, isHuman: message.isHuman)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .background(message.isHuman ? Color.clear : Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

struct ContentItemView: View {
    let item: ContentItem
    let isHuman: Bool

    var body: some View {
        switch item.type {
        case "text":
            if let text = item.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                RichMarkdownText(text: text)
            }

        case "thinking":
            if let thinking = item.thinking, !thinking.isEmpty {
                DisclosureGroup {
                    Text(thinking)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(8)
                } label: {
                    Label("Thinking", systemImage: "brain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

        case "tool_use":
            if let name = item.name {
                HStack(spacing: 4) {
                    Image(systemName: "hammer")
                        .font(.caption)
                    Text("Used tool: \(name)")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .padding(.vertical, 2)
            }

        case "tool_result":
            // Show tool results minimally
            if let name = item.name {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption)
                    Text("Result from: \(name)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
            }

        default:
            // token_budget and others — skip
            EmptyView()
        }
    }
}

struct AttachmentChip: View {
    let attachment: Attachment
    @State private var isExpanded = false

    private var hasContent: Bool {
        guard let content = attachment.extractedContent else { return false }
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isCodeFile: Bool {
        let ft = attachment.fileType ?? ""
        let fn = attachment.fileName.lowercased()
        return ft.contains("python") || ft.contains("c++") || ft.contains("sh")
            || fn.hasSuffix(".py") || fn.hasSuffix(".c") || fn.hasSuffix(".h")
            || fn.hasSuffix(".cpp") || fn.hasSuffix(".swift") || fn.hasSuffix(".js")
            || fn.hasSuffix(".ts") || fn.hasSuffix(".rs") || fn.hasSuffix(".go")
            || fn.hasSuffix(".java") || fn.hasSuffix(".sh") || fn.hasSuffix(".rb")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clickable chip header
            Button(action: {
                if hasContent {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: iconForType(attachment.fileType ?? ""))
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(attachment.fileName)
                        .font(.caption)
                        .fontWeight(.medium)
                    if let size = attachment.fileSize {
                        Text("(\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if hasContent {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content viewer
            if isExpanded, let content = attachment.extractedContent {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    // Toolbar row
                    HStack {
                        Text("\(content.count) characters")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(content, forType: .string)
                        }) {
                            Label("Copy Content", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 6)

                    // Content area
                    ScrollView {
                        if isCodeFile {
                            Text(content)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        } else {
                            RichMarkdownText(text: content)
                                .font(.callout)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding(.bottom, 6)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "pdf": return "doc.richtext"
        case "txt", "text/plain": return "doc.text"
        default:
            if type.contains("python") { return "chevron.left.forwardslash.chevron.right" }
            if type.contains("c++") || type.contains("html") || type.contains("sh") { return "chevron.left.forwardslash.chevron.right" }
            return "paperclip"
        }
    }
}
