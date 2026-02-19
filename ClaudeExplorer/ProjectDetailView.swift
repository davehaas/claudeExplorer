import SwiftUI

struct ProjectDetailView: View {
    let project: ExportedProject
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text(project.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Text("Created \(DateUtility.displayString(from: project.createdAt))")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.body)
                            .padding(.top, 4)
                    }
                }

                if !project.promptTemplate.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prompt Template")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(project.promptTemplate)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }

                // Documents
                if !project.docs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Documents (\(project.docs.count))")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ForEach(project.docs) { doc in
                            ProjectDocView(doc: doc)
                        }
                    }
                }

                // Project memory (if any)
                if let mem = appState.memories.first,
                   let projectMemory = mem.projectMemories[project.uuid] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Memory")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        RichMarkdownText(text: projectMemory)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}

struct ProjectDocView: View {
    let doc: ProjectDocument
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.blue)
                    Text(doc.filename)
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(doc.content.count) chars")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(12)

            if isExpanded {
                Divider()
                ScrollView {
                    RichMarkdownText(text: doc.content)
                        .font(.callout)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 400)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}
