import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("postOnboardingCompleted") private var postOnboardingCompleted = false
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue

    @State private var splashDone = UserDefaults.standard.bool(forKey: "skipSplash")
    @State private var didHandleLaunch = false
    @State private var showLatestMeasurement = false
    @State private var showMetricDetailSheet = false
    @State private var showRemindersSheet = false
    @State private var showAchievementsSheet = false
    @State private var showArticleSheet = false

    var body: some View {
        ZStack {
            if !splashDone {
                SplashView()
                    .transition(.opacity)
            } else if !onboardingCompleted {
                OnboardingFlow()
                    .transition(.opacity)
            } else if !postOnboardingCompleted {
                PostOnboardingFlow()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(AppAppearance(rawValue: appearanceMode)?.colorScheme)
        .fullScreenCover(isPresented: $router.showMeasure) {
            MeasureFlowView()
                .environmentObject(store)
                .environmentObject(router)
        }
        .fullScreenCover(item: $router.paywall) { request in
            PaywallView(placement: request.placement)
                .environmentObject(store)
                .environmentObject(router)
        }
        .fullScreenCover(isPresented: $router.showJourney) {
            JourneyView()
                .environmentObject(store)
                .environmentObject(router)
        }
        .fullScreenCover(isPresented: $router.showMonthly) {
            MonthlyOverviewView()
                .environmentObject(store)
                .environmentObject(router)
        }
        .sheet(isPresented: $router.showHistory) {
            NavigationStack {
                HistoryView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $router.showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $router.showAppleHealth) {
            NavigationStack {
                AppleHealthView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showRemindersSheet) {
            NavigationStack {
                RemindersView()
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showAchievementsSheet) {
            NavigationStack {
                AchievementsOverviewView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .fullScreenCover(isPresented: $showArticleSheet) {
            if let article = ArticleCatalog.allArticles.first {
                ArticleReaderView(article: article)
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showMetricDetailSheet) {
            NavigationStack {
                MetricDetailView(metric: .healthIndex)
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showLatestMeasurement) {
            NavigationStack {
                if let latest = store.latestMeasurement {
                    MeasurementDetailView(measurement: latest, isFresh: false)
                        .environmentObject(store)
                        .environmentObject(router)
                } else {
                    EmptyStateView(icon: "heart.slash", title: "No Measurement", subtitle: "Take your first measurement to see the details.")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = router.toast {
                ToastView(message: toast, icon: "checkmark.circle.fill")
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            await handleLaunch()
        }
    }

    private func handleLaunch() async {
        guard !didHandleLaunch else { return }
        didHandleLaunch = true

        if !UserDefaults.standard.bool(forKey: "skipSplash") {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
        }
        withAnimation(.easeOut(duration: 0.45)) { splashDone = true }

        let defaults = UserDefaults.standard
        if let tab = defaults.string(forKey: "initialTab"), let parsed = AppTab(rawValue: tab) {
            router.selectedTab = parsed
        }

        guard onboardingCompleted, postOnboardingCompleted else { return }
        try? await Task.sleep(nanoseconds: 450_000_000)
        if defaults.bool(forKey: "showPaywall") { router.openPaywall("in_app") }
        if defaults.bool(forKey: "showJourney") { router.showJourney = true }
        if defaults.bool(forKey: "showMonthly") { router.showMonthly = true }
        if defaults.bool(forKey: "showHistory") { router.showHistory = true }
        if defaults.bool(forKey: "showSettings") { router.showSettings = true }
        if defaults.bool(forKey: "showAppleHealth") { router.showAppleHealth = true }
        if defaults.bool(forKey: "showMeasure") { router.showMeasure = true }
        if defaults.bool(forKey: "showLatestMeasurement") { showLatestMeasurement = true }
        if defaults.bool(forKey: "showMetricDetail") { showMetricDetailSheet = true }
        if defaults.bool(forKey: "showReminders") { showRemindersSheet = true }
        if defaults.bool(forKey: "showAchievements") { showAchievementsSheet = true }
        if defaults.bool(forKey: "showArticle") { showArticleSheet = true }
    }
}

struct SplashView: View {
    @State private var appeared = false
    @State private var progress: Double = 0.12

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF8F4EE), Color(hex: 0xF3E7E2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            SoftOrbBackground(color: Theme.accent)
            VStack(spacing: 26) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.08))
                        .frame(width: 190, height: 190)
                        .scaleEffect(appeared ? 1 : 0.7)
                    Circle()
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 150, height: 150)
                        .scaleEffect(appeared ? 1 : 0.8)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 68, weight: .semibold))
                        .foregroundStyle(Theme.heartGradient)
                        .scaleEffect(appeared ? 1 : 0.6)
                        .shadow(color: Theme.accent.opacity(0.25), radius: 24, y: 12)
                }
                VStack(spacing: 10) {
                    Text("Heartica")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Know your heart. Every day.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(spacing: 14) {
                    ProgressBarView(progress: progress, color: Theme.accent, height: 4, track: Theme.accent.opacity(0.12))
                        .frame(width: 150)
                    Text("Preparing your health insights…")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.6)) { progress = 0.86 }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        Group {
            switch router.selectedTab {
            case .home:
                NavigationStack { HomeView() }
            case .dashboard:
                NavigationStack { DashboardView() }
            case .insights:
                NavigationStack { InsightsView() }
            case .me:
                NavigationStack { MeView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MainTabBar(selection: $router.selectedTab) {
                router.showMeasure = true
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}
