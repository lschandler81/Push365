//
//  Push365Widget.swift
//  Push365Widget
//
//  Created on 23/01/2026.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - App Intent for Logging

struct LogPushupsIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Push-ups"
    
    @Parameter(title: "Amount")
    var amount: Int
    
    init() {}
    
    init(amount: Int) {
        self.amount = amount
    }
    
    func perform() async throws -> some IntentResult {
        // Load current snapshot
        guard var snapshot = WidgetDataStore.load() else {
            return .result()
        }
        
        // Check if it's still today
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(snapshot.timestamp, inSameDayAs: now) {
            // Same day - add to completed count
            let newCompleted = snapshot.completed + amount
            let newRemaining = max(0, snapshot.target - newCompleted)
            let newIsComplete = newRemaining == 0
            
            snapshot = WidgetSnapshot(
                dayNumber: snapshot.dayNumber,
                target: snapshot.target,
                completed: newCompleted,
                remaining: newRemaining,
                isComplete: newIsComplete,
                mode: snapshot.mode,
                programStartDate: snapshot.programStartDate,
                timestamp: now
            )
            
            // Save updated snapshot
            WidgetDataStore.save(snapshot)
        }
        
        return .result()
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), dayNumber: 1, target: 1, completed: 0, hasData: false)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> WidgetEntry {
        WidgetEntry(date: Date(), dayNumber: 1, target: 1, completed: 0, hasData: false)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<WidgetEntry> {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDate)
        
        // Read widget snapshot from shared storage
        let snapshot = WidgetDataStore.load()
        
        var dayNumber = 1
        var target = 1
        var completed = 0
        var hasData = false
        
        if let data = snapshot {
            hasData = true
            
            // Use snapshot data directly
            dayNumber = data.dayNumber
            target = data.target
            completed = data.completed
        }
        
        let entry = WidgetEntry(
            date: currentDate,
            dayNumber: dayNumber,
            target: target,
            completed: completed,
            hasData: hasData
        )
        
        // Update timeline at midnight
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let dayNumber: Int
    let target: Int
    let completed: Int
    let hasData: Bool
    
    var remaining: Int {
        max(0, target - completed)
    }
}

// MARK: - Home Screen Widget

struct Push365WidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        ZStack {
            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
            
            if entry.hasData {
                VStack(spacing: 8) {
                    Text("Day \(entry.dayNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    // Remaining count or DONE
                    if entry.remaining > 0 {
                        VStack(spacing: 4) {
                            Text("\(entry.remaining)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.95))
                            
                            Text("remaining")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } else {
                        Text("DONE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255))
                    }
                    
                    Spacer()
                    
                    // Buttons (only show if not complete)
                    if entry.remaining > 0 {
                        HStack(spacing: 12) {
                            Button(intent: LogPushupsIntent(amount: 5)) {
                                Text("+5")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                            Button(intent: LogPushupsIntent(amount: 10)) {
                                Text("+10")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Text("Push365")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Open app to sync")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
        .overlay(
            Text("v2")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(6),
            alignment: .topTrailing
        )
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        ZStack {
            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
            
            if entry.hasData {
                HStack(spacing: 16) {
                    // Left side - Info
                    VStack(alignment: .leading, spacing: 4) {
                        if entry.remaining > 0 {
                            Text("Day \(entry.dayNumber)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Text("Target: \(entry.target)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        } else {
                            Text("DONE")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255))
                        }
                        
                        Spacer()
                        
                        if entry.remaining > 0 {
                            Text("\(entry.remaining)")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.95))
                            
                            Text("remaining")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Right side - Buttons (only show if not complete)
                    if entry.remaining > 0 {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Button(intent: LogPushupsIntent(amount: 5)) {
                                    Text("+5")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .frame(width: 50, height: 40)
                                        .background(.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                
                                Button(intent: LogPushupsIntent(amount: 10)) {
                                    Text("+10")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .frame(width: 50, height: 40)
                                        .background(.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            HStack(spacing: 8) {
                                Button(intent: LogPushupsIntent(amount: 15)) {
                                    Text("+15")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .frame(width: 50, height: 40)
                                        .background(.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                
                                Button(intent: LogPushupsIntent(amount: 20)) {
                                    Text("+20")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .frame(width: 50, height: 40)
                                        .background(.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            } else {
                VStack(spacing: 8) {
                    Text("Push365")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Open app to sync")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .overlay(
            Text("v2")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(6),
            alignment: .topTrailing
        )
    }
}

struct Push365Widget: Widget {
    let kind: String = "Push365Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Push365WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Push365")
        .description("View your daily push-up target and progress")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure widget")
}

// MARK: - Lock Screen Widget

struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), dayNumber: 1, target: 1, completed: 0, hasData: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: Date(), dayNumber: 1, target: 1, completed: 0, hasData: false))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Read widget snapshot from shared storage
        let snapshot = WidgetDataStore.load()
        
        var dayNumber = 1
        var target = 1
        var completed = 0
        var hasData = false
        
        if let data = snapshot {
            hasData = true
            dayNumber = data.dayNumber
            target = data.target
            completed = data.completed
        }
        
        let entry = WidgetEntry(
            date: currentDate,
            dayNumber: dayNumber,
            target: target,
            completed: completed,
            hasData: hasData
        )
        
        // Update timeline at midnight
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct LockScreenWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        if entry.hasData {
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(entry.dayNumber)")
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 4) {
                    Text("\(entry.remaining)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("left")
                        .font(.system(size: 14, weight: .medium))
                }
            }
        } else {
            Text("Open Push365")
                .font(.system(size: 12, weight: .medium))
        }
    }
}

struct Push365LockScreenWidget: Widget {
    let kind: String = "Push365LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Push365")
        .description("Day and remaining push-ups")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    Push365Widget()
} timeline: {
    WidgetEntry(date: .now, dayNumber: 23, target: 23, completed: 15, hasData: true)
    WidgetEntry(date: .now, dayNumber: 23, target: 23, completed: 23, hasData: true)
}

