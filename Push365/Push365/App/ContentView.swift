//
//  ContentView.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI

struct ContentView: View {
    // Temporary demo values until real snapshot wiring is added
    private let dayNumber: Int? = 24
    private let target: Int = 24
    private let completed: Int = 20

    private var isComplete: Bool {
        completed >= target
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isComplete {
                completeView(dayNumber: dayNumber)
            } else {
                incompleteView(dayNumber: dayNumber, target: target, completed: completed)
            }
        }
    }

    private func header(day: Int?) -> some View {
        HStack {
            if let day {
                Text("Day \(day)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(.top, 6)
    }

    private func incompleteView(dayNumber: Int?, target: Int, completed: Int) -> some View {
        let remaining = max(0, target - completed)

        return GeometryReader { geo in
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
                        .font(.system(size: ringSize * 0.28, weight: .bold, design: .rounded))
                        .foregroundStyle(appGreen)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Styling (watch)

private let appBlue = Color(hex: 0x4DA3FF)
private let appGreen = Color(hex: 0x4CAF50)

private extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let accent: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .drawingGroup()
    }
}

#Preview {
    ContentView()
}
