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
    
    // Services
    private let store = ProgressStore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
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
            
            // Update timestamp
            lastUpdated = Date()
        } catch {
            print("Error loading progress: \(error)")
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
                
                Text("push-ups")
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
