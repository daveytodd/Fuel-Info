import SwiftUI
import SwiftData

@main
struct FuelInfoApp: App {
    var body: some Scene {
        WindowGroup { SplashContainerView() }
            .modelContainer(for: FuelEntry.self)
    }
}

private struct SplashContainerView: View {
    @State private var showApp = false
    @State private var pulse = false
    var body: some View {
        Group {
            if showApp { ContentView() }
            else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(systemName: "fuelpump.fill").font(.system(size: 54, weight: .medium)).foregroundStyle(Theme.green)
                            .scaleEffect(pulse ? 1.08 : 0.94).opacity(pulse ? 1 : 0.72)
                        Text("FUEL INFO").font(.system(size: 18, weight: .bold, design: .rounded)).tracking(4).foregroundStyle(.white)
                    }
                }.onAppear {
                    withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { pulse = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation(.easeInOut(duration: 0.45)) { showApp = true }
                    }
                }
            }
        }.preferredColorScheme(.dark)
    }
}
