//
//  HomeView.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Local state
    @State private var settings: UserSettings?
    @State private var today: DayRecord?
    @State private var errorMessage: String?
    @State private var showingCustomSheet = false
    @State private var customAmountText = ""
    
    // Services
    private let store = ProgressStore()
    private let motivation = MotivationService()
    private let notificationManager = NotificationManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let today = today, let settings = settings {
                        // Header Section
                        VStack(spacing: 8) {
                            Text("Day \(today.dayNumber)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Text(DateDisplayFormatter.headerString(for: Date(), preference: settings.dateFormatPreference))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Target Card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Target")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(today.target)")
                                        .font(.system(size: 36, weight: .semibold))
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                if today.isComplete {
                                    VStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundStyle(.green)
                                        Text("Complete")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            
                            // Progress Bar
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressView(value: Double(today.completed), total: Double(today.target))
                                    .progressViewStyle(.linear)
                                    .tint(today.isComplete ? .green : Color.accentColor)
                                    .scaleEffect(y: 2)
                                
                                HStack {
                                    Text("Completed: \(today.completed)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("Remaining: \(today.remaining)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Motivation Line
                        Text(motivation.line(forDay: today.dayNumber))
                            .font(.callout)
                            .italic()
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Quick Log Buttons
                        VStack(spacing: 12) {
                            Text("Log Push-ups")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                QuickLogButton(amount: 5) {
                                    logPushups(amount: 5)
                                }
                                QuickLogButton(amount: 10) {
                                    logPushups(amount: 10)
                                }
                                QuickLogButton(amount: 20) {
                                    logPushups(amount: 20)
                                }
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                showingCustomSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Custom Amount")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(Color.accentColor)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Undo Button
                        if !today.logs.isEmpty {
                            Button(action: undoLastLog) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Undo Last Log")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            }
                            .padding(.top, 8)
                        }
                        
                        // Extra reps note
                        if today.isComplete {
                            Text("Extra reps count toward your total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                        
                    } else {
                        // Loading State
                        ProgressView()
                            .padding()
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Push365")
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingCustomSheet) {
                CustomAmountSheet(
                    amountText: $customAmountText,
                    onSave: {
                        if let amount = Int(customAmountText), amount >= 1 {
                            logPushups(amount: amount)
                            showingCustomSheet = false
                            customAmountText = ""
                        }
                    },
                    onCancel: {
                        showingCustomSheet = false
                        customAmountText = ""
                    }
                )
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        do {
            settings = try store.getOrCreateSettings(modelContext: modelContext)
            today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            errorMessage = nil
            
            // Request notification permission (non-blocking)
            _ = await notificationManager.requestPermission()
            
            // Schedule today's notifications
            if let settings = settings, let today = today {
                notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
            }
        } catch {
            errorMessage = "Error loading data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Actions
    
    private func logPushups(amount: Int) {
        do {
            try store.addLog(amount: amount, date: Date(), modelContext: modelContext)
            // Refresh today's record
            today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            errorMessage = nil
            
            // Reschedule notifications with updated remaining count
            if let settings = settings, let today = today {
                notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
            }
        } catch {
            errorMessage = "Error logging: \(error.localizedDescription)"
        }
    }
    
    private func undoLastLog() {
        do {
            try store.undoLastLog(date: Date(), modelContext: modelContext)
            // Refresh today's record
            today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            errorMessage = nil
            
            // Reschedule notifications with updated remaining count
            if let settings = settings, let today = today {
                notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
            }
        } catch {
            errorMessage = "Error undoing: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct QuickLogButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("+\(amount)")
                    .font(.system(size: 24, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
    }
}

struct CustomAmountSheet: View {
    @Binding var amountText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter the number of push-ups")
                    .font(.headline)
                    .padding(.top)
                
                TextField("Amount", text: $amountText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: onSave) {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(Int(amountText) == nil || Int(amountText) ?? 0 < 1)
                
                Spacer()
            }
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
