import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var placement: String

    @State private var plan: Plan = .yearly
    @State private var trialEnabled = true
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var legalLink: LegalLink?

    enum Plan: String, CaseIterable, Identifiable {
        case yearly, weekly
        var id: String { rawValue }
        var title: String { self == .yearly ? "Yearly" : "Weekly" }
        var price: String { self == .yearly ? "$39.99" : "$4.99" }
        var caption: String { self == .yearly ? "Just $3.33/month" : "Billed every week" }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1D1626), Color(hex: 0x3A1D2A), Color(hex: 0x0E0D12)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Circle()
                .fill(Theme.accent.opacity(0.24))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 130, y: -280)
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        hero
                        features
                        plans
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                }
            }
            VStack {
                Spacer()
                purchaseArea
            }
        }
        .sheet(item: $legalLink) { link in
            SafariView(url: link.url).ignoresSafeArea()
        }
        .alert("Restore Purchase", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .onAppear {
            if store.isPremium { dismiss() }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }
            Spacer()
            Text("HEARTICA PREMIUM")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 98, height: 98)
                Image(systemName: "crown.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
            Text("Unlock your\nfull heart story")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Unlimited measurements, complete HRV analytics and personalized guidance.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            HStack(spacing: 5) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill").font(.system(size: 10))
                }
                Text("Loved by 1M+ users")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.amber)
        }
        .padding(.top, 4)
    }

    private var features: some View {
        VStack(spacing: 10) {
            feature("infinity", "Unlimited measurements")
            feature("chart.line.uptrend.xyaxis", "Advanced analytics & chart controls")
            feature("sparkles", "Unlimited AI health insights")
            feature("square.grid.2x2", "Monthly overview & full trends")
            feature("bolt.heart.fill", "All achievements and Journey pro tasks")
        }
    }

    private func feature(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.amber)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.08))
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.amber.opacity(0.8))
        }
    }

    private var plans: some View {
        VStack(spacing: 8) {
            planCard(.yearly)
            planCard(.weekly)
        }
    }

    private func planCard(_ item: Plan) -> some View {
        Button {
            plan = item
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        if item == .yearly {
                            Text("BEST VALUE")
                                .font(.system(size: 7, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.accentDeep)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.amber)
                                .clipShape(Capsule())
                        }
                    }
                    Text(item.caption)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Text(item.price)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item == .yearly ? "/year" : "/week")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(14)
            .background(plan == item ? .white.opacity(0.14) : .white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(plan == item ? Theme.amber : .white.opacity(0.1), lineWidth: plan == item ? 1.5 : 0.8)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var trialToggle: some View {
        HStack(spacing: 10) {
            Image(systemName: trialEnabled ? "checkmark.square.fill" : "square")
                .font(.system(size: 18))
                .foregroundStyle(trialEnabled ? Theme.amber : .white.opacity(0.4))
            VStack(alignment: .leading, spacing: 1) {
                Text("Start with 3 days free")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text("Cancel anytime. No payment now.")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { trialEnabled.toggle() }
    }

    private var purchaseArea: some View {
        VStack(spacing: 10) {
            trialToggle
            Button {
                purchase()
            } label: {
                Text(trialEnabled ? "Start 3-Day Free Trial" : "Continue with Premium")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accentDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Theme.amber)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            HStack(spacing: 14) {
                Button("Restore") {
                    if store.isPremium {
                        restoreMessage = "Your Heartica Premium purchase is already active."
                    } else {
                        restoreMessage = "No previous purchases were found on this account."
                    }
                    showRestoreAlert = true
                }
                Text("·")
                Button("Terms") { legalLink = LegalLink(url: URL(string: "https://heartica.pro/tou")!) }
                Text("·")
                Button("Privacy") { legalLink = LegalLink(url: URL(string: "https://heartica.pro/pp")!) }
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [Color(hex: 0x0E0D12).opacity(0), Color(hex: 0x0E0D12)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func purchase() {
        // Demo build: no StoreKit products are attached, so the purchase is
        // completed locally to make every premium surface explorable.
        store.setPremium(true, plan: plan.title)
        router.showToast("Welcome to Heartica Premium")
        dismiss()
    }
}
