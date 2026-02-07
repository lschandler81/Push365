//
//  CircularProgressRing.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI

struct CircularProgressRing: View {
    /// Progress 0.0...1.0
    let progress: Double
    let completed: Int
    let target: Int
    let remaining: Int
    let isComplete: Bool
    let firstName: String?

    @State private var animatedProgress: Double = 0

    private let ringWidth: CGFloat = 20
    private let ringSize: CGFloat = 220

    // Specular highlight color (near-white blue)
    private let specularColor = Color(red: 0xEA/255, green: 0xF2/255, blue: 0xFF/255) // #EAF2FF

    // Electric blue palette
    private let electricBlue = Color(red: 0x4D/255, green: 0xA3/255, blue: 0xFF/255)       // #4DA3FF
    private let electricBlueBright = Color(red: 0xA6/255, green: 0xD6/255, blue: 0xFF/255) // lighter blue
    
    // Success green palette
    private let successGreen = Color(red: 0x4F/255, green: 0xAE/255, blue: 0x8A/255)       // #4FAE8A
    private let successGreenBright = Color(red: 0xA8/255, green: 0xE6/255, blue: 0xCF/255) // #A8E6CF
    
    // Computed colors based on completion state
    private var baseColor: Color {
        isComplete ? successGreen : electricBlue
    }
    
    private var brightColor: Color {
        isComplete ? successGreenBright : electricBlueBright
    }

    var body: some View {
        let p = min(max(animatedProgress, 0), 1)
        let isFull = p >= 0.999
        let trimStart = 0.002

        ZStack {
            // Layer 1: Outer glow (behind the progress stroke)
            Group {
                if isFull {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    brightColor.opacity(0.30),
                                    baseColor.opacity(0.18)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringWidth + 10, lineCap: .butt)
                        )
                } else {
                    Circle()
                        .trim(from: trimStart, to: p)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    brightColor.opacity(p > 0 ? 0.30 : 0),
                                    baseColor.opacity(p > 0 ? 0.18 : 0)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringWidth + 10, lineCap: .butt)
                        )
                }
            }
            .frame(width: ringSize, height: ringSize)
            .rotationEffect(.degrees(-90))
            .blur(radius: 10)

            // Ambient full-ring glow (very subtle, always on)
            Circle()
                .stroke(brightColor.opacity(0.10), lineWidth: ringWidth + 12)
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .blur(radius: 18)

            // Layer 2: Base track (deeper)
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: ringWidth * 0.75)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .stroke(baseColor.opacity(0.14), lineWidth: ringWidth * 0.75)
                .frame(width: ringSize, height: ringSize)

            // Layer 2b: Full-ring sheen (subtle transparent gradient around whole ring)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: brightColor.opacity(0.22), location: 0.00),
                            .init(color: baseColor.opacity(0.08), location: 0.22),
                            .init(color: brightColor.opacity(0.18), location: 0.48),
                            .init(color: baseColor.opacity(0.06), location: 0.78),
                            .init(color: brightColor.opacity(0.22), location: 1.00)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: ringWidth * 0.75, lineCap: .butt)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .blur(radius: 1.2)
                .opacity(0.85)

            // Layer 3: Primary progress ring (crisp)
            Group {
                if isFull {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: baseColor, location: 0.00),
                                    .init(color: brightColor, location: 0.30),
                                    .init(color: baseColor, location: 1.00)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                } else {
                    Circle()
                        .trim(from: trimStart, to: p)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: baseColor, location: 0.00),
                                    .init(color: brightColor, location: 0.30),
                                    .init(color: baseColor, location: 1.00)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                }
            }
            .frame(width: ringSize, height: ringSize)
            .rotationEffect(.degrees(-90))
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: p)

            // Center content
            VStack(spacing: 6) {
                if isComplete {
                    VStack(spacing: 2) {
                        Text("Target")
                        Text("complete")
                    }
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                } else {
                    let displayRemaining = max(remaining, 0)
                    Text("\(displayRemaining)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white.opacity(0.92))

                    Text("remaining")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }
        }
        // Prevent glow clipping
        .padding(24)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255).ignoresSafeArea()
        VStack(spacing: 40) {
            CircularProgressRing(progress: 0.3, completed: 6, target: 21, remaining: 15, isComplete: false, firstName: nil)
            CircularProgressRing(progress: 0.75, completed: 16, target: 21, remaining: 5, isComplete: false, firstName: nil)
            CircularProgressRing(progress: 1.0, completed: 21, target: 21, remaining: 0, isComplete: true, firstName: "Alex")
        }
    }
}
