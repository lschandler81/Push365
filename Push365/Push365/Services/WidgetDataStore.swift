import Foundation
import WidgetKit

struct WidgetSnapshot: Codable, Equatable {
    let dayNumber: Int
    let target: Int
    let completed: Int
    let remaining: Int
    let isComplete: Bool
    let timestamp: Date
}

enum WidgetDataStore {
    private static let suiteName = "group.com.lschandler81.Push365"
    private static let key = "push365_widget_snapshot"

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ WidgetDataStore: Failed to access App Group '\(suiteName)'")
            return nil
        }
        guard let data = defaults.data(forKey: key) else {
            print("⚠️ WidgetDataStore: No data found for key '\(key)'")
            return nil
        }
        guard let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            print("⚠️ WidgetDataStore: Failed to decode snapshot")
            return nil
        }
        print("✅ WidgetDataStore: Loaded snapshot - Day \(snapshot.dayNumber), \(snapshot.completed)/\(snapshot.target)")
        return snapshot
    }

    static func clear() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("⚠️ WidgetDataStore: Failed to access App Group '\(suiteName)' for save")
            return
        }
        guard let data = try? JSONEncoder().encode(snapshot) else {
            print("⚠️ WidgetDataStore: Failed to encode snapshot")
            return
        }
        defaults.set(data, forKey: key)
        defaults.synchronize()
        print("✅ WidgetDataStore: Saved snapshot - Day \(snapshot.dayNumber), \(snapshot.completed)/\(snapshot.target)")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
