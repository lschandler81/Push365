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
                VStack(spacing: 24) {
                    // Streaks Section
                    VStack(spacing: 16) {
                        Text("Streaks")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Current Streak",
                                value: "\(currentStreak)",
                                subtitle: currentStreak == 1 ? "day" : "days",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Longest Streak",
                                value: "\(longestStreak)",
                                subtitle: longestStreak == 1 ? "day" : "days",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Totals Section
                    VStack(spacing: 16) {
                        Text("Totals")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TotalRow(
                                title: "Year-to-Date",
                                value: yearToDateTotal,
                                icon: "calendar"
                            )
                            
                            Divider()
                                .padding(.horizontal)
                            
                            TotalRow(
                                title: "Lifetime",
                                value: lifetimeTotal,
                                icon: "infinity"
                            )
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Last Updated
                    if let settings = settings {
                        Text("Last updated: \(DateDisplayFormatter.shortDateString(for: lastUpdated, preference: settings.dateFormatPreference))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
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
            
            // Calculate streaks
            let todayKey = DayCalculator.dateKey(for: Date())
            currentStreak = store.currentStreak(records: records, todayKey: todayKey)
            longestStreak = store.longestStreak(records: records)
            
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
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct TotalRow: View {
    let title: String
    let value: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("push-ups")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    ProgressScreen()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
