import SwiftUI
import WidgetKit
import WatchKit

// NOTE: Ensure WidgetSnapshot and WidgetDataStore are included in the Watch app target membership
// and that the App Group capability is enabled with: group.com.lschandler81.Push365

struct WatchLoggingView: View {
    @State private var snapshot: WidgetSnapshot?
    @State private var isLoading = true
    @State private var isDoneHapticFired = false

    private let greenDone = Color(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255)
    private let background = Color(red: 0x1E/255, green: 0x1E/255, blue: 0x1E/255)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if let s = snapshot {
                VStack(spacing: 12) {
                    // Day label
                    Text("Day \(s.dayNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 6)

                    // Remaining or DONE
                    if s.remaining > 0 {
                        VStack(spacing: 4) {
                            Text("\(s.remaining)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.95))
                            Text("remaining")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } else {
                        Text("DONE")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(greenDone)
                            .onAppear {
                                // Strong success haptic once on reaching DONE
                                if !isDoneHapticFired {
                                    WKInterfaceDevice.current().play(.success)
                                    isDoneHapticFired = true
                                }
                            }
                    }

                    Spacer()

                    // Buttons (hidden when DONE)
                    if s.remaining > 0 {
                        HStack(spacing: 8) {
                            loggingButton("+5", amount: 5)
                            loggingButton("+10", amount: 10)
                            loggingButton("+20", amount: 20)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white.opacity(0.9))
                    }
                    Text("Open Push365 on iPhone to sync")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
            }
        }
        .onAppear {
            loadSnapshot()
        }
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func loggingButton(_ title: String, amount: Int) -> some View {
        Button {
            log(amount: amount)
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func loadSnapshot() {
        isLoading = true
        let loaded = WidgetDataStore.load()
        snapshot = loaded
        isLoading = false
    }

    private func log(amount: Int) {
        guard var s = snapshot else { return }

        let now = Date()
        let calendar = Calendar.current
        if !calendar.isDate(s.timestamp, inSameDayAs: now) {
            // If stale, refresh and bail
            loadSnapshot()
            return
        }

        // Immediate haptic feedback
        WKInterfaceDevice.current().play(.click)

        // Update local snapshot immediately
        let newCompleted = s.completed + amount
        let newRemaining = max(0, s.target - newCompleted)
        let newIsComplete = newRemaining == 0

        s = WidgetSnapshot(
            dayNumber: s.dayNumber,
            target: s.target,
            completed: newCompleted,
            remaining: newRemaining,
            isComplete: newIsComplete,
            mode: s.mode,
            programStartDate: s.programStartDate,
            timestamp: now
        )
        snapshot = s

        // Persist to shared store (App Group)
        WidgetDataStore.save(s)

        // Stronger haptic if DONE reached now; otherwise firm feedback
        if newIsComplete {
            WKInterfaceDevice.current().play(.success)
            isDoneHapticFired = true
        } else {
            WKInterfaceDevice.current().play(.directionUp)
        }

        // Refresh complications/widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    WatchLoggingView()
}
