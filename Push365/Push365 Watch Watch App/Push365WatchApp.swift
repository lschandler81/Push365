import SwiftUI
import WatchConnectivity

@main
struct Push365WatchApp: App {
    private let sync = WatchSyncManager.shared

    var body: some Scene {
        WindowGroup {
            WatchLoggingView()
                .environmentObject(sync)
                .onAppear {
                    sync.activate()
                    sync.requestSnapshot()
                }
        }
    }
}

