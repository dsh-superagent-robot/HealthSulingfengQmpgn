import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("appearanceMode") private var appearance = AppAppearance.system.rawValue

    @State private var legalLink: LegalLink?
    @State private var showShare = false
    @State private var showWhatsNew = false
    @State private var showRestoreResult = false
    @State private var restoreMessage = ""
    @State private var showResetConfirm = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                if !store.isPremium { premiumBanner }
                section(title: "Notifications") {
                    Menu {
                        ForEach(AppAppearance.allCases) { mode in
                            Button {
                                appearance = mode.rawValue
                            } label: {
                                if appearance == mode.rawValue {
                                    Label(mode.title, systemImage: "checkmark")
                                } else {
                                    Text(mode.title)
                                }
                            }
                        }
                    } label: {
                        settingsRow(icon: "circle.lefthalf.filled", color: Theme.purple, title: "Appearance", value: currentAppearance.title)
                    }
                    NavigationLink {
                        RemindersView().environmentObject(store)
                    } label: {
                        settingsRow(icon: "bell.badge.fill", color: Theme.amber, title: "Manage Reminders", value: "\(store.reminders.count)")
                    }
                    NavigationLink {
                        AppleHealthView().environmentObject(store).environmentObject(router)
                    } label: {
                        settingsRow(icon: "heart.circle.fill", color: Theme.blue, title: "Apple Health", value: store.appleHealthConnected ? "Connected" : "Off")
                    }
                }
                section(title: "Legal") {
                    Button {
                        legalLink = LegalLink(url: URL(string: "https://heartica.pro/tou")!)
                    } label: {
                        settingsRow(icon: "doc.text.fill", color: Theme.teal, title: "Terms of Use", value: nil)
                    }
                    Button {
                        legalLink = LegalLink(url: URL(string: "https://heartica.pro/pp")!)
                    } label: {
                        settingsRow(icon: "hand.raised.fill", color: Theme.green, title: "Privacy Policy", value: nil)
                    }
                }
                section(title: "Support") {
                    Button {
                        restore()
                    } label: {
                        settingsRow(icon: "arrow.clockwise", color: Theme.blue, title: "Restore Purchase", value: nil)
                    }
                    Button {
                        contactSupport()
                    } label: {
                        settingsRow(icon: "envelope.fill", color: Theme.teal, title: "Contact Us", value: nil)
                    }
                    Button {
                        showShare = true
                    } label: {
                        settingsRow(icon: "square.and.arrow.up", color: Theme.orange, title: "Share App", value: nil)
                    }
                    Button {
                        rate()
                    } label: {
                        settingsRow(icon: "star.fill", color: Theme.amber, title: "Rate Us", value: nil)
                    }
                    Button {
                        showWhatsNew = true
                    } label: {
                        settingsRow(icon: "sparkles", color: Theme.purple, title: "What's New", value: nil)
                    }
                }
                section(title: "Data") {
                    Button {
                        if store.measurements.isEmpty && store.pressureLogs.isEmpty {
                            store.loadSampleData()
                            router.showToast("Sample data loaded")
                        } else {
                            router.showToast("Sample data already present")
                        }
                    } label: {
                        settingsRow(icon: "tray.and.arrow.down.fill", color: Theme.green, title: "Load Sample Data", value: nil)
                    }
                    Button {
                        showResetConfirm = true
                    } label: {
                        settingsRow(icon: "trash.fill", color: Theme.accent, title: "Reset All Data", value: nil, destructive: true)
                    }
                    settingsRow(icon: "info.circle.fill", color: Theme.textSecondary, title: "Version", value: appVersion)
                }
                Text("Heartica is a wellness application. It is not a medical device and does not diagnose, treat, or prevent any condition.")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $legalLink) { link in
            SafariView(url: link.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ["Please, share my app!", URL(string: "https://apps.apple.com/us/app/6742904990")!])
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(placement: "settings")
                .environmentObject(store)
                .environmentObject(router)
        }
        .alert("Restore Purchase", isPresented: $showRestoreResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
        .alert("Reset all data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.clearAllData()
                router.showToast("All data reset")
            }
        } message: {
            Text("This removes all measurements, logs, reminders and read articles from this device. Your profile is kept.")
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Make Heartica yours")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var premiumBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock All Features")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Try all premium features for free")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Text("Try Premium")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Theme.duskGradient)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 1) {
                content()
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        }
    }

    private func settingsRow(icon: String, color: Color, title: String, value: String?, destructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.11))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(destructive ? Theme.accent : Theme.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            if !destructive && value == nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .system
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "582"
        return "\(version) (\(build))"
    }

    private func restore() {
        if store.isPremium {
            restoreMessage = "Your Heartica Premium purchase is active on this device."
        } else {
            restoreMessage = "No previous purchases were found. You can start a free trial from the premium page."
        }
        showRestoreResult = true
    }

    private func contactSupport() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "support@heartica.pro"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Message Heartica Support Team"),
            URLQueryItem(name: "body", value: "Please do not remove the information from this message.\nApp Version: \(appVersion)\nUser ID: \(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")")
        ]
        if let url = components.url {
            openURL(url)
        }
    }

    private func rate() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        if let url = URL(string: "https://apps.apple.com/app/id6742904990?action=write-review") {
            openURL(url)
        }
    }
}

struct LegalLink: Identifiable {
    let id = UUID()
    var url: URL
}

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("What's New")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                IconButton(systemName: "xmark", size: 34) { dismiss() }
            }
            .padding(.top, 20)
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.calmGradient)
                    .frame(height: 170)
                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Better HRV measurements")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            Text("We have improved the quality of HRV measurements. Here is what it means:")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            VStack(alignment: .leading, spacing: 12) {
                whatsNewRow("1", "The old HRV values will stay the same.")
                whatsNewRow("2", "The new HRV values may slightly differ from what you usually see.")
                whatsNewRow("3", "All new heart metrics will be much more stable with new algorithms.")
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Got it!")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 22)
        .background(Theme.background.ignoresSafeArea())
    }

    private func whatsNewRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .frame(width: 22, height: 22)
                .background(Theme.accentSoft)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
