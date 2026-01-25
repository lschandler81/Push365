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
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func clear() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
