import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Claude Explorer")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Browse your exported Claude.ai conversations,\nprojects, and memories.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error = appState.loadError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }

            Button(action: { appState.pickAndLoad() }) {
                Label("Open Export Folder…", systemImage: "folder")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Select the folder containing your Claude.ai export files:\nconversations.json, memories.json, projects.json, users.json")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding(40)
    }
}
