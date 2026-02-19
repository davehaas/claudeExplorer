import SwiftUI

@main
struct ClaudeExplorerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoaded {
                    MainView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(appState)
            .onAppear {
                appState.attemptAutoLoad()
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
    }
}
