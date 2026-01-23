import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Push365: The Rules")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("This is not a workout plan.")
                            .font(.system(size: 18))
                        Text("It's a commitment.")
                            .font(.system(size: 18))
                    }
                    
                    // The Rule
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The Rule")
                            .font(.system(size: 22, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Every day, you do one more push-up than yesterday.")
                            BulletPoint(text: "There are no rest days.")
                            BulletPoint(text: "Today's number is the only thing that matters.")
                        }
                    }
                    
                    // Completion
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Completion")
                            .font(.system(size: 22, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "A day is complete when you hit today's target.")
                            BulletPoint(text: "Partial effort doesn't count.")
                            BulletPoint(text: "Miss a day, and the streak resets.")
                        }
                    }
                    
                    // Protocol Days
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Protocol Days")
                            .font(.system(size: 22, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Life happens. Injury happens.")
                            BulletPoint(text: "On rare days, you may complete a Protocol Day:")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "One strict rep", indent: 1)
                                BulletPoint(text: "Or a modified version (incline, knees)", indent: 1)
                            }
                            .padding(.leading, 20)
                            
                            BulletPoint(text: "Protocol Days preserve continuity, but do not increase the target.")
                            BulletPoint(text: "They are limited. They are intentional. They are not rest days.")
                        }
                    }
                    
                    // What This App Will Not Do
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What This App Will Not Do")
                            .font(.system(size: 22, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "No social feeds")
                            BulletPoint(text: "No leaderboards")
                            BulletPoint(text: "No motivational quotes")
                            BulletPoint(text: "No excuses")
                        }
                    }
                    
                    // Who This Is For
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who This Is For")
                            .font(.system(size: 22, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "People who value consistency over intensity")
                            BulletPoint(text: "People who want fewer decisions, not more")
                            BulletPoint(text: "People willing to show up daily")
                        }
                    }
                    
                    // Who This Is Not For
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who This Is Not For")
                            .font(.system(size: 22, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Anyone looking for flexibility")
                            BulletPoint(text: "Anyone training for optimization")
                            BulletPoint(text: "Anyone who wants permission to skip")
                        }
                    }
                    
                    // Closing
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You don't need motivation.")
                            .font(.system(size: 18))
                        Text("You need a rule.")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    var indent: Int = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 16))
        }
    }
}

#Preview {
    RulesView()
}
