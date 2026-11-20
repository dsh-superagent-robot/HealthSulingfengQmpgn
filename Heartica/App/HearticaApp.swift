import SwiftUI

@main
struct HearticaApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var router = AppRouter()

    init() {
        // Test/screenshot helper. Launch arguments override the standard
        // defaults domain, so tests cannot complete onboarding by passing
        // "-onboardingCompleted NO"; reset the persisted flags instead.
        if UserDefaults.standard.bool(forKey: "resetOnboarding") {
            UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
            UserDefaults.standard.removeObject(forKey: "postOnboardingCompleted")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
        }
    }
}
