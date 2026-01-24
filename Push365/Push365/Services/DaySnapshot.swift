import Foundation

struct DaySnapshot: Codable, Equatable {
    let dayNumber: Int
    let target: Int
    let completed: Int
    let remaining: Int
    let isComplete: Bool
    let timestamp: Date
}
