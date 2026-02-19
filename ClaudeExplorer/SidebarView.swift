import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List(selection: $appState.sidebarSelection) {
            // Memories row
            Section {
                Label("Memories", systemImage: "brain.head.profile")
                    .tag(SidebarItem.memories)
            }

            // Projects section
            if !appState.sortedProjects.isEmpty {
                Section("Projects") {
                    ForEach(appState.sortedProjects) { project in
                        Label(project.name, systemImage: "folder")
                            .tag(SidebarItem.project(project.uuid))
                    }
                }
            }

            // Conversations section
            Section("Conversations (\(appState.filteredConversations.count))") {
                ForEach(appState.filteredConversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .tag(SidebarItem.conversation(conversation.uuid))
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $appState.searchText, placement: .sidebar, prompt: "Search conversations…")
        .onChange(of: appState.sidebarSelection) { _, _ in
            appState.persistSelection()
        }
    }
}

struct ConversationRow: View {
    let conversation: ExportedConversation

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(conversation.name.isEmpty ? "Untitled" : conversation.name)
                .font(.body)
                .lineLimit(2)

            Text(DateUtility.displayString(from: conversation.updatedAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
