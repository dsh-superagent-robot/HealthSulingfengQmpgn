import SwiftUI
import UIKit

private struct WatchMonthGroup: Identifiable {
    let month: Date
    let items: [HeartRateMeasurement]
    var id: Date { month }
}

struct AppleHealthView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var isSyncing = false
    @State private var lastSync: Date?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard
                if store.appleHealthConnected {
                    journal
                } else {
                    connectCard
                }
                guideCard
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
                Text("Apple Health")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Watch data and recovery sync")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.blue)
                    .frame(width: 54, height: 54)
                    .background(Theme.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Apple Health Sync")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(store.appleHealthConnected ? "Connected · Watch data available" : "Not connected")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(store.appleHealthConnected ? Theme.green : Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { store.appleHealthConnected },
                    set: { value in
                        store.setAppleHealthConnected(value)
                        if value {
                            lastSync = Date()
                            addWatchSamples(count: 2)
                        }
                    }
                ))
                .labelsHidden()
                .tint(Theme.blue)
            }
            Text("This setting only affects syncing within Heartica. Your Apple Health permissions remain unchanged.")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            if store.appleHealthConnected {
                Button {
                    sync()
                } label: {
                    HStack {
                        Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        Text(isSyncing ? "Checking for updates" : "Sync Now")
                        Spacer()
                        if let lastSync {
                            Text("Last sync: \(Fmt.time.string(from: lastSync))")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.blue)
                    .padding(.top, 2)
                }
            }
        }
        .cardSurface(padding: 16)
    }

    private var connectCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.blue)
            Text("Get 2× More Health Data")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Connect Apple Health to bring in watch measurements, HRV, workouts, mindfulness and sleep data.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                benefit("HRV", "waveform.path.ecg")
                benefit("Sleep", "moon.stars.fill")
                benefit("Activity", "figure.run")
            }
            Button {
                store.setAppleHealthConnected(true)
                lastSync = Date()
                addWatchSamples(count: 3)
                router.showToast("Apple Health connected")
            } label: {
                Text("Connect Apple Health")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .cardSurface(padding: 18)
    }

    private func benefit(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Theme.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.blue.opacity(0.1))
        .clipShape(Capsule())
    }

    private var journal: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apple Watch Data")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(watchMeasurements.count) readings")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            if watchMeasurements.isEmpty {
                EmptyStateView(icon: "applewatch", title: "No Watch Data",
                               subtitle: "Your Apple Watch measurements will appear here automatically.",
                               actionTitle: "Sync Now") { sync() }
            } else {
                ForEach(groupedMonths) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Fmt.monthTitle.string(from: group.month))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(Theme.textTertiary)
                        ForEach(group.items) { measurement in
                            watchRow(measurement)
                        }
                    }
                }
            }
        }
    }

    private var watchMeasurements: [HeartRateMeasurement] {
        store.measurements.filter { $0.source == .appleWatch }.sorted { $0.date > $1.date }
    }

    private var groupedMonths: [WatchMonthGroup] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: watchMeasurements) { cal.dateInterval(of: .month, for: $0.date)?.start ?? $0.day }
        return grouped.sorted { $0.key > $1.key }.map { WatchMonthGroup(month: $0.key, items: $0.value) }
    }

    private func watchRow(_ measurement: HeartRateMeasurement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.blue)
                .frame(width: 36, height: 36)
                .background(Theme.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(measurement.pulse) bpm")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    if let tag = store.tag(id: measurement.tagID) {
                        Text(tag.name)
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(tag.color.color)
                    }
                }
                Text("\(Fmt.dateTime.string(from: measurement.date)) · Stress \(Fmt.value(measurement.stress))%")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("HRV \(Fmt.value(measurement.hrv))")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.teal)
                Text("Health \(Fmt.value(measurement.healthIndex))")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .cardSurface(padding: 12)
    }

    private var guideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Check your Apple Health Sync")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("To ensure syncing works correctly:")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            step("1", "Open the Health app on your iPhone")
            step("2", "Tap your profile icon in the top right")
            step("3", "Go to Apps → Heartica")
            step("4", "Select Heartica and tap Turn On All")
            Button {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("Open Health App")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.blue)
                .padding(.top, 4)
            }
        }
        .cardSurface(padding: 16)
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.blue)
                .frame(width: 18, height: 18)
                .background(Theme.blue.opacity(0.1))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func sync() {
        guard !isSyncing else { return }
        isSyncing = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            addWatchSamples(count: 2)
            lastSync = Date()
            isSyncing = false
            router.showToast("2 watch measurements added")
        }
    }

    private func addWatchSamples(count: Int) {
        let now = Date()
        let tags = ["sleep-after", "activity-after", "relax-after"]
        for index in 0..<count {
            let pulse = [63, 71, 66, 69, 75][index % 5]
            var measurement = HealthEngine.measurement(
                pulse: pulse,
                rmssd: 52 + Double(index * 3),
                sdnn: 82 + Double(index * 4),
                date: now.addingTimeInterval(TimeInterval(-index * 1800)),
                tagID: tags[index % tags.count],
                source: .appleWatch,
                healthKitID: "HK-\(UUID().uuidString)"
            )
            measurement.id = UUID()
            if store.measurements.contains(where: { $0.healthKitID == measurement.healthKitID }) { continue }
            store.addMeasurement(measurement)
        }
    }
}
