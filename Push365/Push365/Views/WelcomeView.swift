//
//  WelcomeView.swift
//  Push365
//
//  Created by Lee Chandler on 21/01/2026.
//

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    
    @State private var displayName: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var selectedMode: ProgressMode = .flexible
    @State private var showDatePicker: Bool = false
    @State private var alreadyStarted: Bool = false
    @State private var yesterdayTarget: String = ""
    
    private let store = ProgressStore()
    private let notificationManager = NotificationManager()
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Base dark blue background
            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                .ignoresSafeArea()
            
            // Ring-centered spotlight
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
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Welcome to")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Text("Push365")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(DSColor.textPrimary)
                        
                        Text("Build consistency, one day at a time")
                            .font(.system(size: 17))
                            .foregroundStyle(DSColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    
                    // Optional fields card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("About You (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DSColor.textSecondary)
                            
                            TextField("Your name", text: $displayName)
                                .font(.system(size: 17))
                                .foregroundStyle(DSColor.textPrimary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DSColor.background)
                                )
                                .autocorrectionDisabled()
                        }
                        
                        // Birthday field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Birthday")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DSColor.textSecondary)
                            
                            Button {
                                showDatePicker.toggle()
                            } label: {
                                HStack {
                                    Text(showDatePicker ? "Selected" : "Optional")
                                        .font(.system(size: 17))
                                        .foregroundStyle(DSColor.textPrimary.opacity(showDatePicker ? 1 : 0.5))
                                    
                                    Spacer()
                                    
                                    if showDatePicker {
                                        Text(dateOfBirth, style: .date)
                                            .font(.system(size: 17))
                                            .foregroundStyle(DSColor.textPrimary)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                                        .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DSColor.background)
                                )
                            }
                            
                            if showDatePicker {
                                DatePicker(
                                    "",
                                    selection: $dateOfBirth,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // Already Started section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Already started?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Picker("Status", selection: $alreadyStarted) {
                            Text("Starting today").tag(false)
                            Text("I've already started").tag(true)
                        }
                        .pickerStyle(.segmented)
                        
                        if alreadyStarted {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Yesterday's target")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(DSColor.textSecondary)
                                
                                TextField("e.g., 21", text: $yesterdayTarget)
                                    .font(.system(size: 17))
                                    .foregroundStyle(DSColor.textPrimary)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(DSColor.background)
                                    )
                                
                                Text("Enter the push-ups you were meant to do yesterday.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // Progress Mode selection
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Progress Mode")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Picker("Mode", selection: $selectedMode) {
                            ForEach(ProgressMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // Mode explanation
                        VStack(alignment: .leading, spacing: 12) {
                            if selectedMode == .strict {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Today's target equals the day number.")
                                        .font(.system(size: 15))
                                        .foregroundStyle(DSColor.textPrimary)
                                    
                                    Text("Example: Day 21 → target 21, even if you missed yesterday.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Your target only increases after you complete it.")
                                        .font(.system(size: 15))
                                        .foregroundStyle(DSColor.textPrimary)
                                    
                                    Text("Example: If you miss a day, tomorrow stays at last completed + 1.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DSColor.background)
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // Get Started button
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DSColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DSColor.accent)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            do {
                // Get or create settings
                var userSettings = try store.getOrCreateSettings(modelContext: modelContext)
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                let yesterdayKey = calendar.startOfDay(for: yesterday)
                
                // Handle "Already started" logic
                if alreadyStarted, let targetValue = Int(yesterdayTarget), targetValue >= 1 {
                    // Clamp to reasonable range
                    let clampedTarget = min(targetValue, 365)
                    
                    // Calculate programStartDate so yesterday would be day N
                    // If yesterday should be day N, then programStart = yesterday - (N - 1) days
                    let daysBack = clampedTarget - 1
                    if let calculatedStart = calendar.date(byAdding: .day, value: -daysBack, to: yesterdayKey) {
                        userSettings.programStartDate = calculatedStart
                    } else {
                        userSettings.programStartDate = today
                    }
                    
                    // Set completion tracking
                    userSettings.lastCompletedTarget = clampedTarget
                    userSettings.lastCompletedDateKey = yesterdayKey
                    userSettings.currentStreak = 0 // Conservative: don't assume yesterday was completed
                    // longestStreak remains unchanged
                } else {
                    // Starting today: Day 1
                    userSettings.programStartDate = today
                    // Don't modify streak/completion fields - let first completion handle it
                }
                
                // Save onboarding data
                userSettings.displayName = displayName.isEmpty ? nil : displayName
                userSettings.dateOfBirth = showDatePicker ? dateOfBirth : nil
                userSettings.mode = selectedMode
                userSettings.hasCompletedOnboarding = true
                
                try modelContext.save()
                
                // Request notification permission
                let granted = await notificationManager.requestPermission()
                
                if granted && userSettings.notificationsEnabled {
                    // Schedule notifications for today
                    let today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
                    notificationManager.scheduleNotifications(for: Date(), settings: userSettings, record: today)
                }
                
                // Complete
                onComplete()
            } catch {
                print("Error completing onboarding: \(error)")
            }
        }
    }
}

#Preview {
    WelcomeView(onComplete: {})
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
