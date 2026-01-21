//
//  HistoryView.swift
//  Push365
//
//  Created by Lee Chandler on 21/01/2026.
//

import SwiftUI
import SwiftData

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
            .navigationTitle("History")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadHistory()
            }
            .onChange(of: selectedRange) { _, _ in
                Task {
                    await loadHistory()
                }
            }
        }
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
            // Show current month only
            let components = calendar.dateComponents([.year, .month], from: today)
            monthsToShow = [(year: components.year!, month: components.month!)]
            
        case .allTime:
            // Show all months from program start to current month
            let startComponents = calendar.dateComponents([.year, .month], from: userSettings.programStartDate)
            let endComponents = calendar.dateComponents([.year, .month], from: today)
            
            var result: [(year: Int, month: Int)] = []
            var current = DateComponents(year: endComponents.year, month: endComponents.month)
            
            while let currentDate = calendar.date(from: current),
                  let startDate = calendar.date(from: startComponents),
                  currentDate >= startDate {
                result.append((year: current.year!, month: current.month!))
                
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
                isCurrentMonth: false,
                completed: 0,
                target: 0
            ))
        }
        
        // Add actual days of month
        for day in 1...daysInMonth {
            let dayComponents = DateComponents(year: year, month: month, day: day)
            guard let date = calendar.date(from: dayComponents) else { continue }
            let dateKey = calendar.startOfDay(for: date)
            
            let isToday = calendar.isDate(dateKey, inSameDayAs: today)
            let isFuture = dateKey > today
            
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
                        .disabled(day.isFuture)
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
                .fill(day.isFuture ? DSColor.background : DSColor.surface)
                .opacity(day.isFuture ? 0.3 : 1.0)
            
            // Today outline
            if day.isToday {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(DSColor.accent.opacity(0.6), lineWidth: 2)
            }
            
            // Completion indicator
            if day.isComplete {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DSColor.success.opacity(0.15))
                
                VStack(spacing: 2) {
                    Text("\(day.dayOfMonth)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DSColor.success)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DSColor.success.opacity(0.8))
                }
            } else {
                VStack(spacing: 2) {
                    Text("\(day.dayOfMonth)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(day.isFuture ? DSColor.textSecondary.opacity(0.3) : DSColor.textPrimary)
                    
                    if !day.isFuture && day.isCurrentMonth {
                        Circle()
                            .stroke(DSColor.textSecondary.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 10, height: 10)
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
