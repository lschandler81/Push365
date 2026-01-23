import WidgetKit
import SwiftUI

// MARK: - Entry

struct Push365Entry: TimelineEntry {
    let date: Date
    let dayNumber: Int
    let target: Int
    let completed: Int
    let remaining: Int
    let isComplete: Bool
    let hasData: Bool
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: Push365Entry
    var body: some View {
        switch family {
        case .systemSmall:
            Push365SmallView(entry: entry)
        case .systemMedium:
            Push365MediumView(entry: entry)
        default:
            Push365SmallView(entry: entry)
        }
    }
}

// MARK: - Provider

struct Push365Provider: TimelineProvider {

    func placeholder(in context: Context) -> Push365Entry {
        // Use stored data if available; otherwise show fallback state
        if let snapshot = WidgetDataStore.load() {
            return Push365Entry(
                date: Date(),
                dayNumber: snapshot.dayNumber,
                target: snapshot.target,
                completed: snapshot.completed,
                remaining: snapshot.remaining,
                isComplete: snapshot.isComplete,
                hasData: true
            )
        }
        return Push365Entry(
            date: Date(),
            dayNumber: 0,
            target: 0,
            completed: 0,
            remaining: 0,
            isComplete: false,
            hasData: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Push365Entry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Push365Entry>) -> Void) {
        let entry = loadEntry()

        // Schedule refresh at next midnight
        let calendar = Calendar.current
        let now = Date()
        let startOfTomorrow = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? now.addingTimeInterval(60 * 60 * 6)

        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        completion(timeline)
    }

    private func loadEntry() -> Push365Entry {
        guard let data = WidgetDataStore.load() else {
            return Push365Entry(
                date: Date(),
                dayNumber: 0,
                target: 0,
                completed: 0,
                remaining: 0,
                isComplete: false,
                hasData: false
            )
        }
        return Push365Entry(
            date: Date(),
            dayNumber: data.dayNumber,
            target: data.target,
            completed: data.completed,
            remaining: data.remaining,
            isComplete: data.isComplete,
            hasData: true
        )
    }
}

// MARK: - Views

struct Push365SmallView: View {
    let entry: Push365Entry

    var body: some View {
        ZStack {
            Color.black
            if entry.hasData {
                VStack(spacing: 6) {
                    Text("Day \(entry.dayNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 0)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(entry.remaining)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Text("left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
            } else {
                Text("Open Push365 to sync")
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(12)
            }
        }
        .containerBackground(.black, for: .widget)
    }
}

struct Push365MediumView: View {
    let entry: Push365Entry

    var body: some View {
        ZStack {
            Color.black
            if entry.hasData {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Day \(entry.dayNumber)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Target: \(entry.target)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(entry.remaining)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        Text("left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(16)
            } else {
                Text("Open Push365 to sync")
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(16)
            }
        }
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - Widget

struct Push365Widget: Widget {
    let kind = "Push365Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Push365Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Push365")
        .description("Today's day number, target, and remaining.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

