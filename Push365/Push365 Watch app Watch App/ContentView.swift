//
//  ContentView.swift
//  Push365 Watch app Watch App
//
//  Created by Lee Chandler on 24/01/2026.
//

import SwiftUI
import Foundation

// App theme colors (match iPhone aesthetic)
private let appBackgroundTop = Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255) // subtle near-black
private let appBackgroundBottom = Color(red: 0x12/255, green: 0x16/255, blue: 0x1C/255)
private let appBlue = Color(red: 127/255, green: 179/255, blue: 255/255) // softer, calmer ring blue (#7FB3FF)

private let appGreen = Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255) // widget green

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
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Today View
struct ContentView: View {
    @State private var snapshot: WidgetSnapshot? = nil

    var body: some View {
        ZStack {
            LinearGradient(colors: [appBackgroundTop, appBackgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            Group {
                if snapshot == nil {
                    noDataView
                } else if (snapshot?.isComplete ?? false) {
                    completeView(dayNumber: snapshot?.dayNumber)
                } else {
                    incompleteView(dayNumber: snapshot?.dayNumber, target: snapshot?.target ?? 0, completed: snapshot?.completed ?? 0)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .onTapGesture { reloadSnapshot() }
            .onAppear { reloadSnapshot() }
        }
    }

    // MARK: - Subviews
    private var noDataView: some View {
        VStack(spacing: 6) {
            Text("Push365")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text("Open iPhone app to sync")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func header(day: Int?) -> some View {
        Text("Day \(day ?? 1)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private func incompleteView(dayNumber: Int?, target: Int, completed: Int) -> some View {
        return GeometryReader { geo in
            let remaining = snapshot?.remaining ?? max(0, target - completed)
            let size = min(geo.size.width, geo.size.height)
            let ringSize = max(76, min(92, size * 0.72))

            VStack(spacing: 10) {
                header(day: dayNumber)

                ZStack {
                    ProgressRing(
                        progress: target == 0 ? 0 : Double(completed) / Double(target),
                        accent: appBlue,
                        lineWidth: 6
                    )
                    .frame(width: ringSize, height: ringSize)

                    VStack(spacing: 2) {
                        Text("\(remaining)")
                            .font(.system(size: ringSize * 0.38, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.95))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("remaining")
                            .font(.system(size: max(11, ringSize * 0.16), weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func completeView(dayNumber: Int?) -> some View {
        return GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let ringSize = max(76, min(92, size * 0.72))

            VStack(spacing: 10) {
                header(day: dayNumber)

                ZStack {
                    ProgressRing(
                        progress: 1.0,
                        accent: appGreen,
                        lineWidth: 6
                    )
                    .frame(width: ringSize, height: ringSize)

                    Text("DONE")
                        .font(.system(size: ringSize * 0.24, weight: .bold, design: .rounded))
                        .foregroundStyle(appGreen)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func reloadSnapshot() {
        snapshot = WatchSnapshotStore.shared.loadLatest()
        
        // Simulator workaround: if no data found, write sample data for testing
        #if targetEnvironment(simulator)
        if snapshot == nil {
            let sampleSnapshot = WidgetSnapshot(
                dayNumber: 25,
                target: 25,
                completed: 10,
                remaining: 15,
                isComplete: false,
                timestamp: Date()
            )
            WidgetDataStore.save(sampleSnapshot)
            snapshot = sampleSnapshot
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
                    .foregroundStyle(Color.green)
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
