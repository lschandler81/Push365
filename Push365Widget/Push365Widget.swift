//
//  Push365Widget.swift
//  Push365Widget
//
//  Created on 23/01/2026.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), dayNumber: 1, target: 1, completed: 0, hasData: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(date: Date(), dayNumber: 1, target: 1, completed: 0, hasData: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDate)
        
        // Read widget data from shared storage
        let widgetData = WidgetDataStore.shared.loadData()
        
        var dayNumber = 1
        var target = 1
        var completed = 0
        var hasData = false
        
        if let data = widgetData {
            hasData = true
            
            // Calculate day number based on start date
            let startDate = calendar.startOfDay(for: data.programStartDate)
            let components = calendar.dateComponents([.day], from: startDate, to: startOfToday)
            dayNumber = (components.day ?? 0) + 1
            
            // Calculate target based on mode
            if data.mode == "strict" {
                target = dayNumber
            } else {
                // Flexible: use last completed target + 1, or day number if no completions
                target = data.lastCompletedTarget > 0 ? data.lastCompletedTarget + 1 : dayNumber
            }
            
            // Use completed value if today matches stored date
            if calendar.isDate(data.todayDate, inSameDayAs: startOfToday) {
                completed = data.todayCompleted
            } else {
                completed = 0
            }
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
                    
                    Text("\(entry.remaining)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.95))
                    
                    Text("remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
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
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        ZStack {
            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
            
            if entry.hasData {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(entry.dayNumber)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("Target: \(entry.target)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(entry.remaining)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.95))
                        
                        Text("remaining")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
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
    }
}

struct Push365Widget: Widget {
    let kind: String = "Push365Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Push365WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Push365")
        .description("View your daily push-up target and progress")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Lock Screen Widget

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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
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
