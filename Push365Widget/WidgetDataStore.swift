//
//  WidgetDataStore.swift
//  Push365Widget
//
//  Created on 23/01/2026.
//

import Foundation

struct WidgetData: Codable {
    let programStartDate: Date
    let mode: String
    let lastCompletedTarget: Int
    let todayDate: Date
    let todayCompleted: Int
}

class WidgetDataStore {
    static let shared = WidgetDataStore()
    
    private let suiteName = "group.com.push365.app"
    private let dataKey = "widgetData"
    
    private init() {}
    
    func saveData(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: dataKey)
            defaults.synchronize()
        }
    }
    
    func loadData() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        guard let data = defaults.data(forKey: dataKey) else { return nil }
        
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
