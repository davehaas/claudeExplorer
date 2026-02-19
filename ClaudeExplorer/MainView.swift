import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            DetailPanel()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.changeFolder(); appState.pickAndLoad() }) {
                    Label("Change Folder", systemImage: "folder.badge.gearshape")
                }
                .help("Select a different export folder")
            }
        }
    }
}

struct DetailPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.sidebarSelection {
            case .conversation:
                if let conversation = appState.selectedConversation {
                    ConversationDetailView(conversation: conversation)
                } else {
                    emptyState
                }
            case .project:
                if let project = appState.selectedProject {
                    ProjectDetailView(project: project)
                } else {
                    emptyState
                }
            case .memories:
                MemoriesView()
            case nil:
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("Select a conversation, project, or memories from the sidebar")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
