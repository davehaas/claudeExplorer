import Foundation

// MARK: - Users

struct ExportedUser: Codable, Identifiable {
    let uuid: String
    let fullName: String
    let emailAddress: String
    let verifiedPhoneNumber: String?

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid
        case fullName = "full_name"
        case emailAddress = "email_address"
        case verifiedPhoneNumber = "verified_phone_number"
    }
}

// MARK: - Memories

struct ExportedMemories: Codable {
    let conversationsMemory: String
    let projectMemories: [String: String]
    let accountUuid: String

    enum CodingKeys: String, CodingKey {
        case conversationsMemory = "conversations_memory"
        case projectMemories = "project_memories"
        case accountUuid = "account_uuid"
    }
}

// MARK: - Projects

struct ExportedProject: Codable, Identifiable {
    let uuid: String
    let name: String
    let description: String
    let isPrivate: Bool
    let isStarterProject: Bool
    let promptTemplate: String
    let createdAt: String
    let updatedAt: String
    let creator: ProjectCreator
    let docs: [ProjectDocument]

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid, name, description
        case isPrivate = "is_private"
        case isStarterProject = "is_starter_project"
        case promptTemplate = "prompt_template"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creator, docs
    }
}

struct ProjectCreator: Codable {
    let uuid: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case fullName = "full_name"
    }
}

struct ProjectDocument: Codable, Identifiable {
    let uuid: String
    let filename: String
    let content: String
    let createdAt: String

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid, filename, content
        case createdAt = "created_at"
    }
}

// MARK: - Conversations

struct ExportedConversation: Codable, Identifiable {
    let uuid: String
    let name: String
    let summary: String
    let createdAt: String
    let updatedAt: String
    let account: ConversationAccount
    let chatMessages: [ChatMessage]

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid, name, summary, account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case chatMessages = "chat_messages"
    }

    var createdDate: Date? {
        DateUtility.parseISO8601(createdAt)
    }

    var updatedDate: Date? {
        DateUtility.parseISO8601(updatedAt)
    }
}

struct ConversationAccount: Codable {
    let uuid: String
}

struct ChatMessage: Codable, Identifiable {
    let uuid: String
    let text: String
    let content: [ContentItem]
    let sender: String
    let createdAt: String
    let updatedAt: String
    let attachments: [Attachment]
    let files: [MessageFile]

    var id: String { uuid }

    var isHuman: Bool { sender == "human" }
    var isAssistant: Bool { sender == "assistant" }

    enum CodingKeys: String, CodingKey {
        case uuid, text, content, sender, attachments, files
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Content Items (discriminated union on "type")

struct ContentItem: Codable, Identifiable {
    let startTimestamp: String?
    let stopTimestamp: String?
    let flags: AnyCodableValue?
    let type: String

    // text fields
    let text: String?
    let citations: [Citation]?

    // thinking fields
    let thinking: String?
    let summaries: [ThinkingSummary]?
    let cutOff: Bool?
    let alternativeDisplayType: String?

    // tool_use fields
    let toolUseId: String?
    let name: String?
    let input: AnyCodableValue?
    let message: String?
    let integrationName: String?

    // tool_result fields
    let toolResultContent: AnyCodableValue?
    let isError: Bool?

    var id: String { "\(type)-\(startTimestamp ?? UUID().uuidString)" }

    enum CodingKeys: String, CodingKey {
        case startTimestamp = "start_timestamp"
        case stopTimestamp = "stop_timestamp"
        case flags, type, text, citations
        case thinking, summaries
        case cutOff = "cut_off"
        case alternativeDisplayType = "alternative_display_type"
        case toolUseId = "id"
        case name, input, message
        case integrationName = "integration_name"
        case toolResultContent = "content"
        case isError = "is_error"
    }
}

struct Citation: Codable {
    let uuid: String?
    let startIndex: Int?
    let endIndex: Int?
    let details: CitationDetails?

    enum CodingKeys: String, CodingKey {
        case uuid
        case startIndex = "start_index"
        case endIndex = "end_index"
        case details
    }
}

struct CitationDetails: Codable {
    let type: String?
    let url: String?
}

struct ThinkingSummary: Codable {
    let summary: String?
}

struct Attachment: Codable, Identifiable {
    let fileName: String
    let fileSize: Int?
    let fileType: String?
    let extractedContent: String?

    var id: String { fileName + (fileType ?? "") }

    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case fileSize = "file_size"
        case fileType = "file_type"
        case extractedContent = "extracted_content"
    }
}

struct MessageFile: Codable {
    let fileName: String

    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
    }
}

// MARK: - Flexible JSON value wrapper

enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case dictionary([String: AnyCodableValue])
    case array([AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
            return
        }
        if let i = try? container.decode(Int.self) {
            self = .int(i)
            return
        }
        if let d = try? container.decode(Double.self) {
            self = .double(d)
            return
        }
        if let s = try? container.decode(String.self) {
            self = .string(s)
            return
        }
        if let arr = try? container.decode([AnyCodableValue].self) {
            self = .array(arr)
            return
        }
        if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
            return
        }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .dictionary(let dict): try container.encode(dict)
        case .array(let arr): try container.encode(arr)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Date Utility

enum DateUtility {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parseISO8601(_ string: String) -> Date? {
        iso8601Formatter.date(from: string)
            ?? iso8601FormatterNoFraction.date(from: string)
    }

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func displayString(from isoString: String) -> String {
        guard let date = parseISO8601(isoString) else { return isoString }
        return displayFormatter.string(from: date)
    }
}
