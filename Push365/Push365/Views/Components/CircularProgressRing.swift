//
//  CircularProgressRing.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI

struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let completed: Int
    let target: Int
    let isComplete: Bool
    
    @State private var animatedProgress: Double = 0
    
    private let ringWidth: CGFloat = 20
    private let ringSize: CGFloat = 220
    
    // Specular highlight color (near-white blue for metallic glint)
    private let specularColor = Color(red: 0xEA/255, green: 0xF2/255, blue: 0xFF/255)
    
    // Electric blue base + a brighter variant for gradients
    private let electricBlue = Color(red: 0x4D/255, green: 0xA3/255, blue: 0xFF/255)
    private let electricBlueBright = Color(red: 0xA6/255, green: 0xD6/255, blue: 0xFF/255)
    
    var body: some View {
        ZStack {
            // Layer 1: Outer glow (subtle, blurred, sits outside main ring)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    DSColor.accent.opacity(animatedProgress > 0 ? 0.18 : 0),
                    style: StrokeStyle(
                        lineWidth: ringWidth + 10,
                        lineCap: .round
                    )
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .blur(radius: 14)
            
            // Layer 2: Base track (subtle electric-blue prefill highlight)
            Circle()
                .stroke(electricBlue.opacity(0.16), lineWidth: ringWidth * 0.75)
                .frame(width: ringSize, height: ringSize)
            
            // Layer 2b: Full-ring sheen (transparent gradient over the whole ring)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: electricBlueBright.opacity(0.22), location: 0.00),
                            .init(color: electricBlue.opacity(0.10), location: 0.30),
                            .init(color: electricBlueBright.opacity(0.18), location: 0.55),
                            .init(color: electricBlue.opacity(0.08), location: 0.80),
                            .init(color: electricBlueBright.opacity(0.22), location: 1.00)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth * 0.75, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
            
            // Layer 3: Primary progress ring (crisp electric blue, NO blur)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [electricBlueBright, electricBlue]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatedProgress)
            
            // Layer 4: Specular highlight (sharp metallic glint on bottom-left quadrant)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    specularColor.opacity(animatedProgress > 0 ? 0.95 : 0),
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .frame(width: ringSize - (ringWidth * 0.55), height: ringSize - (ringWidth * 0.55))
                .rotationEffect(.degrees(-90))
                .mask(
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0.0),        // 0°
                                    .init(color: .clear, location: 0.50),       // 180°
                                    .init(color: .white, location: 0.583),      // 210° - start glint
                                    .init(color: .white.opacity(0.9), location: 0.736), // 265° - peak
                                    .init(color: .white, location: 0.861),      // 310° - end glint
                                    .init(color: .clear, location: 0.92),       // 331°
                                    .init(color: .clear, location: 1.0)         // 360°
                                ]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            lineWidth: ringWidth + 4
                        )
                        .frame(width: ringSize - (ringWidth * 0.55), height: ringSize - (ringWidth * 0.55))
                )
            
            // Center content - target number
            VStack(spacing: 4) {
                Text("\(target)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(DSColor.textPrimary)
                
                Text("push-ups")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DSColor.textSecondary.opacity(0.6))
            }
        }
        .padding(24) // Extra padding to prevent glow clipping
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
        }
    }
}

#Preview {
    ZStack {
        DSColor.background
        VStack(spacing: 40) {
            CircularProgressRing(progress: 0.3, completed: 6, target: 20, isComplete: false)
            CircularProgressRing(progress: 1.0, completed: 20, target: 20, isComplete: true)
        }
    }
}
