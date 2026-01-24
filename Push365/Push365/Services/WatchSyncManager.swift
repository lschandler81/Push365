import Foundation
import Combine

final class WatchSyncManager: ObservableObject {
    static let shared = WatchSyncManager()
    private init() {}

    @Published var snapshot: DaySnapshot?

    func activate() { }
    func requestSnapshot() { }
    func sendLog(amount: Int) { }
}
