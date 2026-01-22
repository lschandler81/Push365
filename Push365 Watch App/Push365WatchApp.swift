//
//  Push365WatchApp.swift
//  Push365 Watch App
//
//  Created by Lee Chandler on 22/01/2026.
//

import SwiftUI

@main
struct Push365WatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchTodayView()
                .environmentObject(connectivity)
        }
    }
}
