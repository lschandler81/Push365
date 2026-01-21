//
//  HistoryDetailView.swift
//  Push365
//
//  Created by Lee Chandler on 21/01/2026.
//

import SwiftUI
import SwiftData

struct HistoryDetailView: View {
    let item: HistoryDayItem
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [DayRecord]
    
    @State private var logs: [LogEntry] = []
    
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
                VStack(spacing: 24) {
                    // Summary Card
                    VStack(spacing: 16) {
                        Text("Day \(item.dayNumber)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(DSColor.textPrimary)
                        
                        Text(item.dateString)
                            .font(.system(size: 16))
                            .foregroundStyle(DSColor.textSecondary)
                        
                        Divider()
                            .background(DSColor.textSecondary.opacity(0.2))
                            .padding(.vertical, 8)
                        
                        HStack(spacing: 32) {
                            VStack(spacing: 8) {
                                Text("\(item.completed)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(DSColor.textPrimary)
                                Text("Completed")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(DSColor.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                            
                            VStack(spacing: 8) {
                                Text("\(item.target)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(DSColor.textPrimary)
                                Text("Target")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(DSColor.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                        }
                        
                        // Status badge
                        Text(item.isComplete ? "✓ Completed" : "Incomplete")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(item.isComplete ? DSColor.success : DSColor.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(item.isComplete ? DSColor.success.opacity(0.15) : DSColor.surface)
                            )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DSColor.surface)
                    )
                    .padding(.horizontal, 20)
                    
                    // Log entries
                    if !logs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Log Entries")
                                .font(DSFont.sectionHeader)
                                .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(1)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(logs, id: \.id) { log in
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(DSColor.accent)
                                        
                                        Text("\(log.amount) push-ups")
                                            .font(.system(size: 15))
                                            .foregroundStyle(DSColor.textPrimary)
                                        
                                        Spacer()
                                        
                                        Text(log.timestamp, style: .time)
                                            .font(.system(size: 13))
                                            .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(DSColor.surface)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else if item.completed == 0 {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(DSColor.textSecondary.opacity(0.3))
                            Text("No activity recorded")
                                .font(.system(size: 15))
                                .foregroundStyle(DSColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Day Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            loadLogs()
        }
    }
    
    private func loadLogs() {
        // Find the record for this date
        if let record = allRecords.first(where: { $0.dateKey == item.dateKey }) {
            logs = record.logs.sorted { $0.timestamp < $1.timestamp }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(item: HistoryDayItem(
            dateKey: Date(),
            dayNumber: 5,
            target: 20,
            completed: 15,
            isComplete: false,
            dateString: "21 Jan 2026"
        ))
    }
    .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
