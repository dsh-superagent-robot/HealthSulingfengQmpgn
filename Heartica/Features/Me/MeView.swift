import SwiftUI
import PhotosUI

struct MeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter

    @State private var period: ChartPeriod = .week
    @State private var selectedMetric: Metric?
    @State private var showAchievements = false
    @State private var showProfile = false
    @State private var showGraphSettings = false
    @State private var showMonthly = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                profileCard
                statisticsHeader
                statisticsList
                achievementsCard
                connectCard
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedMetric) { metric in
            NavigationStack {
                MetricDetailView(metric: metric)
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showAchievements) {
            NavigationStack {
                AchievementsOverviewView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showGraphSettings) {
            GraphSettingsView()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR SPACE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Theme.accent)
                Text("Me")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 9) {
                IconButton(systemName: "calendar", size: 42) {
                    router.showMonthly = true
                }
                IconButton(systemName: "gearshape.fill", size: 42) {
                    router.showSettings = true
                }
            }
        }
    }

    private var profileCard: some View {
        Button {
            showProfile = true
        } label: {
            HStack(spacing: 14) {
                AvatarView(profile: store.profile, size: 62, image: ProfileImageStore.load())
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.profile.displayName)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 6) {
                        if let age = store.profile.age {
                            Text("\(age) years")
                        }
                        if store.profile.gender != .none {
                            Text("·")
                            Text(store.profile.gender.title)
                        }
                        if let bmi = store.profile.bmi {
                            Text("·")
                            Text("BMI \(Fmt.value(bmi, decimals: 1))")
                        }
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    Text("My Profile")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var statisticsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Statistics")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    showGraphSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
            }
            HStack(spacing: 4) {
                ForEach(ChartPeriod.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { period = item }
                    } label: {
                        Text(item.shortTitle)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(period == item ? .white : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(period == item ? Theme.accent : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Theme.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack {
                Text(periodLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(statisticsMeasurements.count) measurements")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private var periodLabel: String {
        switch period {
        case .day: return "Today"
        case .week: return "This week"
        case .month: return "This month"
        case .quarter: return "Last 3 months"
        case .year: return "This year"
        }
    }

    private var statisticsMeasurements: [HeartRateMeasurement] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -period.days + 1, to: cal.startOfDay(for: Date())) ?? Date()
        return store.measurements.filter { $0.date >= start }
    }

    private var statisticsList: some View {
        VStack(spacing: 10) {
            statRow(metric: .pulse, value: average(\.pulseValue).map { "\(Int($0.rounded()))" }, status: average(\.pulseValue).map { HealthEvaluator.pulse(Int($0)) })
            statRow(metric: .hrv, value: average(\.hrv).map { Fmt.value($0) }, status: average(\.hrv).map { HealthEvaluator.hrv($0) })
            statRow(metric: .stress, value: average(\.stress).map { Fmt.value($0) }, status: average(\.stress).map { HealthEvaluator.stress($0) })
            statRow(metric: .healthIndex, value: average(\.healthIndex).map { Fmt.value($0) }, status: average(\.healthIndex).map { HealthEvaluator.healthIndex($0) })
            logStatRow(metric: .pressureSystolic, value: periodPressure, unit: "mmHg", detail: "SYS / DIA")
            logStatRow(metric: .glucoseBeforeMeal, value: periodGlucose, unit: "mg/dL", detail: "Average")
            logStatRow(metric: .oxygen, value: periodOxygen, unit: "%", detail: "Average")
        }
    }

    private func statRow(metric: Metric, value: String?, status: HealthStatus?) -> some View {
        let measurements = statisticsMeasurements
        let keyPath: KeyPath<HeartRateMeasurement, Double>
        switch metric {
        case .pulse: keyPath = \.pulseValue
        case .hrv: keyPath = \.hrv
        case .stress: keyPath = \.stress
        case .healthIndex: keyPath = \.healthIndex
        default: keyPath = \.healthIndex
        }
        let series = Statistics.dailySeries(measurements, keyPath: keyPath, days: min(period.days, 30)).map(\.value)
        return HStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(metric.color)
                .frame(width: 38, height: 38)
                .background(metric.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(periodAverageLabel)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Sparkline(values: series, color: metric.color, filled: false)
                .frame(width: 56, height: 26)
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value ?? "—")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(metric.unit)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                if let status {
                    Text(status.label)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(status.color)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        .contentShape(Rectangle())
        .onTapGesture { selectedMetric = metric }
    }

    private func logStatRow(metric: Metric, value: String?, unit: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(metric.color)
                .frame(width: 38, height: 38)
                .background(metric.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value ?? "—")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private var periodAverageLabel: String {
        switch period {
        case .day: return "Daily average"
        case .week: return "Weekly average"
        case .month: return "Monthly average"
        case .quarter: return "Quarterly average"
        case .year: return "Yearly average"
        }
    }

    private func average(_ keyPath: KeyPath<HeartRateMeasurement, Double>) -> Double? {
        let items = statisticsMeasurements
        guard !items.isEmpty else { return nil }
        return items.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(items.count)
    }

    private var cutoffDate: Date {
        Calendar.current.date(byAdding: .day, value: -period.days + 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    private var periodPressure: String? {
        let logs = store.pressureLogs.filter { $0.date >= cutoffDate }
        guard !logs.isEmpty else { return nil }
        let sys = logs.map(\.sys).reduce(0, +) / logs.count
        let dia = logs.map(\.dia).reduce(0, +) / logs.count
        return "\(sys)/\(dia)"
    }

    private var periodGlucose: String? {
        let logs = store.glucoseLogs.filter { $0.date >= cutoffDate }
        guard !logs.isEmpty else { return nil }
        return "\(Int(logs.map(\.valueMgdl).reduce(0, +) / Double(logs.count)))"
    }

    private var periodOxygen: String? {
        let logs = store.oxygenLogs.filter { $0.date >= cutoffDate }
        guard !logs.isEmpty else { return nil }
        return "\(Int(logs.map(\.value).reduce(0, +) / logs.count))"
    }

    private var achievementsCard: some View {
        let completed = AchievementEngine.completedCount(store: store)
        let total = AchievementCatalog.all.count
        return Button {
            showAchievements = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "rosette")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                            .frame(width: 32, height: 32)
                            .background(Theme.amber.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Achievements")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(completed) of \(total) unlocked")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                HStack(spacing: 8) {
                    ForEach(AchievementCatalog.categories) { category in
                        let unlocked = category.achievements.filter { AchievementEngine.value(for: $0, store: store) >= ($0.tiers.first?.rewardValue ?? 1) }.count
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(category.color)
                            Text("\(unlocked)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(category.color.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
            }
            .cardSurface(padding: 16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var connectCard: some View {
        VStack(spacing: 10) {
            Button {
                router.showAppleHealth = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.blue)
                        .frame(width: 40, height: 40)
                        .background(Theme.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health & Watch")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text(store.appleHealthConnected ? "Connected" : "Not connected")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(store.appleHealthConnected ? Theme.green : Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardSurface(padding: 14)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Profile

enum ProfileImageStore {
    static var url: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("profile_image.jpg")
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func save(_ image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return false }
        return (try? data.write(to: url, options: .atomic)) != nil
    }

    static func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var surname = ""
    @State private var age = ""
    @State private var gender: Gender = .none
    @State private var height = ""
    @State private var weight = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var avatar: UIImage?
    @State private var showPhotoOptions = false
    @State private var showRemovePhoto = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                avatarSection
                form
                Button {
                    save()
                } label: {
                    Text("Save Profile")
                }
                .buttonStyle(PrimaryButtonStyle())
                Text("This information helps us to provide a more personalized experience for you.")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: load)
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    avatar = image
                    if ProfileImageStore.save(image) {
                        var profile = store.profile
                        profile.avatarFilename = "profile_image.jpg"
                        store.updateProfile(profile)
                    }
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .confirmationDialog("Profile Photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
            Button("Choose from Library") { showPhotoPicker = true }
            if avatar != nil {
                Button("Delete a Photo", role: .destructive) {
                    avatar = nil
                    ProfileImageStore.clear()
                    var profile = store.profile
                    profile.avatarFilename = nil
                    store.updateProfile(profile)
                }
            }
            Button("Cancel", role: .cancel) {}
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
            Text("My Profile")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 10) {
            AvatarView(profile: store.profile, size: 96, image: avatar)
            Button(avatar == nil ? "Add Photo" : "Change Photo") {
                showPhotoOptions = true
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var form: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                field("Name", text: $name, placeholder: "Alex")
                field("Second Name", text: $surname, placeholder: "Morgan")
            }
            HStack(spacing: 12) {
                field("Age", text: $age, placeholder: "34", keyboard: .numberPad)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Gender")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Menu {
                        ForEach(Gender.allCases) { item in
                            Button(item.title) { gender = item }
                        }
                    } label: {
                        HStack {
                            Text(gender == .none ? "Not Set" : gender.title)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.horizontal, 13)
                        .frame(height: 48)
                        .background(Theme.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            HStack(spacing: 12) {
                field("Height (cm)", text: $height, placeholder: "168", keyboard: .decimalPad)
                field("Weight (kg)", text: $weight, placeholder: "64", keyboard: .decimalPad)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 13)
                .frame(height: 48)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func load() {
        let profile = store.profile
        name = profile.name
        surname = profile.surname
        age = profile.age.map(String.init) ?? ""
        gender = profile.gender
        height = profile.heightCm.map { Fmt.value($0, decimals: 0) } ?? ""
        weight = profile.weightKg.map { Fmt.value($0, decimals: 0) } ?? ""
        avatar = ProfileImageStore.load()
    }

    private func save() {
        var profile = store.profile
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.surname = surname.trimmingCharacters(in: .whitespaces)
        profile.gender = gender
        if let parsedAge = Int(age), parsedAge > 0, parsedAge <= 120 { profile.age = parsedAge }
        if let parsedHeight = Double(height.replacingOccurrences(of: ",", with: ".")), parsedHeight > 0, parsedHeight <= 300 {
            profile.heightCm = parsedHeight
        }
        if let parsedWeight = Double(weight.replacingOccurrences(of: ",", with: ".")), parsedWeight > 0, parsedWeight <= 500 {
            profile.weightKg = parsedWeight
        }
        if avatar != nil { profile.avatarFilename = "profile_image.jpg" }
        store.updateProfile(profile)
        dismiss()
    }
}
