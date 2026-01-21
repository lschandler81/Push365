//
//  HomeView.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Local state
    @State private var settings: UserSettings?
    @State private var today: DayRecord?
    @State private var errorMessage: String?
    @State private var showingCustomSheet = false
    @State private var customAmountText = ""
    @State private var wasComplete = false
    
    // Services
    private let store = ProgressStore()
    private let motivation = MotivationService()
    private let notificationManager = NotificationManager()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Base dark blue background
                    Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                        .ignoresSafeArea()
                    
                    // Ring-centered spotlight (stronger focus)
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0x2A/255, green: 0x38/255, blue: 0x50/255).opacity(0.9),
                            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if let today = today, let settings = settings {
                            // App title at top (background importance)
                            Text("Push365")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(1.2)
                                .padding(.top, adaptiveTopPadding(for: geometry))
                            
                            Spacer()
                                .frame(height: adaptiveSpacing(for: geometry, base: 20))
                            
                            // Day number and date - the hero alongside ring
                            VStack(spacing: 8) {
                                Text("Day \(today.dayNumber)")
                                    .font(DSFont.dayTitle)
                                    .foregroundStyle(DSColor.textPrimary)
                                
                                Text(DateDisplayFormatter.headerString(for: Date(), preference: settings.dateFormatPreference))
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, adaptiveTopPadding(for: geometry))
                            
                            Spacer()
                                .frame(height: adaptiveSpacing(for: geometry, base: 32))
                            
                            // Circular Progress Ring - the hero
                            CircularProgressRing(
                                progress: Double(today.completed) / Double(max(1, today.target)),
                                completed: today.completed,
                                target: today.target,
                                isComplete: today.isComplete
                            )
                            .onChange(of: today.isComplete) { oldValue, newValue in
                                if newValue && !wasComplete {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    wasComplete = true
                                    
                                    // Immediately cancel evening reminder when target is reached
                                    notificationManager.cancelReminder(for: Date())
                                    
                                    // Fire completion confirmation
                                    notificationManager.notifyCompletion(for: today)
                                }
                            }
                            
                            Spacer()
                                .frame(height: adaptiveSpacing(for: geometry, base: 28))
                            
                            // Streak indicator (small and calm)
                            HStack(spacing: 6) {
                                Text("Streak: \(settings.currentStreak)")
                                    .font(.system(size: 13, weight: .medium))
                                Text("•")
                                    .font(.system(size: 13))
                                Text("Best: \(settings.longestStreak)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                            .padding(.bottom, 8)
                            
                            // Remaining stat (only if not complete)
                            if !today.isComplete {
                                VStack(spacing: 4) {
                                    Text("\(today.remaining)")
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundStyle(DSColor.textPrimary.opacity(0.85))
                                    Text("Remaining")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                                        .textCase(.uppercase)
                                        .tracking(0.8)
                                }
                                
                                Spacer()
                                    .frame(height: adaptiveSpacing(for: geometry, base: 16))
                            }
                            
                            // Status pill (only show when complete)
                            if today.isComplete {
                                Text("Done for today ✅")
                                    .font(DSFont.subheadline)
                                    .foregroundStyle(DSColor.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(DSColor.accent.opacity(0.15))
                                    )
                                
                                Spacer()
                                    .frame(height: adaptiveSpacing(for: geometry, base: 16))
                            }
                            
                            Spacer()
                            
                        } else {
                            ProgressView()
                                .tint(DSColor.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(DSFont.caption)
                                .foregroundStyle(DSColor.destructive)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let today = today {
                    // Bottom control stack (fixed above tab bar)
                    VStack(spacing: 12) {
                        // Quick Log Buttons
                        HStack(spacing: 12) {
                            QuickLogButton(amount: 5, isLocked: today.isComplete) {
                                logPushups(amount: 5)
                            }
                            QuickLogButton(amount: 10, isLocked: today.isComplete) {
                                logPushups(amount: 10)
                            }
                            QuickLogButton(amount: 20, isLocked: today.isComplete) {
                                logPushups(amount: 20)
                            }
                        }
                        
                        // Custom Amount button
                        Button(action: {
                            showingCustomSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: today.isComplete ? "lock.fill" : "plus.circle")
                                    .font(.system(size: 14))
                                Text("Custom Amount")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                today.isComplete ? 
                                    DSColor.surface.opacity(0.3) : 
                                    DSColor.surface.opacity(0.5)
                            )
                            .foregroundStyle(
                                today.isComplete ? 
                                    DSColor.textSecondary.opacity(0.4) : 
                                    DSColor.textSecondary.opacity(0.8)
                            )
                            .cornerRadius(DSRadius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.button)
                                    .strokeBorder(
                                        today.isComplete ? 
                                            DSColor.textSecondary.opacity(0.15) : 
                                            Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .disabled(today.isComplete)
                        
                        // Undo button (always present; disabled when there is nothing to undo)
                        let canUndo = !today.logs.isEmpty
                        
                        Button {
                            guard canUndo else { return }
                            undoLastLog()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 11))
                                Text("Undo Last Log")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(DSColor.surface.opacity(0.3))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(DSColor.textSecondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(!canUndo)
                        .opacity(canUndo ? 1.0 : 0.35)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                            .ignoresSafeArea()
                    )
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingCustomSheet) {
                CustomAmountSheet(
                    amountText: $customAmountText,
                    onSave: {
                        if let amount = Int(customAmountText), amount >= 1 {
                            logPushups(amount: amount)
                            showingCustomSheet = false
                            customAmountText = ""
                        }
                    },
                    onCancel: {
                        showingCustomSheet = false
                        customAmountText = ""
                    }
                )
            }
        }
    }
    
    // MARK: - Adaptive Spacing
    
    private func adaptiveTopPadding(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height < 700 ? 8 : 16
    }
    
    private func adaptiveBottomPadding(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height < 700 ? 16 : 24
    }
    
    private func adaptiveSpacing(for geometry: GeometryProxy, base: CGFloat) -> CGFloat {
        geometry.size.height < 700 ? base * 0.7 : base
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        do {
            settings = try store.getOrCreateSettings(modelContext: modelContext)
            today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            errorMessage = nil
            
            // Reset completion tracking
            wasComplete = today?.isComplete ?? false
            
            // Reset completion tracking
            wasComplete = today?.isComplete ?? false
            
            // Request notification permission (non-blocking)
            _ = await notificationManager.requestPermission()
            
            // Schedule today's notifications
            if let settings = settings, let today = today {
                notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
            }
        } catch {
            errorMessage = "Error loading data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Actions
    
    private func logPushups(amount: Int) {
        do {
            try store.addLog(amount: amount, date: Date(), modelContext: modelContext)
            // Refresh today's record
            today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            errorMessage = nil
            
            // Reschedule notifications with updated remaining count
            if let settings = settings, let today = today {
                notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
            }
        } catch {
            errorMessage = "Error logging: \(error.localizedDescription)"
        }
    }
    
    private func undoLastLog() {
        do {
            try store.undoLastLog(date: Date(), modelContext: modelContext)
            // Refresh today's record
            today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            errorMessage = nil
            
            // Reschedule notifications with updated remaining count
            if let settings = settings, let today = today {
                notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
            }
        } catch {
            errorMessage = "Error undoing: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct QuickLogButton: View {
    let amount: Int
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                }
                Text("+\(amount)")
                    .font(.system(size: 20, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isLocked ? 
                    DSColor.surface.opacity(0.2) : 
                    Color.clear
            )
            .foregroundStyle(
                isLocked ? 
                    DSColor.textSecondary.opacity(0.35) : 
                    DSColor.accent.opacity(0.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.button)
                    .strokeBorder(
                        isLocked ? 
                            DSColor.textSecondary.opacity(0.15) : 
                            DSColor.accent.opacity(0.35),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

struct CustomAmountSheet: View {
    @Binding var amountText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(DSFont.button)
                        .foregroundStyle(DSColor.textSecondary)
                }
                
                Spacer()
                
                Text("Custom Amount")
                    .font(DSFont.button)
                    .fontWeight(.semibold)
                    .foregroundStyle(DSColor.textPrimary)
                
                Spacer()
                
                Text("Cancel")
                    .font(DSFont.button)
                    .foregroundStyle(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DSColor.surface)
            
            Divider()
                .background(DSColor.textSecondary.opacity(0.2))
            
            // Content
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 16)
                
                // Number input
                VStack(spacing: 12) {
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DSColor.textPrimary)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.button)
                                .fill(DSColor.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.button)
                                .strokeBorder(DSColor.accent.opacity(0.4), lineWidth: 2)
                        )
                        .padding(.horizontal, 32)
                    
                    Text("push-ups")
                        .font(DSFont.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                }
                
                // Quick step buttons
                HStack(spacing: 12) {
                    QuickStepButton(label: "+1") {
                        let current = Int(amountText) ?? 0
                        amountText = "\(current + 1)"
                    }
                    
                    QuickStepButton(label: "+5") {
                        let current = Int(amountText) ?? 0
                        amountText = "\(current + 5)"
                    }
                    
                    QuickStepButton(label: "+10") {
                        let current = Int(amountText) ?? 0
                        amountText = "\(current + 10)"
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Save button
                Button(action: onSave) {
                    Text("Save")
                        .font(DSFont.button)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.button)
                                .fill(DSColor.accent)
                        )
                        .foregroundStyle(DSColor.background)
                }
                .disabled(Int(amountText) == nil || Int(amountText) ?? 0 < 1)
                .opacity((Int(amountText) ?? 0) >= 1 ? 1.0 : 0.4)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColor.overlay)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

struct QuickStepButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DSFont.button)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DSRadius.pill)
                        .fill(DSColor.surface)
                )
                .foregroundStyle(DSColor.textSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.pill)
                        .strokeBorder(DSColor.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
