//
//  HistoryView.swift
//  Push365
//
//  Created by Lee Chandler on 21/01/2026.
//

import SwiftUI
import SwiftData

struct MonthIdentifier: Equatable, Hashable {
    let year: Int
    let month: Int
}

struct CalendarMonth: Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let days: [CalendarDay]
    
    var displayName: String {
        let components = DateComponents(year: year, month: month, day: 1)
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayOfMonth: Int
    let dayNumber: Int
    let isComplete: Bool
    let isToday: Bool
    let isFuture: Bool
    let isBeforeStart: Bool
    let isPreTracking: Bool
    let isCurrentMonth: Bool
    let completed: Int
    let target: Int
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [DayRecord]
    @Query private var settings: [UserSettings]
    
    @State private var months: [CalendarMonth] = []
    @State private var selectedRange: HistoryRange = .thirtyDays
    @State private var selectedMonth: MonthIdentifier? = nil
    
    private let store = ProgressStore()
    
    enum HistoryRange: String, CaseIterable, Identifiable {
        case thirtyDays = "30 Days"
        case allTime = "All Time"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
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
                
                VStack(spacing: 0) {
                    // Range selector
                    Picker("Range", selection: $selectedRange) {
                        ForEach(HistoryRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if months.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 48))
                                .foregroundStyle(DSColor.textSecondary.opacity(0.3))
                            Text("No history yet")
                                .font(DSFont.body)
                                .foregroundStyle(DSColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            // Monthly summary (only for 30 Days mode)
                            if selectedRange == .thirtyDays, let month = months.first {
                                monthlySummarySection(month: month)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Month navigation (only for 30 Days mode)
                            if selectedRange == .thirtyDays {
                                monthNavigationControls()
                                    .padding(.horizontal, 20)
                            }
                            
                            ScrollView {
                                LazyVStack(spacing: 24) {
                                    ForEach(months) { month in
                                        MonthCalendarView(month: month, settings: settings.first)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadHistory()
            }
            .onChange(of: selectedRange) { _, newValue in
                // Reset month selection when switching to All Time
                if newValue == .allTime {
                    selectedMonth = nil
                }
                Task {
                    await loadHistory()
                }
            }
            .onChange(of: selectedMonth) { _, _ in
                Task {
                    await loadHistory()
                }
            }
        }
    }
    
    // MARK: - Month Navigation
    
    @ViewBuilder
    private func monthNavigationControls() -> some View {
        guard let userSettings = settings.first else { return AnyView(EmptyView()) }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayComponents = calendar.dateComponents([.year, .month], from: today)
        guard let currentYear = todayComponents.year, let currentMonthNum = todayComponents.month else {
            return AnyView(EmptyView())
        }
        let currentMonth = MonthIdentifier(year: currentYear, month: currentMonthNum)
        
        let startComponents = calendar.dateComponents([.year, .month], from: userSettings.programStartDate)
        guard let startYear = startComponents.year, let startMonthNum = startComponents.month else {
            return AnyView(EmptyView())
        }
        let startMonth = MonthIdentifier(year: startYear, month: startMonthNum)
        
        let displayedMonth = selectedMonth ?? currentMonth
        
        // Check if we can go back
        let canGoBack: Bool = {
            guard let displayedDate = calendar.date(from: DateComponents(year: displayedMonth.year, month: displayedMonth.month)),
                  let startDate = calendar.date(from: DateComponents(year: startMonth.year, month: startMonth.month)) else {
                return false
            }
            return displayedDate > startDate
        }()
        
        // Check if we can go forward (not past current month)
        let canGoForward: Bool = {
            guard let displayedDate = calendar.date(from: DateComponents(year: displayedMonth.year, month: displayedMonth.month)),
                  let currentDate = calendar.date(from: DateComponents(year: currentMonth.year, month: currentMonth.month)) else {
                return false
            }
            return displayedDate < currentDate
        }()
        
        return AnyView(
            HStack(spacing: 16) {
                // Previous month button
                Button(action: {
                    navigateMonth(offset: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(canGoBack ? DSColor.accent : DSColor.textSecondary.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(DSColor.surface.opacity(0.5))
                        )
                }
                .disabled(!canGoBack)
                
                // Current month label
                Text(monthDisplayName(year: displayedMonth.year, month: displayedMonth.month))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DSColor.textPrimary)
                    .frame(maxWidth: .infinity)
                
                // Next month button
                Button(action: {
                    navigateMonth(offset: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(canGoForward ? DSColor.accent : DSColor.textSecondary.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(DSColor.surface.opacity(0.5))
                        )
                }
                .disabled(!canGoForward)
            }
            .padding(.vertical, 8)
        )
    }
    
    private func navigateMonth(offset: Int) {
        let calendar = Calendar.current
        let currentMonth = selectedMonth ?? {
            let today = calendar.startOfDay(for: Date())
            let components = calendar.dateComponents([.year, .month], from: today)
            guard let year = components.year, let month = components.month else {
                return MonthIdentifier(year: 2026, month: 1)
            }
            return MonthIdentifier(year: year, month: month)
        }()
        
        guard let currentDate = calendar.date(from: DateComponents(year: currentMonth.year, month: currentMonth.month)),
              let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate) else {
            return
        }
        
        let newComponents = calendar.dateComponents([.year, .month], from: newDate)
        guard let year = newComponents.year, let month = newComponents.month else {
            return
        }
        selectedMonth = MonthIdentifier(year: year, month: month)
    }
    
    private func monthDisplayName(year: Int, month: Int) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month)) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Monthly Summary
    
    @ViewBuilder
    private func monthlySummarySection(month: CalendarMonth) -> some View {
        if settings.first?.trackingStartDate == nil {
            // No tracking start date set, show empty state
            VStack(spacing: 8) {
                Text("No data yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DSColor.textPrimary)
                Text("Complete a day to see your monthly stats.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DSColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DSColor.surface.opacity(0.5))
            )
        } else {
        
        // Eligible days: tracked, not future, >= program start
        let eligibleDays = month.days.filter { day in
            day.isCurrentMonth &&
            !day.isFuture &&
            !day.isBeforeStart &&
            !day.isPreTracking
        }
        
        if eligibleDays.isEmpty {
            // Empty state
            VStack(spacing: 8) {
                Text("No data yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DSColor.textPrimary)
                Text("Complete a day to see your monthly stats.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DSColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DSColor.surface.opacity(0.5))
            )
        } else {
            let summary = calculateMonthlySummary(eligibleDays: eligibleDays)
            
            HStack(spacing: 20) {
                // Completed days
                VStack(spacing: 4) {
                    Text("\(summary.completed)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DSColor.success)
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DSColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                // Missed days
                VStack(spacing: 4) {
                    Text("\(summary.missed)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DSColor.textSecondary)
                    Text("Missed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DSColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                // Completion rate
                VStack(spacing: 4) {
                    Text("\(summary.completionRate)%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DSColor.accent)
                    Text("Success Rate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DSColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DSColor.surface.opacity(0.5))
            )
        }
        }
    }
    
    private func calculateMonthlySummary(eligibleDays: [CalendarDay]) -> (completed: Int, missed: Int, completionRate: Int) {
        // Build dictionary of records for quick lookup
        let recordDict = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.dateKey, $0) })
        
        var completed = 0
        var missed = 0
        
        for day in eligibleDays {
            if let record = recordDict[day.date] {
                if record.isComplete {
                    completed += 1
                } else {
                    missed += 1
                }
            }
            // Days without records are NOT counted as missed (pre-tracking)
        }
        
        let total = completed + missed
        let completionRate: Int = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
        
        return (completed: completed, missed: missed, completionRate: completionRate)
    }
    
    private func loadHistory() async {
        guard let userSettings = settings.first else {
            months = []
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Build dictionary of existing records
        let recordDict = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.dateKey, $0) })
        
        // Determine which months to show
        let monthsToShow: [(year: Int, month: Int)]
        
        switch selectedRange {
        case .thirtyDays:
            // Show selected month (or current month if none selected)
            if let selected = selectedMonth {
                monthsToShow = [(year: selected.year, month: selected.month)]
            } else {
                let components = calendar.dateComponents([.year, .month], from: today)
                guard let year = components.year, let month = components.month else {
                    monthsToShow = []
                    return
                }
                monthsToShow = [(year: year, month: month)]
            }
            
        case .allTime:
            // Show all months from program start to current month
            let startComponents = calendar.dateComponents([.year, .month], from: userSettings.programStartDate)
            let endComponents = calendar.dateComponents([.year, .month], from: today)
            
            var result: [(year: Int, month: Int)] = []
            var current = DateComponents(year: endComponents.year, month: endComponents.month)
            
            while let currentDate = calendar.date(from: current),
                  let startDate = calendar.date(from: startComponents),
                  currentDate >= startDate {
                guard let year = current.year, let month = current.month else {
                    break
                }
                result.append((year: year, month: month))
                
                // Go back one month
                if let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                    let prevComponents = calendar.dateComponents([.year, .month], from: prevMonth)
                    current = DateComponents(year: prevComponents.year, month: prevComponents.month)
                } else {
                    break
                }
            }
            
            monthsToShow = result
        }
        
        // Build calendar months
        var newMonths: [CalendarMonth] = []
        
        for (year, month) in monthsToShow {
            let days = buildMonthDays(year: year, month: month, today: today, userSettings: userSettings, recordDict: recordDict, calendar: calendar)
            newMonths.append(CalendarMonth(year: year, month: month, days: days))
        }
        
        months = newMonths
    }
    
    private func buildMonthDays(
        year: Int,
        month: Int,
        today: Date,
        userSettings: UserSettings,
        recordDict: [Date: DayRecord],
        calendar: Calendar
    ) -> [CalendarDay] {
        var days: [CalendarDay] = []
        
        // Get first day of month
        let monthComponents = DateComponents(year: year, month: month, day: 1)
        guard let firstOfMonth = calendar.date(from: monthComponents) else { return [] }
        
        // Get number of days in month
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        let daysInMonth = range.count
        
        // Get weekday of first day (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // Add empty days for offset (Sunday = 1, so offset = firstWeekday - 1)
        let offset = firstWeekday - 1
        for _ in 0..<offset {
            days.append(CalendarDay(
                date: Date.distantPast,
                dayOfMonth: 0,
                dayNumber: 0,
                isComplete: false,
                isToday: false,
                isFuture: true,
                isBeforeStart: false,
                isPreTracking: false,
                isCurrentMonth: false,
                completed: 0,
                target: 0
            ))
        }
        
        let trackingStart = calendar.startOfDay(for: userSettings.trackingStartDate ?? today)
        
        // Add actual days of month
        for day in 1...daysInMonth {
            let dayComponents = DateComponents(year: year, month: month, day: day)
            guard let date = calendar.date(from: dayComponents) else { continue }
            let dateKey = calendar.startOfDay(for: date)
            
            let isToday = calendar.isDate(dateKey, inSameDayAs: today)
            let isFuture = dateKey > today
            let programStart = calendar.startOfDay(for: userSettings.programStartDate)
            let isBeforeStart = dateKey < programStart
            let isPreTracking = dateKey >= programStart && dateKey < trackingStart && !isBeforeStart
            
            // Calculate day number
            let dayNumber = DayCalculator.dayNumber(for: dateKey, startDate: userSettings.programStartDate)
            
            // Check if record exists
            if let record = recordDict[dateKey] {
                days.append(CalendarDay(
                    date: dateKey,
                    dayOfMonth: day,
                    dayNumber: dayNumber,
                    isComplete: record.isComplete,
                    isToday: isToday,
                    isFuture: isFuture,
                    isBeforeStart: isBeforeStart,
                    isPreTracking: isPreTracking,
                    isCurrentMonth: true,
                    completed: record.completed,
                    target: record.target
                ))
            } else {
                // No record - calculate target
                let target = DayCalculator.resolvedTarget(for: dateKey, dayNumber: dayNumber, settings: userSettings)
                days.append(CalendarDay(
                    date: dateKey,
                    dayOfMonth: day,
                    dayNumber: dayNumber,
                    isComplete: false,
                    isToday: isToday,
                    isFuture: isFuture,
                    isBeforeStart: isBeforeStart,
                    isPreTracking: isPreTracking,
                    isCurrentMonth: true,
                    completed: 0,
                    target: target
                ))
            }
        }
        
        return days
    }
}

struct MonthCalendarView: View {
    let month: CalendarMonth
    let settings: UserSettings?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month header
            Text(month.displayName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DSColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(month.days) { day in
                    if day.isCurrentMonth {
                        NavigationLink(destination: HistoryDetailView(
                            item: HistoryDayItem(
                                dateKey: day.date,
                                dayNumber: day.dayNumber,
                                target: day.target,
                                completed: day.completed,
                                isComplete: day.isComplete,
                                dateString: DateDisplayFormatter.shortDateString(for: day.date, preference: settings?.dateFormatPreference ?? .automatic)
                            )
                        )) {
                            CalendarDayTile(day: day)
                        }
                        .disabled(day.isFuture || day.isBeforeStart || day.isPreTracking)
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Empty cell for offset
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DSColor.surface)
        )
    }
}

struct CalendarDayTile: View {
    let day: CalendarDay
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(day.isFuture || day.isBeforeStart || day.isPreTracking ? DSColor.background : DSColor.surface)
                .opacity(day.isFuture || day.isBeforeStart || day.isPreTracking ? 0.3 : 1.0)
            
            // Today outline
            if day.isToday {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(DSColor.accent.opacity(0.6), lineWidth: 2)
            }
            
            // Completion indicator
            if day.isComplete && !day.isBeforeStart && !day.isPreTracking {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DSColor.success.opacity(0.15))
                
                VStack(spacing: 2) {
                    Text("\(day.dayOfMonth)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DSColor.success)
                    
                    // Green filled dot
                    Circle()
                        .fill(DSColor.success)
                        .frame(width: 6, height: 6)
                }
            } else if day.isBeforeStart {
                // Before program start - very dim
                Text("\(day.dayOfMonth)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DSColor.textSecondary.opacity(0.15))
            } else if day.isPreTracking {
                // Pre-tracking days (between start and tracking start) - slightly less dim
                Text("\(day.dayOfMonth)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DSColor.textSecondary.opacity(0.24))
            } else {
                VStack(spacing: 2) {
                    Text("\(day.dayOfMonth)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(day.isFuture ? DSColor.textSecondary.opacity(0.3) : DSColor.textPrimary)
                    
                    // Past/today incomplete: grey hollow dot (only for tracked days)
                    if !day.isFuture && day.isCurrentMonth {
                        Circle()
                            .stroke(DSColor.textSecondary.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 44)
    }
}

struct HistoryDayItem: Identifiable {
    let id = UUID()
    let dateKey: Date
    let dayNumber: Int
    let target: Int
    let completed: Int
    let isComplete: Bool
    let dateString: String
}

#Preview {
    HistoryView()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
