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
    
    @State private var firstName: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var selectedMode: ProgressMode = .flexible
    @State private var showBirthdayPicker: Bool = false
    @State private var hasBirthday: Bool = false
    @State private var tempDateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var alreadyStarted: Bool = false
    @State private var startDate: Date = Date()
    @State private var enableBackfill: Bool = false
    @State private var showModeInfo: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    
    @FocusState private var focusedField: FocusField?
    
    private let store = ProgressStore()
    private let notificationManager = NotificationManager()
    
    var onComplete: () -> Void
    
    enum FocusField: Hashable {
        case name
    }
    
    var body: some View {
        ZStack {
            // Base dark blue background
            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
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
            .onTapGesture {
                focusedField = nil
            }
            
            ScrollViewReader { proxy in
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
                                    
                                    let calendar = Calendar.current
                                    let startOfDayStart = calendar.startOfDay(for: startDate)
                                    let startOfDayToday = calendar.startOfDay(for: Date())
                                    let daysDiff = calendar.dateComponents([.day], from: startOfDayStart, to: startOfDayToday).day ?? 0
                                    let dayNumber = max(daysDiff + 1, 1)
                                    
                                    Text("We'll label today as Day \(dayNumber) from your start date.")
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
                        
                        // First name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First name (optional)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DSColor.textSecondary)
                            
                            TextField("Your first name", text: $firstName)
                                .font(.system(size: 17))
                                .foregroundStyle(DSColor.textPrimary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DSColor.background)
                                )
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .name)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                                .id("nameField")
                            
                            Text("Used for friendly reminders")
                                .font(.system(size: 13))
                                .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                        }
                        
                        // Birthday field
                        Button {
                            focusedField = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showBirthdayPicker = true
                            }
                        } label: {
                            HStack {
                                Text("Birthday (optional)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(DSColor.textSecondary)
                                
                                Spacer()
                                
                                Text(hasBirthday ? formatDate(dateOfBirth) : "Not set")
                                    .font(.system(size: 15))
                                    .foregroundStyle(hasBirthday ? DSColor.textPrimary : DSColor.textSecondary.opacity(0.5))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DSColor.background)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // Get Started button
                    Button {
                        focusedField = nil
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
                    .id("getStartedButton")
                    }
                    .onChange(of: focusedField) { _, newValue in
                        if newValue != nil {
                            withAnimation {
                                proxy.scrollTo("nameField", anchor: .center)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .foregroundStyle(DSColor.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showModeInfo) {
            ModeExplanationSheet()
        }
        .sheet(isPresented: $showBirthdayPicker) {
            BirthdayPickerSheet(
                dateOfBirth: $tempDateOfBirth,
                onSave: {
                    dateOfBirth = tempDateOfBirth
                    hasBirthday = true
                    showBirthdayPicker = false
                },
                onCancel: {
                    showBirthdayPicker = false
                }
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func completeOnboarding() {
        Task {
            do {
                // Get or create settings
                let userSettings = try store.getOrCreateSettings(modelContext: modelContext)
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let selectedStartDate = calendar.startOfDay(for: startDate)
                
                // Set program start date and tracking start date
                userSettings.programStartDate = selectedStartDate
                userSettings.trackingStartDate = today
                
                // Trim and save firstName
                let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                userSettings.firstName = trimmedFirstName.isEmpty ? nil : trimmedFirstName
                
                // Migrate old displayName to firstName if needed
                if userSettings.firstName == nil && userSettings.displayName != nil {
                    userSettings.firstName = userSettings.displayName
                }
                
                userSettings.dateOfBirth = hasBirthday ? dateOfBirth : nil
                userSettings.mode = selectedMode
                userSettings.hasCompletedOnboarding = true
                
                // Handle backfill if enabled
                if enableBackfill && selectedStartDate < today {
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                        errorMessage = "Unable to calculate backfill dates. Please try again."
                        isSubmitting = false
                        return
                    }
                    
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
                        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                            break
                        }
                        currentDate = nextDate
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

// MARK: - Birthday Picker Sheet

struct BirthdayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dateOfBirth: Date
    let onSave: () -> Void
    let onCancel: () -> Void
    
    private let minDate: Date = {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? Date()
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                DSColor.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Birthday")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(DSColor.textPrimary)
                        
                        Text("Optional – helps personalize your experience")
                            .font(.system(size: 15))
                            .foregroundStyle(DSColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    DatePicker(
                        "",
                        selection: $dateOfBirth,
                        in: minDate...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(DSColor.accent)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            onSave()
                        } label: {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(DSColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DSColor.accent)
                                )
                        }
                        
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(DSColor.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DSColor.surface)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    WelcomeView(onComplete: {})
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}

