import Foundation

/// Loads and decodes the four JSON export files from a folder URL.
final class DataLoader {

    enum LoadError: LocalizedError {
        case fileNotFound(String)
        case decodingFailed(String, Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "Could not find \(name) in the selected folder."
            case .decodingFailed(let name, let error):
                return "Failed to decode \(name): \(error.localizedDescription)"
            }
        }
    }

    struct ExportData {
        var users: [ExportedUser]
        var memories: [ExportedMemories]
        var projects: [ExportedProject]
        var conversations: [ExportedConversation]
    }

    /// Load all four JSON files from the given folder URL.
    /// The caller is responsible for starting/stopping security-scoped access if needed.
    static func loadAll(from folderURL: URL) throws -> ExportData {
        let users: [ExportedUser] = try loadFile(named: "users.json", from: folderURL)
        let memories: [ExportedMemories] = try loadFile(named: "memories.json", from: folderURL)
        let projects: [ExportedProject] = try loadFile(named: "projects.json", from: folderURL)
        let conversations: [ExportedConversation] = try loadFile(named: "conversations.json", from: folderURL)
        return ExportData(users: users, memories: memories, projects: projects, conversations: conversations)
    }

    private static func loadFile<T: Decodable>(named filename: String, from folder: URL) throws -> T {
        let fileURL = folder.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw LoadError.fileNotFound(filename)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw LoadError.decodingFailed(filename, error)
        }
    }
}
