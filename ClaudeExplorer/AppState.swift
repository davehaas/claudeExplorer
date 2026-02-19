import SwiftUI
import Combine

/// Represents what's selected in the sidebar.
enum SidebarItem: Hashable {
    case conversation(String)  // conversation UUID
    case project(String)       // project UUID
    case memories
}

/// Central app state that owns the loaded data and selection state.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Data
    @Published var users: [ExportedUser] = []
    @Published var memories: [ExportedMemories] = []
    @Published var projects: [ExportedProject] = []
    @Published var conversations: [ExportedConversation] = []

    // MARK: - UI State
    @Published var isLoaded = false
    @Published var loadError: String?
    @Published var searchText = ""
    @Published var sidebarSelection: SidebarItem?

    // MARK: - Folder access
    @Published var folderURL: URL?
    // nonisolated(unsafe) so deinit can clean up the security-scoped resource
    nonisolated(unsafe) private var _securityScopedURL: URL?
    private var securityScopedAccess = false

    // MARK: - Computed

    /// Conversations sorted newest-first, filtered by search text.
    var filteredConversations: [ExportedConversation] {
        let sorted = conversations.sorted { a, b in
            let dateA = a.updatedDate ?? a.createdDate ?? .distantPast
            let dateB = b.updatedDate ?? b.createdDate ?? .distantPast
            return dateA > dateB
        }
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter { conv in
            conv.name.lowercased().contains(query)
            || conv.chatMessages.contains { msg in
                msg.text.lowercased().contains(query)
            }
        }
    }

    var sortedProjects: [ExportedProject] {
        projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var selectedConversation: ExportedConversation? {
        guard case .conversation(let id) = sidebarSelection else { return nil }
        return conversations.first { $0.uuid == id }
    }

    var selectedProject: ExportedProject? {
        guard case .project(let id) = sidebarSelection else { return nil }
        return projects.first { $0.uuid == id }
    }

    // MARK: - Lifecycle

    func attemptAutoLoad() {
        guard let url = BookmarkManager.resolveBookmark() else { return }
        loadData(from: url)
    }

    func pickAndLoad() {
        guard let url = BookmarkManager.pickFolder() else { return }
        do {
            try BookmarkManager.saveBookmark(for: url)
        } catch {
            loadError = "Failed to save folder bookmark: \(error.localizedDescription)"
            return
        }
        loadData(from: url)
    }

    func changeFolder() {
        stopAccess()
        BookmarkManager.clearBookmark()
        isLoaded = false
        loadError = nil
        users = []
        memories = []
        projects = []
        conversations = []
        sidebarSelection = nil
    }

    func loadData(from url: URL) {
        stopAccess()

        // Start security-scoped access
        securityScopedAccess = url.startAccessingSecurityScopedResource()
        folderURL = url
        _securityScopedURL = securityScopedAccess ? url : nil

        do {
            let data = try DataLoader.loadAll(from: url)
            self.users = data.users
            self.memories = data.memories
            self.projects = data.projects
            self.conversations = data.conversations
            self.isLoaded = true
            self.loadError = nil

            // Restore last selection
            restoreSelection()
        } catch {
            self.loadError = error.localizedDescription
            self.isLoaded = false
        }
    }

    private func stopAccess() {
        if securityScopedAccess, let url = folderURL {
            url.stopAccessingSecurityScopedResource()
            securityScopedAccess = false
            _securityScopedURL = nil
        }
    }

    // MARK: - Selection persistence

    func persistSelection() {
        switch sidebarSelection {
        case .conversation(let id):
            BookmarkManager.lastConversationID = id
            BookmarkManager.lastSidebarSelection = "conversation"
        case .project(let id):
            BookmarkManager.lastProjectID = id
            BookmarkManager.lastSidebarSelection = "project"
        case .memories:
            BookmarkManager.lastSidebarSelection = "memories"
        case nil:
            BookmarkManager.lastSidebarSelection = nil
        }
    }

    private func restoreSelection() {
        switch BookmarkManager.lastSidebarSelection {
        case "conversation":
            if let id = BookmarkManager.lastConversationID,
               conversations.contains(where: { $0.uuid == id }) {
                sidebarSelection = .conversation(id)
            }
        case "project":
            if let id = BookmarkManager.lastProjectID,
               projects.contains(where: { $0.uuid == id }) {
                sidebarSelection = .project(id)
            }
        case "memories":
            sidebarSelection = .memories
        default:
            break
        }
    }

    deinit {
        _securityScopedURL?.stopAccessingSecurityScopedResource()
    }
}
