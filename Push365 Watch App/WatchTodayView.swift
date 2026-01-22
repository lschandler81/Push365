//
//  WatchTodayView.swift
//  Push365 Watch App
//
//  Created by Lee Chandler on 22/01/2026.
//

import SwiftUI

struct WatchTodayView: View {
    @EnvironmentObject private var connectivity: WatchConnectivityManager
    
    var body: some View {
        ZStack {
            DSColor.background.ignoresSafeArea()
            
            if let dayState = connectivity.dayState {
                ScrollView {
                    VStack(spacing: DSSpacing.md) {
                        // Day number
                        Text("Day \(dayState.dayNumber)")
                            .font(DSFont.caption(size: 11))
                            .foregroundStyle(DSColor.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        // Progress Ring
                        ZStack {
                            // Background ring
                            Circle()
                                .stroke(DSColor.surface, lineWidth: 8)
                                .frame(width: 100, height: 100)
                            
                            // Progress ring
                            Circle()
                                .trim(from: 0, to: min(CGFloat(dayState.completed) / CGFloat(max(1, dayState.target)), 1.0))
                                .stroke(
                                    dayState.isComplete ? Color.green : DSColor.accent,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: dayState.completed)
                            
                            // Center text
                            VStack(spacing: 2) {
                                Text("\(dayState.remaining)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(DSColor.textPrimary)
                                    .monospacedDigit()
                                
                                Text(dayState.isComplete ? "Done!" : "left")
                                    .font(DSFont.caption(size: 9))
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                            
                            // Syncing indicator
                            if connectivity.isSyncing {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .tint(DSColor.accent)
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        .padding(.vertical, DSSpacing.sm)
                        
                        // Target info
                        Text("Target: \(dayState.target)")
                            .font(DSFont.caption(size: 11))
                            .foregroundStyle(DSColor.textSecondary)
                        
                        Divider()
                            .background(DSColor.surface)
                            .padding(.vertical, DSSpacing.xs)
                        
                        // Quick log buttons
                        HStack(spacing: DSSpacing.sm) {
                            QuickLogButton(amount: 1, isComplete: dayState.isComplete, isSyncing: connectivity.isSyncing) {
                                logPushups(1)
                            }
                            
                            QuickLogButton(amount: 5, isComplete: dayState.isComplete, isSyncing: connectivity.isSyncing) {
                                logPushups(5)
                            }
                            
                            QuickLogButton(amount: 10, isComplete: dayState.isComplete, isSyncing: connectivity.isSyncing) {
                                logPushups(10)
                            }
                        }
                        
                        // Undo button
                        Button(action: undoLastLog) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 10))
                                Text("Undo")
                                    .font(DSFont.caption(size: 11))
                            }
                            .foregroundStyle(canUndo ? DSColor.textSecondary : DSColor.textSecondary.opacity(0.3))
                            .padding(.vertical, 6)
                        }
                        .disabled(!canUndo)
                        .buttonStyle(.plain)
                        
                        // Connection status (subtle)
                        if !connectivity.isReachable {
                            HStack(spacing: 4) {
                                Image(systemName: "iphone.slash")
                                    .font(.system(size: 9))
                                Text("Phone disconnected")
                                    .font(DSFont.caption(size: 9))
                            }
                            .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                            .padding(.top, DSSpacing.xs)
                        }
                    }
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.sm)
                }
            } else {
                VStack(spacing: DSSpacing.md) {
                    ProgressView()
                        .tint(DSColor.accent)
                    
                    Text("Connecting to iPhone...")
                        .font(DSFont.caption(size: 11))
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
        }
        .onAppear {
            if connectivity.dayState == nil {
                connectivity.requestInitialState()
            }
        }
    }
    
    private var canUndo: Bool {
        guard let dayState = connectivity.dayState else { return false }
        return dayState.canUndo && !connectivity.isSyncing
    }
    
    // MARK: - Actions
    
    private func logPushups(_ amount: Int) {
        WKInterfaceDevice.current().play(.click)
        connectivity.logPushups(amount)
    }
    
    private func undoLastLog() {
        WKInterfaceDevice.current().play(.click)
        connectivity.undoLastLog()
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let amount: Int
    let isComplete: Bool
    let isSyncing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("+\(amount)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(isDisabled ? DSColor.textSecondary.opacity(0.3) : DSColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: DSRadius.sm)
                        .fill(isDisabled ? DSColor.surface.opacity(0.3) : DSColor.surface)
                )
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
    
    private var isDisabled: Bool {
        isComplete || isSyncing
    }
}
