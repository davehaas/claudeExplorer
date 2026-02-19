import Foundation
import AppKit

/// Manages security-scoped bookmarks for persistent folder access across launches.
final class BookmarkManager {

    private static let bookmarkKey = "exportFolderBookmark"
    private static let lastConversationKey = "lastSelectedConversationID"
    private static let lastProjectKey = "lastSelectedProjectID"
    private static let sidebarSelectionKey = "lastSidebarSelection"

    // MARK: - Bookmark persistence

    /// Save a security-scoped bookmark for the given folder URL.
    static func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
    }

    /// Resolve a previously saved bookmark, returning the folder URL.
    /// Returns nil if no bookmark is saved or resolution fails.
    static func resolveBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Re-save the bookmark with fresh data
                try? saveBookmark(for: url)
            }
            return url
        } catch {
            print("BookmarkManager: Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    /// Clear the saved bookmark (e.g., when user wants to change folder).
    static func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    // MARK: - Last selection persistence

    static var lastConversationID: String? {
        get { UserDefaults.standard.string(forKey: lastConversationKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastConversationKey) }
    }

    static var lastProjectID: String? {
        get { UserDefaults.standard.string(forKey: lastProjectKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastProjectKey) }
    }

    static var lastSidebarSelection: String? {
        get { UserDefaults.standard.string(forKey: sidebarSelectionKey) }
        set { UserDefaults.standard.set(newValue, forKey: sidebarSelectionKey) }
    }

    // MARK: - Folder picker

    /// Show an NSOpenPanel to let the user pick their export folder.
    /// Returns the selected URL, or nil if cancelled.
    static func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select your Claude export folder"
        panel.message = "Choose the folder containing conversations.json, memories.json, projects.json, and users.json"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return nil
        }
        return url
    }
}
