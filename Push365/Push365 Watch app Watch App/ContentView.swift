//
//  ContentView.swift
//  Push365 Watch app Watch App
//
//  Created by Lee Chandler on 24/01/2026.
//

import SwiftUI
import Foundation
import WatchKit

// App theme colors (match iPhone aesthetic)
private let appBackgroundTop = Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
private let appBackgroundBottom = Color(red: 0x14/255, green: 0x18/255, blue: 0x1E/255)
private let appBlue = Color(red: 127/255, green: 179/255, blue: 255/255)
private let appGreen = Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255)

// MARK: - Minimal snapshot loader (Watch)
final class WatchSnapshotStore {
    static let shared = WatchSnapshotStore()
    private init() {}
    func loadLatest() -> WidgetSnapshot? {
        return WidgetDataStore.load()
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double // 0.0 - 1.0
    var accent: Color = appBlue
    var progressWidth: CGFloat = 9
    var trackWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: trackWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    accent.opacity(0.95),
                    style: StrokeStyle(lineWidth: progressWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.25), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Today View
struct ContentView: View {
    @State private var snapshot: WidgetSnapshot? = nil
    @State private var wasComplete = false
    @State private var hasLoadedSnapshot = false

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let ringSize = max(96, min(132, size * 0.76))

            ZStack {
                LinearGradient(
                    colors: [appBackgroundTop, appBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.4)],
                    center: UnitPoint(x: 0.5, y: 0.45),
                    startRadius: size * 0.28,
                    endRadius: size * 0.68
                )
                .ignoresSafeArea()

                Group {
                    if snapshot == nil {
                        noDataView
                    } else if (snapshot?.isComplete ?? false) {
                        completeView(dayNumber: snapshot?.dayNumber, ringSize: ringSize)
                    } else {
                        incompleteView(
                            dayNumber: snapshot?.dayNumber,
                            target: snapshot?.target ?? 0,
                            completed: snapshot?.completed ?? 0,
                            ringSize: ringSize
                        )
                    }
                }
                .overlay(alignment: .topLeading) {
                    // Keep “Day 25” in the top-left, visually aligned with the system time.
                    header(day: snapshot?.dayNumber)
                        .padding(.leading, 8)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { reloadSnapshot() }
                .onAppear { reloadSnapshot() }
                .onReceive(NotificationCenter.default.publisher(for: .watchSnapshotUpdated)) { _ in
                    reloadSnapshot()
                }
            }
        }
    }

    // MARK: - Subviews
    private var noDataView: some View {
        VStack(spacing: 8) {
            Text("Push365")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text("Open iPhone app to sync")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private func header(day: Int?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("Day")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.42))
            Text("\(day ?? 1)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func incompleteView(dayNumber: Int?, target: Int, completed: Int, ringSize: CGFloat) -> some View {
        let remaining = snapshot?.remaining ?? max(0, target - completed)
        let progress = target == 0 ? 0 : Double(completed) / Double(target)

        return ZStack {
            ProgressRing(
                progress: progress,
                accent: appBlue,
                progressWidth: 9,
                trackWidth: 5
            )
            .frame(width: ringSize, height: ringSize)

            VStack(spacing: 8) {
                Text("\(remaining)")
                    .font(.system(size: ringSize * 0.44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)

                    Text("remaining")
                        .font(.system(size: max(11, ringSize * 0.12), weight: .medium))
                        .foregroundStyle(.white.opacity(0.50))
                        .offset(y: -8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func completeView(dayNumber: Int?, ringSize: CGFloat) -> some View {
        return ZStack {
            ProgressRing(
                progress: 1.0,
                accent: appGreen,
                progressWidth: 9,
                trackWidth: 5
            )
            .frame(width: ringSize, height: ringSize)

            Text("DONE")
                .font(.system(size: ringSize * 0.27, weight: .bold, design: .rounded))
                .foregroundStyle(appGreen)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func reloadSnapshot() {
        let latest = WatchSnapshotStore.shared.loadLatest()
        snapshot = latest
        if let isComplete = latest?.isComplete {
            if hasLoadedSnapshot, isComplete && !wasComplete {
                WKInterfaceDevice.current().play(.success)
            }
            wasComplete = isComplete
            hasLoadedSnapshot = true
        } else {
            wasComplete = false
            hasLoadedSnapshot = true
        }
        
        // Simulator-only fallback (don’t write back to the shared store)
        #if targetEnvironment(simulator)
        if snapshot == nil {
            snapshot = WidgetSnapshot(
                dayNumber: 25,
                target: 25,
                completed: 10,
                remaining: 15,
                isComplete: false,
                timestamp: Date()
            )
        }
        #endif
    }
}

// MARK: - Previews
#Preview("Incomplete") {
    ZStack {
        LinearGradient(colors: [appBackgroundTop, appBackgroundBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        ContentView()
    }
}

#Preview("Complete") {
    ZStack {
        LinearGradient(colors: [appBackgroundTop, appBackgroundBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        VStack {
            TodayCompletePreview()
        }
        .padding()
    }
}

#Preview("No Data") {
    ZStack {
        LinearGradient(colors: [appBackgroundTop, appBackgroundBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        VStack {
            TodayNoDataPreview()
        }
        .padding()
    }
}

// MARK: - Lightweight preview helpers
private struct TodayCompletePreview: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Day 23")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                ProgressRing(progress: 1.0)
                    .frame(width: 84, height: 84)
                Text("DONE")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(appGreen)
            }
        }
    }
}
private struct TodayNoDataPreview: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Push365")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text("Open iPhone app to sync")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
}
