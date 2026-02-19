# Claude Explorer

A native macOS app for browsing, searching, and exporting your Claude.ai conversation history.

Claude.ai lets you export your account data as a set of JSON files. Claude Explorer turns that raw export into a readable, searchable archive — so you can revisit past conversations, view project knowledge, review memories, and extract useful context for new sessions.

## Features

### Conversation Browser
- Full scrollable chat transcripts with clear visual distinction between Human and Assistant turns
- Markdown rendering: bold, italics, inline code, and fenced code blocks with syntax-appropriate styling
- Thinking blocks shown as collapsible sections
- Tool use and tool results displayed as compact indicators
- Conversations sorted newest-first with message counts and token estimates

### Inline Attachment Viewer
- Click any attachment chip to expand its extracted content inline
- Code files rendered in monospaced font; text/markdown files rendered with full formatting
- Copy attachment content to clipboard with one click
- Supports all exported file types: source code, plain text, HTML, PDFs (extracted text), and more

### Search
- Filter conversations by title or message content from the sidebar search field
- Instant filtering across all 200+ conversations

### Projects & Memories
- Browse Claude.ai projects with their knowledge documents and prompt templates
- View project documents with expandable content viewers
- Access general conversation memory and per-project memories
- Project memory cross-referenced with project names

### Export & Context Transfer
- **Copy as Markdown** — full cleaned transcript to clipboard, ready to paste into a new session or save as documentation
- **Copy as Context Brief** — condensed version with: original request, files referenced, key discussion points, code produced, and final outcome
- **Save as .md file** — write either format to disk via save dialog
- Token count estimates shown for each export format so you know what fits in a context window
- Designed to bridge context between Claude sessions — export learnings from an old chat, then seed a new Claude chat, Code session, or Cowork with that context

### Persistent Folder Access
- On first launch, a welcome screen prompts you to select your Claude export folder
- Uses macOS Security-Scoped Bookmarks to remember folder access across app launches (required for sandboxed apps)
- On subsequent launches, data loads automatically and restores your last-viewed conversation
- Change Folder button in the toolbar to reselect if you move your export

## Getting Started

### 1. Export your Claude.ai data

Go to [claude.ai](https://claude.ai) > Settings > Account > Export Data. Claude will email you a download link. The export contains four JSON files in a folder named with your account:

```
your.email/
  conversations.json    # All conversations with full message history
  memories.json         # General and per-project memories
  projects.json         # Projects with knowledge documents
  users.json            # Account info
```

### 2. Build the app

Open `ClaudeExplorer.xcodeproj` in Xcode (requires Xcode 15+ and macOS 14+):

1. Select your development team in Signing & Capabilities
2. Build and run (Cmd+R)

No third-party dependencies — the app uses only SwiftUI, Foundation, and AppKit.

### 3. Point it at your export

On first launch, click **Open Export Folder** and select the folder containing your four JSON files. The app will load everything and remember the location for next time.

## Architecture

```
ClaudeExplorer/
  ClaudeExplorerApp.swift        App entry point, window configuration
  Models.swift                   Codable data models matching the JSON export schema
  DataLoader.swift               JSON file loading and decoding
  BookmarkManager.swift          Security-scoped bookmarks, NSOpenPanel, UserDefaults persistence
  AppState.swift                 Central ObservableObject: data, selection state, folder access
  WelcomeView.swift              First-launch onboarding screen
  MainView.swift                 NavigationSplitView with sidebar/detail routing
  SidebarView.swift              Projects section, conversations list, search
  ConversationDetailView.swift   Chat transcript, message bubbles, attachment viewer, export menu
  ConversationExporter.swift     Markdown/context brief generation, token estimation, clipboard/file export
  MarkdownText.swift             Markdown rendering with code block support
  MemoriesView.swift             General and project memory display
  ProjectDetailView.swift        Project info, documents, prompt templates
  ClaudeExplorer.entitlements    Sandbox permissions (file read-write, bookmarks)
```

### JSON Schema Summary

The app parses four files from the Claude.ai export:

- **conversations.json** — Array of conversations, each with `uuid`, `name`, `created_at`, `updated_at`, and `chat_messages`. Each message has `sender` (human/assistant), `text`, `content` (typed blocks: text, thinking, tool_use, tool_result, token_budget), `attachments` (with full `extracted_content`), and `files`.

- **projects.json** — Array of projects with `name`, `description`, `prompt_template`, `creator`, and `docs` (knowledge documents with full content).

- **memories.json** — Array with a single object containing `conversations_memory` (general memory text) and `project_memories` (keyed by project UUID).

- **users.json** — Array of user account records with `full_name` and `email_address`.

Note: The export does not include a conversation-to-project mapping. Conversations and projects are displayed as separate sections in the sidebar.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (to build)
- A Claude.ai data export (the four JSON files)

## Privacy

All data stays local. The app reads your export files from disk and never makes any network requests. No telemetry, no analytics, no API calls. The sandbox entitlements are limited to reading/writing user-selected files and persisting folder bookmarks.

## License

MIT
