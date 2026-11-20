import Foundation
import Combine
import UIKit

struct PersistedState: Codable {
    var profile = Profile()
    var measurements: [HeartRateMeasurement] = []
    var pressureLogs: [PressureLog] = []
    var glucoseLogs: [GlucoseLog] = []
    var oxygenLogs: [OxygenLog] = []
    var reminders: [ReminderItem] = []
    var customTags: [TagDefinition] = []
    var readArticleIDs: Set<String> = []
    var appleHealthConnected: Bool = false
    var isPremium: Bool = false
    var premiumPlan: String?
}

final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published private(set) var profile: Profile
    @Published private(set) var measurements: [HeartRateMeasurement]
    @Published private(set) var pressureLogs: [PressureLog]
    @Published private(set) var glucoseLogs: [GlucoseLog]
    @Published private(set) var oxygenLogs: [OxygenLog]
    @Published private(set) var reminders: [ReminderItem]
    @Published private(set) var customTags: [TagDefinition]
    @Published private(set) var readArticleIDs: Set<String>
    @Published private(set) var appleHealthConnected: Bool
    @Published private(set) var isPremium: Bool
    @Published private(set) var premiumPlan: String?

    private let fileURL: URL
    private let calendar = Calendar.current
    private var hasSeeded = false

    var allTags: [TagDefinition] { TagCatalog.presets + customTags }

    init(fileURL: URL? = nil, seedDemoData: Bool = false) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = support.appendingPathComponent("Heartica", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = fileURL ?? directory.appendingPathComponent("store.json")

        if UserDefaults.standard.bool(forKey: "resetData") {
            try? FileManager.default.removeItem(at: self.fileURL)
        }

        if let data = try? Data(contentsOf: self.fileURL),
           let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            profile = state.profile
            measurements = state.measurements.sorted { $0.date > $1.date }
            pressureLogs = state.pressureLogs.sorted { $0.date > $1.date }
            glucoseLogs = state.glucoseLogs.sorted { $0.date > $1.date }
            oxygenLogs = state.oxygenLogs.sorted { $0.date > $1.date }
            reminders = state.reminders
            customTags = state.customTags
            readArticleIDs = state.readArticleIDs
            appleHealthConnected = state.appleHealthConnected
            isPremium = state.isPremium
            premiumPlan = state.premiumPlan
        } else {
            let state = PersistedState()
            profile = state.profile
            measurements = []
            pressureLogs = []
            glucoseLogs = []
            oxygenLogs = []
            reminders = []
            customTags = []
            readArticleIDs = []
            appleHealthConnected = false
            isPremium = false
            premiumPlan = nil
        }

        if seedDemoData || UserDefaults.standard.bool(forKey: "seedDemo") {
            loadSampleDataIfEmpty()
        }
        if UserDefaults.standard.bool(forKey: "seedPremium") {
            isPremium = true
            premiumPlan = "Yearly"
            persist()
        }
    }

    // MARK: - Persistence

    private func snapshot() -> PersistedState {
        PersistedState(
            profile: profile,
            measurements: measurements,
            pressureLogs: pressureLogs,
            glucoseLogs: glucoseLogs,
            oxygenLogs: oxygenLogs,
            reminders: reminders,
            customTags: customTags,
            readArticleIDs: readArticleIDs,
            appleHealthConnected: appleHealthConnected,
            isPremium: isPremium,
            premiumPlan: premiumPlan
        )
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(snapshot())
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Heartica: failed to persist store — \(error)")
        }
    }

    // MARK: - Profile

    func updateProfile(_ profile: Profile) {
        self.profile = profile
        persist()
    }

    func setPremium(_ value: Bool, plan: String? = nil) {
        isPremium = value
        premiumPlan = value ? (plan ?? premiumPlan ?? "Yearly") : nil
        persist()
    }

    func setAppleHealthConnected(_ value: Bool) {
        appleHealthConnected = value
        persist()
    }

    // MARK: - Measurements

    func addMeasurement(_ measurement: HeartRateMeasurement) {
        measurements.append(measurement)
        measurements.sort { $0.date > $1.date }
        persist()
    }

    func updateMeasurement(_ measurement: HeartRateMeasurement) {
        if let index = measurements.firstIndex(where: { $0.id == measurement.id }) {
            measurements[index] = measurement
        } else {
            measurements.append(measurement)
        }
        measurements.sort { $0.date > $1.date }
        persist()
    }

    func deleteMeasurement(id: UUID) {
        measurements.removeAll { $0.id == id }
        persist()
    }

    func measurements(on day: Date) -> [HeartRateMeasurement] {
        measurements.filter { calendar.isDate($0.date, inSameDayAs: day) }.sorted { $0.date > $1.date }
    }

    var latestMeasurement: HeartRateMeasurement? {
        measurements.max(by: { $0.date < $1.date })
    }

    // MARK: - Health logs

    func addPressureLog(_ log: PressureLog) {
        pressureLogs.append(log)
        pressureLogs.sort { $0.date > $1.date }
        persist()
    }

    func updatePressureLog(_ log: PressureLog) {
        if let index = pressureLogs.firstIndex(where: { $0.id == log.id }) {
            pressureLogs[index] = log
        } else {
            pressureLogs.append(log)
        }
        pressureLogs.sort { $0.date > $1.date }
        persist()
    }

    func deletePressureLog(id: UUID) {
        pressureLogs.removeAll { $0.id == id }
        persist()
    }

    func addGlucoseLog(_ log: GlucoseLog) {
        glucoseLogs.append(log)
        glucoseLogs.sort { $0.date > $1.date }
        persist()
    }

    func updateGlucoseLog(_ log: GlucoseLog) {
        if let index = glucoseLogs.firstIndex(where: { $0.id == log.id }) {
            glucoseLogs[index] = log
        } else {
            glucoseLogs.append(log)
        }
        glucoseLogs.sort { $0.date > $1.date }
        persist()
    }

    func deleteGlucoseLog(id: UUID) {
        glucoseLogs.removeAll { $0.id == id }
        persist()
    }

    func addOxygenLog(_ log: OxygenLog) {
        oxygenLogs.append(log)
        oxygenLogs.sort { $0.date > $1.date }
        persist()
    }

    func updateOxygenLog(_ log: OxygenLog) {
        if let index = oxygenLogs.firstIndex(where: { $0.id == log.id }) {
            oxygenLogs[index] = log
        } else {
            oxygenLogs.append(log)
        }
        oxygenLogs.sort { $0.date > $1.date }
        persist()
    }

    func deleteOxygenLog(id: UUID) {
        oxygenLogs.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Tags

    func addCustomTag(_ tag: TagDefinition) {
        guard customTags.count < 20, !allTags.contains(where: { $0.name.lowercased() == tag.name.lowercased() }) else { return }
        customTags.append(tag)
        persist()
    }

    func deleteCustomTag(id: String) {
        customTags.removeAll { $0.id == id }
        persist()
    }

    func tag(id: String?) -> TagDefinition? {
        guard let id else { return nil }
        return allTags.first { $0.id == id }
    }

    // MARK: - Articles

    func markArticleRead(_ id: String) {
        readArticleIDs.insert(id)
        persist()
    }

    func isArticleRead(_ id: String) -> Bool {
        readArticleIDs.contains(id)
    }

    // MARK: - Reminders

    func upsertReminder(_ reminder: ReminderItem) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
        persist()
    }

    func deleteReminder(id: UUID) {
        reminders.removeAll { $0.id == id }
        persist()
    }

    func setReminderScheduled(id: UUID, scheduled: Bool) {
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            reminders[index].isScheduled = scheduled
            persist()
        }
    }

    // MARK: - Aggregates

    var measurementCount: Int { measurements.count }
    var measurementDayCount: Int { Set(measurements.map(\.day)).count }
    var articlesReadCount: Int { readArticleIDs.count }
    var taggedMeasurementCount: Int { measurements.filter { $0.tagID != nil }.count }
    var measurementStreak: Int { Statistics.streak(measurements.map(\.date)) }
    var activeTagCount: Int { Set(measurements.compactMap(\.tagID)).count }
    var closedPairsCount: Int { 0 }

    var todayMeasurements: [HeartRateMeasurement] {
        measurements(on: Date())
    }

    func measurementsInLast(days: Int) -> [HeartRateMeasurement] {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) else { return measurements }
        return measurements.filter { $0.date >= cutoff }
    }

    // MARK: - Sample content

    func loadSampleDataIfEmpty() {
        guard measurements.isEmpty, pressureLogs.isEmpty, glucoseLogs.isEmpty, oxygenLogs.isEmpty else { return }
        loadSampleData()
    }

    func loadSampleData() {
        var rng = HealthEngine.SeededRandom(seed: 0x51F0A3)
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let tagRotation = ["sleep-after", "stress-before", "activity-after", nil, "relax-after", "eating-before"]

        for dayOffset in stride(from: 20, through: 0, by: -1) {
            if dayOffset % 7 == 6 && dayOffset != 0 { continue }
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            let count = dayOffset == 0 ? 2 : rng.int(1, 2)
            for index in 0..<count {
                let hour = dayOffset == 0 ? (index == 0 ? 7 : 9) : rng.int(7, 21)
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = hour
                components.minute = rng.int(0, 55)
                let date = calendar.date(from: components) ?? day
                let tag = tagRotation[(dayOffset + index) % tagRotation.count]
                let baseSeed = UInt64(dayOffset * 31 + index + 1)
                var measurement = HealthEngine.randomMeasurement(seed: baseSeed, date: date, tagID: tag)
                if tag == "stress-before" || tag == "stress-during" {
                    measurement = HealthEngine.measurement(
                        pulse: min(measurement.pulse + 7, 96),
                        rmssd: max(measurement.rmssd - 10, 18),
                        date: date,
                        tagID: tag
                    )
                }
                measurements.append(measurement)
            }

            if dayOffset % 2 == 0 {
                let sys = rng.int(112, 136)
                let dia = rng.int(68, 88)
                pressureLogs.append(PressureLog(date: day.addingTimeInterval(3600 * 9), sys: sys, dia: dia, tagID: nil))
            }
            if dayOffset % 3 == 0 {
                let before = rng.int(78, 112)
                let after = rng.int(118, 168)
                glucoseLogs.append(GlucoseLog(date: day.addingTimeInterval(3600 * 8), valueMgdl: Double(before), tagID: "eating-before"))
                glucoseLogs.append(GlucoseLog(date: day.addingTimeInterval(3600 * 13), valueMgdl: Double(after), tagID: "eating-after"))
            }
            if dayOffset % 3 == 1 {
                oxygenLogs.append(OxygenLog(date: day.addingTimeInterval(3600 * 10), value: rng.int(95, 99), tagID: nil))
            }
        }

        // A few Apple Watch measurements for the journal.
        for dayOffset in [1, 3, 6] {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            let date = day.addingTimeInterval(3600 * 20)
            let pulse = [62, 68, 71][dayOffset % 3]
            let watch = HealthEngine.measurement(
                pulse: pulse,
                rmssd: 52 + Double(dayOffset),
                sdnn: 84 + Double(dayOffset),
                date: date,
                tagID: "sleep-after",
                source: .appleWatch,
                healthKitID: "HK-\(dayOffset)"
            )
            measurements.append(watch)
        }

        measurements.sort { $0.date > $1.date }
        pressureLogs.sort { $0.date > $1.date }
        glucoseLogs.sort { $0.date > $1.date }
        oxygenLogs.sort { $0.date > $1.date }

        if profile.name.isEmpty {
            profile = Profile(name: "Alex", surname: "Morgan", age: 34, gender: .female, weightKg: 64, heightCm: 168, avatarFilename: nil)
        }
        appleHealthConnected = true
        markReadArticlesForSample()
        persist()
    }

    private func markReadArticlesForSample() {
        let samples = ArticleCatalog.categories.prefix(3).flatMap { $0.articles.prefix(2) }
        for article in samples {
            readArticleIDs.insert(article.id)
        }
    }

    func clearAllData() {
        let name = profile.name
        let surname = profile.surname
        let age = profile.age
        let gender = profile.gender
        let weight = profile.weightKg
        let height = profile.heightCm
        let avatar = profile.avatarFilename
        profile = Profile(name: name, surname: surname, age: age, gender: gender, weightKg: weight, heightCm: height, avatarFilename: avatar)
        measurements = []
        pressureLogs = []
        glucoseLogs = []
        oxygenLogs = []
        reminders = []
        customTags = []
        readArticleIDs = []
        appleHealthConnected = false
        isPremium = false
        premiumPlan = nil
        persist()
    }

    func clearSampleContent() {
        measurements = []
        pressureLogs = []
        glucoseLogs = []
        oxygenLogs = []
        readArticleIDs = []
        appleHealthConnected = false
        persist()
    }
}
