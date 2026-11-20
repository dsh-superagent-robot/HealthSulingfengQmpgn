import SwiftUI
import Combine

struct PaywallRequest: Identifiable, Equatable {
    let id = UUID()
    var placement: String
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var showMeasure = false
    @Published var paywall: PaywallRequest?
    @Published var showJourney = false
    @Published var showMonthly = false
    @Published var showAppleHealth = false
    @Published var toast: String?
    @Published var showHistory = false
    @Published var showSettings = false
    private var toastTask: Task<Void, Never>?

    func openPaywall(_ placement: String) {
        paywall = PaywallRequest(placement: placement)
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            toast = message
        }
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }

    func openHistory(store: AppStore) {
        showHistory = true
    }
}
