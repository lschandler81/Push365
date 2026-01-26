import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Match your app background
            LinearGradient(
                colors: [
                    Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255),
                    Color(red: 0x14/255, green: 0x18/255, blue: 0x1E/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1.0 : 0.92)
                .animation(.easeOut(duration: 0.5), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}
