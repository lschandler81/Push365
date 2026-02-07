//
//  ProgressScreen.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.modelContext) private var modelContext
    
    // Local state
    @State private var currentStreak: Int = 0
    @State private var longestStreak: Int = 0
    @State private var lifetimeTotal: Int = 0
    @State private var yearToDateTotal: Int = 0
    @State private var lastUpdated: Date = Date()
    @State private var settings: UserSettings?
    @State private var thirtyDayCompletions: Int = 0
    @State private var thirtyDaySuccessRate: Int = 0
    @State private var avgCompletionTime: String = "—"
    
    // Services
    private let store = ProgressStore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Insights Section
                    VStack(spacing: 16) {
                        Text("Insights")
                            .font(DSFont.sectionHeader)
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            InsightRow(
                                title: "30-day success rate",
                                value: "\(thirtyDaySuccessRate)%",
                                subtitle: "completion rate",
                                icon: "chart.bar.fill"
                            )
                            
                            Divider()
                                .background(DSColor.textSecondary.opacity(0.2))
                                .padding(.horizontal, 20)
                            
                            InsightRow(
                                title: "30-day completions",
                                value: "\(thirtyDayCompletions)",
                                subtitle: thirtyDayCompletions == 1 ? "day" : "days",
                                icon: "calendar.badge.checkmark"
                            )
                            
                            Divider()
                                .background(DSColor.textSecondary.opacity(0.2))
                                .padding(.horizontal, 20)
                            
                            InsightRow(
                                title: "Avg completion time",
                                value: avgCompletionTime,
                                subtitle: avgCompletionTime != "—" ? "last 30 days" : "no data",
                                icon: "clock"
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.card)
                                .fill(DSColor.surface)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Streaks Section
                    VStack(spacing: 16) {
                        Text("Streaks")
                            .font(DSFont.sectionHeader)
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Current Streak",
                                value: "\(currentStreak)",
                                subtitle: currentStreak == 1 ? "day" : "days",
                                icon: "flame.fill",
                                color: DSColor.accent
                            )
                            
                            StatCard(
                                title: "Longest Streak",
                                value: "\(longestStreak)",
                                subtitle: longestStreak == 1 ? "day" : "days",
                                icon: "trophy.fill",
                                color: Color(red: 1.0, green: 0.8, blue: 0.4)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Totals Section
                    VStack(spacing: 16) {
                        Text("Totals")
                            .font(DSFont.sectionHeader)
                            .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            TotalRow(
                                title: "Year-to-Date",
                                value: yearToDateTotal,
                                icon: "calendar"
                            )
                            
                            Divider()
                                .background(DSColor.textSecondary.opacity(0.2))
                                .padding(.horizontal, 20)
                            
                            TotalRow(
                                title: "Lifetime",
                                value: lifetimeTotal,
                                icon: "infinity"
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.card)
                                .fill(DSColor.surface)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Last Updated
                    if let settings = settings {
                        Text("Last updated: \(DateDisplayFormatter.shortDateString(for: lastUpdated, preference: settings.dateFormatPreference))")
                            .font(DSFont.caption)
                            .foregroundStyle(DSColor.textSecondary.opacity(0.6))
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(DSColor.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadProgress()
            }
            .refreshable {
                await loadProgress()
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadProgress() async {
        do {
            // Load settings
            settings = try store.getOrCreateSettings(modelContext: modelContext)
            
            // Fetch all records
            let records = try store.allRecords(modelContext: modelContext)
            
            // Get streaks from settings (source of truth)
            if let settings = settings {
                currentStreak = settings.currentStreak
                longestStreak = settings.longestStreak
            }
            
            // Calculate totals
            let totals = store.totals(records: records)
            lifetimeTotal = totals.lifetime
            yearToDateTotal = totals.yearToDate
            
            // Calculate insights
            calculateInsights(records: records)
            
            // Update timestamp
            lastUpdated = Date()
        } catch {
            // Silent error handling
        }
    }
    
    private func calculateInsights(records: [DayRecord]) {
        guard let settings = settings else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let programStart = settings.programStartDate
        
        // Filter to last 30 days, only past/today, >= programStartDate
        let recentRecords = records.filter { record in
            record.dateKey >= thirtyDaysAgo &&
            record.dateKey <= today &&
            record.dateKey >= programStart
        }
        
        // Count completions
        thirtyDayCompletions = recentRecords.filter { $0.isComplete }.count
        
        // Calculate 30-day success rate
        let totalEligibleDays = recentRecords.count
        thirtyDaySuccessRate = totalEligibleDays > 0 ? Int((Double(thirtyDayCompletions) / Double(totalEligibleDays)) * 100) : 0
        
        // Calculate average completion time
        let completedRecords = recentRecords.filter { $0.isComplete }
        
        if completedRecords.isEmpty {
            avgCompletionTime = "—"
        } else {
            var totalSeconds: TimeInterval = 0
            var validCount = 0
            
            for record in completedRecords {
                // Find the log that caused completion
                let sortedLogs = record.logs.sorted { $0.timestamp < $1.timestamp }
                
                var cumulativeTotal = 0
                var completionLog: LogEntry?
                
                for log in sortedLogs {
                    cumulativeTotal += log.amount
                    if cumulativeTotal >= record.target {
                        completionLog = log
                        break
                    }
                }
                
                // Use completion log timestamp or last log timestamp
                if let timestamp = (completionLog ?? sortedLogs.last)?.timestamp {
                    let components = calendar.dateComponents([.hour, .minute, .second], from: timestamp)
                    if let hour = components.hour, let minute = components.minute, let second = components.second {
                        let secondsSinceMidnight = TimeInterval(hour * 3600 + minute * 60 + second)
                        totalSeconds += secondsSinceMidnight
                        validCount += 1
                    }
                }
            }
            
            if validCount > 0 {
                let avgSeconds = totalSeconds / Double(validCount)
                let avgHour = Int(avgSeconds) / 3600
                let avgMinute = (Int(avgSeconds) % 3600) / 60
                avgCompletionTime = String(format: "%02d:%02d", avgHour, avgMinute)
            } else {
                avgCompletionTime = "—"
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)
            
            Text(value)
                .font(DSFont.largeNumber)
                .foregroundStyle(DSColor.textPrimary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColor.textSecondary)
                
                Text(subtitle)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .fill(DSColor.surface)
        )
    }
}

struct TotalRow: View {
    let title: String
    let value: Int
    let icon: String

    private var pushUpLabel: String {
        value == 1 ? "push-up" : "push-ups"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                .frame(width: 28)
            
            Text(title)
                .font(DSFont.button)
                .foregroundStyle(DSColor.textPrimary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(value)")
                    .font(DSFont.mediumNumber)
                    .foregroundStyle(DSColor.textPrimary)
                
                Text(pushUpLabel)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DSColor.accent.opacity(0.8))
                .frame(width: 28)
            
            Text(title)
                .font(DSFont.button)
                .foregroundStyle(DSColor.textPrimary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(DSFont.mediumNumber)
                    .foregroundStyle(DSColor.textPrimary)
                
                Text(subtitle)
                    .font(DSFont.caption)
                    .foregroundStyle(DSColor.textSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#Preview {
    ProgressScreen()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
