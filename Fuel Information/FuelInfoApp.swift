import SwiftUI
import SwiftData

@main
struct FuelInfoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FuelEntry.self)
    }
}
