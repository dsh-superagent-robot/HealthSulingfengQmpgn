import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    @State private var page = 0
    @State private var phase: Phase = .intro
    @State private var form = Profile()
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var permissions = PermissionsState()

    enum Phase { case intro, paywall, profile, permissions }

    private let pages: [OnboardingPage] = OnboardingPage.all

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            SoftOrbBackground(color: pageColor)
            Group {
                switch phase {
                case .intro: intro
                case .paywall: paywall
                case .profile: profile
                case .permissions: permissionsView
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                     removal: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    private var pageColor: Color {
        Theme.primaryColor(for: page)
    }

    // MARK: Intro

    private var intro: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.heartGradient)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Heartica")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Text("\(page + 1) / \(pages.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(page: item, index: index)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.accent : Theme.separator)
                        .frame(width: index == page ? 24 : 7, height: 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
                }
            }
            .padding(.bottom, 18)

            VStack(spacing: 12) {
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        phase = .paywall
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Personalize My Journey")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("By proceeding, you accept our Terms of Use and Privacy Policy")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: Paywall

    private var paywall: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    phase = .profile
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                Spacer()
                Text("Heartica Premium")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(Theme.duskGradient)
                            .frame(height: 210)
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(Theme.amber)
                            Text("Unlock your full heart story")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text("Unlimited measurements, advanced analytics and personalized insights.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.78))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 14) {
                        PremiumFeatureRow(icon: "infinity", title: "Unlimited measurements", subtitle: "No daily limits, ever")
                        PremiumFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced analytics", subtitle: "Full trends and chart controls")
                        PremiumFeatureRow(icon: "sparkles", title: "AI health insights", subtitle: "Clear guidance for your numbers")
                        PremiumFeatureRow(icon: "square.grid.2x2", title: "Monthly overview", subtitle: "Every metric, every day")
                    }

                    VStack(spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$39.99").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(Theme.textPrimary)
                            Text("/ year").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(Theme.textSecondary)
                        }
                        Text("3 days free, then $39.99/year. Cancel anytime.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }

            VStack(spacing: 10) {
                Button {
                    store.setPremium(true, plan: "Yearly")
                    phase = .profile
                } label: {
                    Text("Start 3-Day Free Trial")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    phase = .profile
                } label: {
                    Text("Continue with Free Plan")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: Profile

    private var profile: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    phase = .paywall
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                Spacer()
                Button("Skip") {
                    finishProfile()
                    phase = .permissions
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Let's Personalize\nYour Journey")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Help us understand you better before you begin. You can change this anytime in your profile.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            OnboardingField(title: "First name", text: $form.name, placeholder: "Alex")
                            OnboardingField(title: "Last name", text: $form.surname, placeholder: "Morgan")
                        }
                        HStack(spacing: 12) {
                            OnboardingField(title: "Age", text: $ageText, placeholder: "34", keyboard: .numberPad)
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Gender")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                                Menu {
                                    ForEach(Gender.allCases) { gender in
                                        Button(gender.title) { form.gender = gender }
                                    }
                                } label: {
                                    HStack {
                                        Text(form.gender == .none ? "Not Set" : form.gender.title)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(Theme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(Theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            OnboardingField(title: "Height (cm)", text: $heightText, placeholder: "168", keyboard: .decimalPad)
                            OnboardingField(title: "Weight (kg)", text: $weightText, placeholder: "64", keyboard: .decimalPad)
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(Theme.teal)
                        Text("Your health data stays on your device and is never sold.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(14)
                    .background(Theme.teal.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
            }

            Button {
                finishProfile()
                phase = .permissions
            } label: {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            if ageText.isEmpty, let age = form.age { ageText = "\(age)" }
            if heightText.isEmpty, let height = form.heightCm { heightText = Fmt.value(height, decimals: 0) }
            if weightText.isEmpty, let weight = form.weightKg { weightText = Fmt.value(weight, decimals: 0) }
        }
    }

    private func finishProfile() {
        form.name = form.name.trimmingCharacters(in: .whitespaces)
        form.surname = form.surname.trimmingCharacters(in: .whitespaces)
        if let age = Int(ageText), age > 0, age <= 120 { form.age = age } else { form.age = nil }
        if let height = Double(heightText.replacingOccurrences(of: ",", with: ".")), height > 0, height <= 300 {
            form.heightCm = height
        } else {
            form.heightCm = nil
        }
        if let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")), weight > 0, weight <= 500 {
            form.weightKg = weight
        } else {
            form.weightKg = nil
        }
        store.updateProfile(form)
    }

    // MARK: Permissions

    private var permissionsView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Theme.calmGradient)
                            .frame(height: 170)
                        VStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("You're in control")
                                .font(.system(size: 21, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Enable only what you need. Your choices can change anytime.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }

                    VStack(spacing: 12) {
                        PermissionCard(icon: "camera.fill", color: Theme.accent,
                                       title: "Camera", subtitle: "Measure your pulse with the camera and flash.",
                                       isOn: $permissions.camera)
                        PermissionCard(icon: "bell.badge.fill", color: Theme.amber,
                                       title: "Notifications", subtitle: "Gentle reminders for your daily check-ins.",
                                       isOn: $permissions.notifications)
                        PermissionCard(icon: "heart.circle.fill", color: Theme.blue,
                                       title: "Apple Health", subtitle: "Bring in watch measurements and recovery data.",
                                       isOn: $permissions.health)
                    }

                    Text("Permissions are requested only when you use each feature. Heartica does not access your photos.")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Button {
                completeOnboarding()
            } label: {
                Text("Get Started")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func completeOnboarding() {
        if permissions.notifications {
            Task {
                _ = await NotificationManager.shared.requestAuthorization()
            }
        }
        if permissions.health {
            store.setAppleHealthConnected(true)
        }
        withAnimation { onboardingCompleted = true }
    }
}

// MARK: - Supporting views

private struct PermissionsState {
    var camera = true
    var notifications = true
    var health = true
}

private struct OnboardingPage: Identifiable {
    let id: Int
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String
    let chips: [String]
    let gradient: LinearGradient

    static let all: [OnboardingPage] = [
        OnboardingPage(id: 0, eyebrow: "Welcome", title: "Check your **Heart Rate** whenever you need",
                       subtitle: "Track your heart health — fast, simple and reliable.",
                       symbol: "heart.fill", chips: ["Camera-based", "Private", "No wearable needed"],
                       gradient: Theme.heartGradient),
        OnboardingPage(id: 1, eyebrow: "Pulse", title: "Reveal your **Heart Health** in seconds",
                       subtitle: "Get instant insights into your heart rate, stress and overall health.",
                       symbol: "waveform.path.ecg", chips: ["HRV", "Stress", "Health Index"],
                       gradient: Theme.calmGradient),
        OnboardingPage(id: 2, eyebrow: "Log", title: "Log **Blood Pressure** and **Glucose Level**",
                       subtitle: "Keep all your vital stats together in one convenient app.",
                       symbol: "drop.fill", chips: ["Pressure", "Glucose", "Oxygen"],
                       gradient: Theme.duskGradient),
        OnboardingPage(id: 3, eyebrow: "Stress", title: "Reduce **Stress Level** with weekly insights",
                       subtitle: "Analyze your patterns and learn how to lower stress.",
                       symbol: "brain.head.profile", chips: ["7-day CSI", "Recovery", "Trends"],
                       gradient: Theme.goldGradient),
        OnboardingPage(id: 4, eyebrow: "Monitor", title: "Monitor **Health Metrics** daily with ease",
                       subtitle: "Use advanced technology for a healthy, active life.",
                       symbol: "chart.xyaxis.line", chips: ["Charts", "Journey", "Achievements"],
                       gradient: Theme.heartGradient)
    ]
}

private struct OnboardingPageView: View {
    var page: OnboardingPage
    var index: Int
    @State private var animate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 10)
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(page.gradient)
                    .frame(height: 330)
                    .shadow(color: Theme.primaryColor(for: index).opacity(0.25), radius: 26, y: 16)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .frame(height: 330)
                ForEach(0..<3) { ring in
                    Circle()
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 170 + CGFloat(ring) * 62, height: 170 + CGFloat(ring) * 62)
                }
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 118, height: 118)
                Image(systemName: page.symbol)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1.03 : 0.96)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animate)
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(page.chips, id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.18))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 26)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(page.eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Theme.accent)
                Text(.init(page.title))
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if index == 0 {
                    HStack(spacing: 6) {
                        HStack(spacing: 1) {
                            ForEach(0..<5) { _ in Image(systemName: "star.fill").font(.system(size: 9)) }
                        }
                        .foregroundStyle(Theme.amber)
                        Text("Trusted by millions of users worldwide")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 10)
        }
        .onAppear { animate = true }
    }

}

private struct OnboardingField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct PremiumFeatureRow: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 42, height: 42)
                .background(Theme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }
}

private struct PermissionCard: View {
    var icon: String
    var color: Color
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }
}
