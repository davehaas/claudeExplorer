import SwiftUI

struct MemoriesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("Memories")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)

                if let mem = appState.memories.first {
                    // Conversations memory
                    if !mem.conversationsMemory.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("General Memory")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            RichMarkdownText(text: mem.conversationsMemory)
                                .font(.body)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(10)
                    }

                    // Project memories
                    if !mem.projectMemories.isEmpty {
                        ForEach(Array(mem.projectMemories.keys.sorted()), id: \.self) { projectUUID in
                            if let memoryText = mem.projectMemories[projectUUID] {
                                let projectName = appState.projects.first(where: { $0.uuid == projectUUID })?.name ?? projectUUID

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder")
                                            .foregroundStyle(.blue)
                                        Text("Project: \(projectName)")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)
                                    }

                                    RichMarkdownText(text: memoryText)
                                        .font(.body)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(10)
                            }
                        }
                    }
                } else {
                    Text("No memories found.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
