import SwiftUI

@main
struct HearticaApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
        }
    }
}
