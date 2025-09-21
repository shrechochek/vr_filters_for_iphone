import SwiftUI

@main
struct test_appApp: App {
    @StateObject private var camera = CameraModel() // общий инстанс камеры

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(camera)
        }
    }
}
