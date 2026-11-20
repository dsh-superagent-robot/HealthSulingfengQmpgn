import XCTest
@testable import Heartica

final class HearticaTests: XCTestCase {
    override func tearDown() {
        if let url = storeURL {
            try? FileManager.default.removeItem(at: url)
        }
        storeURL = nil
        super.tearDown()
    }

    private var storeURL: URL?

    private func makeStore(seed: Bool = false) -> AppStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("heartica-tests-\(UUID().uuidString).json")
        storeURL = url
        return AppStore(fileURL: url, seedDemoData: seed)
    }

    func testPulseThresholdsMatchSpecification() {
        XCTAssertEqual(HealthEvaluator.pulse(55).label, "Low")
        XCTAssertEqual(HealthEvaluator.pulse(72).label, "Normal")
        XCTAssertEqual(HealthEvaluator.pulse(110).label, "High")
        XCTAssertEqual(HealthEvaluator.pulse(130).label, "Very High")
    }

    func testHRVAndStressThresholds() {
        XCTAssertEqual(HealthEvaluator.hrv(40).label, "Low")
        XCTAssertEqual(HealthEvaluator.hrv(70).label, "Normal")
        XCTAssertEqual(HealthEvaluator.hrv(110).label, "High")
        XCTAssertEqual(HealthEvaluator.stress(10).label, "Relaxed")
        XCTAssertEqual(HealthEvaluator.stress(90).label, "Very High")
        XCTAssertEqual(HealthEvaluator.csi(170).label, "Elevated Stress")
    }

    func testMeasurementDerivationProducesConsistentMetrics() {
        let measurement = HealthEngine.measurement(pulse: 70, rmssd: 50, sdnn: 90)
        XCTAssertEqual(measurement.pulse, 70)
        XCTAssertEqual(measurement.healthIndex, log(50), accuracy: 0.0001)
        XCTAssertGreaterThan(measurement.energy, 0)
        XCTAssertGreaterThan(measurement.stress, 0)
        XCTAssertEqual(measurement.hrv, 90)
        XCTAssertEqual(measurement.csi, Int(clamp(8500.0 / 50.0, 20.0, 650.0).rounded()))
    }

    func testGlucoseMillimolesAreTruncatedToTenths() {
        XCTAssertEqual(GlucoseUnit.mmolRange.first, 2.7)
        XCTAssertEqual(GlucoseUnit.mmolRange.last, 13.8)
        XCTAssertEqual(GlucoseUnit.mmolRange.count, 112)
        XCTAssertEqual(floor(50.0 / 18.0 * 10.0) / 10.0, 2.7, accuracy: 0.0001)
    }

    func testCatalogSizes() {
        XCTAssertEqual(JourneyCatalog.chapters.count, 12)
        XCTAssertEqual(JourneyCatalog.allLevels.count, 100)
        XCTAssertTrue(JourneyCatalog.allLevels.allSatisfy { $0.tasks.count == 5 })
        XCTAssertEqual(ArticleCatalog.categories.count, 10)
        XCTAssertEqual(ArticleCatalog.allArticles.count, 83)
        XCTAssertEqual(AchievementCatalog.categories.count, 5)
        XCTAssertEqual(AchievementCatalog.all.count, 21)
    }

    func testStoreRoundTripPersistence() {
        let store = makeStore()
        let measurement = HealthEngine.measurement(pulse: 71, rmssd: 55)
        store.addMeasurement(measurement)
        store.addPressureLog(PressureLog(date: Date(), sys: 120, dia: 80, tagID: nil))
        store.addGlucoseLog(GlucoseLog(date: Date(), valueMgdl: 99, tagID: "eating-before"))
        store.addOxygenLog(OxygenLog(date: Date(), value: 98, tagID: nil))
        store.updateProfile(Profile(name: "Test", surname: "User", age: 30, gender: .female, weightKg: 60, heightCm: 165))

        guard let url = storeURL else { return XCTFail("missing url") }
        let reloaded = AppStore(fileURL: url)
        XCTAssertEqual(reloaded.measurements.count, 1)
        XCTAssertEqual(reloaded.pressureLogs.count, 1)
        XCTAssertEqual(reloaded.glucoseLogs.count, 1)
        XCTAssertEqual(reloaded.oxygenLogs.count, 1)
        XCTAssertEqual(reloaded.profile.name, "Test")
        XCTAssertEqual(reloaded.profile.age, 30)
    }

    func testSampleDataSeedsEveryLogType() {
        let store = makeStore(seed: true)
        XCTAssertFalse(store.measurements.isEmpty)
        XCTAssertFalse(store.pressureLogs.isEmpty)
        XCTAssertFalse(store.glucoseLogs.isEmpty)
        XCTAssertFalse(store.oxygenLogs.isEmpty)
        XCTAssertTrue(store.measurements.contains { $0.source == .appleWatch })
        XCTAssertGreaterThan(store.measurementDayCount, 5)
    }

    func testJourneyUnlocksSequentially() {
        let store = makeStore()
        let first = JourneyCatalog.allLevels[0]
        XCTAssertTrue(JourneyEngine.isUnlocked(first, store: store))
        let second = JourneyCatalog.allLevels[1]
        XCTAssertFalse(JourneyEngine.isUnlocked(second, store: store))
        for index in 0..<5 {
            store.addMeasurement(HealthEngine.measurement(pulse: 70 + index, rmssd: 50, date: Date()))
        }
        let progress = JourneyEngine.progress(for: first.coreTasks[0], store: store)
        XCTAssertEqual(progress.current, 5)
    }

    func testArticleReadingAndAchievementProgress() {
        let store = makeStore()
        let article = ArticleCatalog.allArticles[0]
        XCTAssertFalse(store.isArticleRead(article.id))
        store.markArticleRead(article.id)
        XCTAssertTrue(store.isArticleRead(article.id))
        let achievement = AchievementCatalog.achievement(id: "achv_insight_scholar")
        XCTAssertNotNil(achievement)
        XCTAssertEqual(AchievementEngine.value(for: achievement!, store: store), 1)
    }

    func testHealthStatusForPressureOxygenAndGlucose() {
        XCTAssertEqual(HealthEvaluator.pressure(sys: 115, dia: 75).label, "Normal")
        XCTAssertEqual(HealthEvaluator.pressure(sys: 150, dia: 95).label, "Very High")
        XCTAssertEqual(HealthEvaluator.oxygen(97).label, "Normal")
        XCTAssertEqual(HealthEvaluator.oxygen(88).label, "Very Low")
        XCTAssertEqual(HealthEvaluator.glucose(90).label, "Normal")
        XCTAssertEqual(HealthEvaluator.glucose(220, afterMeal: true).label, "Elevated")
    }
}
