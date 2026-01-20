//
//  ProgressScreen.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI

struct ProgressScreen: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Progress Tracking")
                    .font(.title)
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressScreen()
}
