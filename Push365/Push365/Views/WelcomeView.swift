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
    @State private var startDate: Date = Date()
    @State private var enableBackfill: Bool = false
    @State private var showModeInfo: Bool = false
    
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
                    
                    // Progress Mode Card (FIRST - defines the rules)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Progress Mode")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            Spacer()
                            
                            Button {
                                showModeInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                            }
                        }
                        
                        Picker("Mode", selection: $selectedMode) {
                            ForEach(ProgressMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(selectedMode == .strict ? "Target matches the day number." : "Target only increases after you complete it.")
                            .font(.system(size: 14))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // Start Context Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Start")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        VStack(spacing: 16) {
                            // Starting today (default)
                            Button {
                                alreadyStarted = false
                                startDate = Date()
                                enableBackfill = false
                            } label: {
                                HStack {
                                    Image(systemName: alreadyStarted ? "circle" : "circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(DSColor.accent)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Starting today")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(DSColor.textPrimary)
                                        Text("Begin your Push365 challenge now.")
                                            .font(.system(size: 13))
                                            .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(alreadyStarted ? Color.clear : DSColor.background.opacity(0.5))
                                )
                            }
                            
                            // Already started
                            Button {
                                alreadyStarted = true
                            } label: {
                                HStack {
                                    Image(systemName: alreadyStarted ? "circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(DSColor.accent)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("I've already started")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(DSColor.textPrimary)
                                        Text("Backdate your start for accurate stats.")
                                            .font(.system(size: 13))
                                            .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(alreadyStarted ? DSColor.background.opacity(0.5) : Color.clear)
                                )
                            }
                        }
                        
                        // Show date picker if already started
                        if alreadyStarted {
                            VStack(alignment: .leading, spacing: 12) {
                                Divider()
                                    .background(DSColor.textSecondary.opacity(0.2))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Start date")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(DSColor.textSecondary)
                                    
                                    DatePicker(
                                        "",
                                        selection: $startDate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .tint(DSColor.accent)
                                    
                                    Text("We'll label today as Day \(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: Date())).day! + 1) from your start date.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                                }
                                
                                // Backfill toggle (only if start date is before today)
                                let today = Calendar.current.startOfDay(for: Date())
                                let selectedDay = Calendar.current.startOfDay(for: startDate)
                                
                                if selectedDay < today {
                                    Divider()
                                        .background(DSColor.textSecondary.opacity(0.2))
                                    
                                    Toggle(isOn: $enableBackfill) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Mark previous days as complete")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(DSColor.textPrimary)
                                            
                                            Text("Use this if you've already been doing Push365 and want accurate streaks and stats.")
                                                .font(.system(size: 13))
                                                .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                                        }
                                    }
                                    .tint(DSColor.accent)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // About You Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("About You (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name (optional)")
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
                            Button {
                                showDatePicker.toggle()
                            } label: {
                                HStack {
                                    Text("Birthday (optional)")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(DSColor.textSecondary)
                                    
                                    Spacer()
                                    
                                    if showDatePicker {
                                        Text(dateOfBirth, style: .date)
                                            .font(.system(size: 15))
                                            .foregroundStyle(DSColor.textPrimary)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                                        .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                                }
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
            .sheet(isPresented: $showModeInfo) {
                ModeExplanationSheet()
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
                let selectedStartDate = calendar.startOfDay(for: startDate)
                
                // Set program start date and tracking start date
                userSettings.programStartDate = selectedStartDate
                userSettings.trackingStartDate = today
                
                // Save onboarding data
                userSettings.displayName = displayName.isEmpty ? nil : displayName
                userSettings.dateOfBirth = showDatePicker ? dateOfBirth : nil
                userSettings.mode = selectedMode
                userSettings.hasCompletedOnboarding = true
                
                // Handle backfill if enabled
                if enableBackfill && selectedStartDate < today {
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                    
                    // Create DayRecords for each day from start date to yesterday
                    var currentDate = selectedStartDate
                    var backfilledCount = 0
                    
                    while currentDate <= yesterday {
                        let dayNum = DayCalculator.dayNumber(for: currentDate, startDate: selectedStartDate)
                        let targetValue = max(1, dayNum)
                        
                        // Create the day record marked as complete (no individual logs)
                        let record = DayRecord(
                            dateKey: currentDate,
                            dayNumber: dayNum,
                            target: targetValue,
                            completed: targetValue
                        )
                        
                        modelContext.insert(record)
                        
                        backfilledCount += 1
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                    }
                    
                    // Update streak tracking
                    if backfilledCount > 0 {
                        userSettings.currentStreak = backfilledCount
                        userSettings.longestStreak = backfilledCount
                        userSettings.lastCompletedDateKey = yesterday
                        let yesterdayNum = DayCalculator.dayNumber(for: yesterday, startDate: selectedStartDate)
                        userSettings.lastCompletedTarget = max(1, yesterdayNum)
                    }
                }
                
                try modelContext.save()
                
                // Request notification permission
                let granted = await notificationManager.requestPermission()
                
                if granted && userSettings.notificationsEnabled {
                    // Schedule notifications for today
                    let todayRecord = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
                    notificationManager.scheduleNotifications(for: Date(), settings: userSettings, record: todayRecord)
                }
                
                // Complete
                onComplete()
            } catch {
                print("Error completing onboarding: \(error)")
            }
        }
    }
}

// MARK: - Mode Explanation Sheet

struct ModeExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DSColor.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Strict Mode")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DSColor.textPrimary)
                        
                        Text("Target matches the day number.")
                            .font(.system(size: 15))
                            .foregroundStyle(DSColor.textSecondary)
                        
                        Text("Example: If you start Jan 1: Day 3 target is 3.")
                            .font(.system(size: 14))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                            .padding(.leading, 12)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Flexible Mode")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DSColor.textPrimary)
                        
                        Text("Target only increases after you complete it.")
                            .font(.system(size: 15))
                            .foregroundStyle(DSColor.textSecondary)
                        
                        Text("Example: If you miss a day: tomorrow stays at last completed + 1.")
                            .font(.system(size: 14))
                            .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                            .padding(.leading, 12)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Progress Modes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DSColor.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    WelcomeView(onComplete: {})
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
