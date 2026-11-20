import Foundation
import SwiftUI

enum JourneyTaskType: String, Codable, CaseIterable, Identifiable {
    case core, optional, pro
    var id: String { rawValue }
    var title: String {
        switch self {
        case .core: return "Main"
        case .optional: return "Optional"
        case .pro: return "Pro"
        }
    }
}

enum JourneyCategory: String, Codable, CaseIterable, Identifiable {
    case anyMeasuresVol
    case anyMeasuresDays
    case consistency7
    case consistency30
    case anyRestVol
    case sleepAfter
    case sleepBefore
    case sleepPairs
    case exerciseBefore
    case exerciseAfter
    case exercisePairs
    case stressBefore
    case stressDuring
    case stressAfter
    case stressPairs
    case meditateBefore
    case meditateAfter
    case meditationPairs
    case anyPairs
    case anyActivityVol
    case allTagsVol
    case allTagGroups
    case allTagsSets
    case readArticle
    case appleHealth
    case fullSpectrum
    case aiCommentsVol

    var id: String { rawValue }

    func title(target: Int, referenceTitle: String? = nil) -> String {
        switch self {
        case .anyMeasuresVol: return "Make \(target) Heart Rate Measures"
        case .anyMeasuresDays: return "Measure Your Heart Rate for \(target) Days"
        case .consistency7: return "7-Day Consistency: Log Measurements on \(target) of Last 7 Days"
        case .consistency30: return "30-Day Consistency: Log Measurements on \(target) of Last 30 Days"
        case .anyRestVol: return "Make \(target) REST Measurements"
        case .sleepAfter: return "Make \(target) After Sleep Measurements"
        case .sleepBefore: return "Make \(target) Before Sleep Measurements"
        case .sleepPairs: return "Night Cycle Series: Record \(target) Sleep Pairs"
        case .exerciseBefore: return "Make \(target) Before Exercise Measurements"
        case .exerciseAfter: return "Make \(target) After Exercise Measurements"
        case .exercisePairs: return "Workout Reaction Protocol: Complete \(target) Exercise Pairs"
        case .stressBefore: return "Make \(target) Before Stress Measurements"
        case .stressDuring: return "Make \(target) During Stress Measurements"
        case .stressAfter: return "Make \(target) After Stress Measurements"
        case .stressPairs: return "Resilience Loop: Complete \(target) Stress Pairs"
        case .meditateBefore: return "Make \(target) Before Meditation Measurements"
        case .meditateAfter: return "Make \(target) After Meditation Measurements"
        case .meditationPairs: return "Meditation Lab: Finish \(target) Meditation Pairs"
        case .anyPairs: return "Do \(target) Before & After Pairs"
        case .anyActivityVol: return "Make \(target) Activity Measures"
        case .allTagsVol: return "Make \(target) Any Tagged Measurements"
        case .allTagGroups: return "Make Measures for All 4 Tag Clusters"
        case .allTagsSets: return "Context Atlas: Use All 11 Tags at least \(target) Each"
        case .readArticle: return "Read the Article: \(referenceTitle ?? "Library Pick")"
        case .appleHealth: return "Connect Apple Health"
        case .fullSpectrum: return "Full Spectrum: Collect \(target) Pairs in Each Cluster"
        case .aiCommentsVol: return "Read \(target) AI Comments"
        }
    }

    var cta: String {
        switch self {
        case .readArticle: return "Read Article"
        case .appleHealth: return "Go to Settings"
        default: return "Take Measurement"
        }
    }

    var icon: String {
        switch self {
        case .readArticle: return "book.fill"
        case .appleHealth: return "heart.circle.fill"
        case .sleepBefore, .sleepAfter, .sleepPairs: return "moon.stars.fill"
        case .exerciseBefore, .exerciseAfter, .exercisePairs: return "figure.run"
        case .stressBefore, .stressDuring, .stressAfter, .stressPairs: return "brain.head.profile"
        case .meditateBefore, .meditateAfter, .meditationPairs: return "leaf.fill"
        case .allTagsSets, .allTagsVol, .allTagGroups: return "tag.fill"
        default: return "heart.fill"
        }
    }
}

struct JourneyTask: Identifiable, Hashable {
    var id: String
    var type: JourneyTaskType
    var category: JourneyCategory
    var targetValue: Int
    var referenceID: String?
    var title: String
    var cta: String { category.cta }

    var isPro: Bool { type == .pro }
}

struct JourneyLevel: Identifiable, Hashable {
    var id: String
    var number: Int
    var chapterID: String
    var title: String
    var description: String
    var tasks: [JourneyTask]
    var coreTasks: [JourneyTask] { tasks.filter { $0.type == .core } }
    var optionalTasks: [JourneyTask] { tasks.filter { $0.type == .optional } }
    var proTasks: [JourneyTask] { tasks.filter { $0.type == .pro } }
}

struct JourneyChapter: Identifiable, Hashable {
    var id: String
    var number: Int
    var title: String
    var description: String
    var levels: [JourneyLevel]
    var colorHex: UInt
    var icon: String
    var color: Color { Color(hex: colorHex) }

    var firstLevelNumber: Int { levels.first?.number ?? 1 }
    var lastLevelNumber: Int { levels.last?.number ?? 1 }
}

enum JourneyCatalog {
    static let chapters: [JourneyChapter] = build()

    static var allLevels: [JourneyLevel] { chapters.flatMap(\.levels) }

    static func chapter(containing level: JourneyLevel) -> JourneyChapter? {
        chapters.first { $0.id == level.chapterID }
    }

    private struct ChapterSeed {
        let title: String
        let description: String
        let levelCount: Int
        let color: UInt
        let icon: String
        let chaptersTasks: [JourneyCategory]
    }

    private static let seeds: [ChapterSeed] = [
        ChapterSeed(title: "Onboarding & First Wins", description: "Build the habit with a few easy measurements.", levelCount: 3, color: 0xE4515A, icon: "flag.fill",
                    chaptersTasks: [.anyMeasuresVol, .readArticle, .sleepAfter]),
        ChapterSeed(title: "Building a Good Habit", description: "Turn a first win into a repeatable routine.", levelCount: 5, color: 0xE0A03A, icon: "calendar.badge.clock",
                    chaptersTasks: [.anyMeasuresDays, .consistency7, .readArticle]),
        ChapterSeed(title: "Your Health Baseline", description: "Collect enough signal to see your personal normal.", levelCount: 6, color: 0x2F9C8E, icon: "chart.line.uptrend.xyaxis",
                    chaptersTasks: [.anyRestVol, .anyMeasuresDays, .allTagsVol]),
        ChapterSeed(title: "Sleep Routine & Recovery", description: "Pair readings around sleep to learn what restores you.", levelCount: 5, color: 0x527FE5, icon: "moon.stars.fill",
                    chaptersTasks: [.sleepBefore, .sleepAfter, .sleepPairs]),
        ChapterSeed(title: "Mindfulness & Control", description: "Use short pauses to understand your baseline.", levelCount: 10, color: 0x4D9C5C, icon: "leaf.fill",
                    chaptersTasks: [.meditateBefore, .meditateAfter, .meditationPairs]),
        ChapterSeed(title: "Activity & Load", description: "See how exercise moves your heart and recovery.", levelCount: 10, color: 0xE07B3F, icon: "figure.run",
                    chaptersTasks: [.exerciseBefore, .exerciseAfter, .exercisePairs]),
        ChapterSeed(title: "Stress & Resilience", description: "Map how tension enters and leaves your body.", levelCount: 10, color: 0xCB3C44, icon: "brain.head.profile",
                    chaptersTasks: [.stressBefore, .stressDuring, .stressAfter]),
        ChapterSeed(title: "Trends & Deep Observation", description: "Read the long curve instead of a single dot.", levelCount: 10, color: 0x8B6BD9, icon: "chart.xyaxis.line",
                    chaptersTasks: [.consistency30, .anyMeasuresDays, .allTagsVol]),
        ChapterSeed(title: "Exploring Multiple Contexts", description: "Use every tag and discover your patterns.", levelCount: 10, color: 0xD95C9A, icon: "square.grid.2x2.fill",
                    chaptersTasks: [.allTagGroups, .allTagsSets, .anyPairs]),
        ChapterSeed(title: "Full Spectrum & Weekly Systems", description: "Build a complete weekly view of your health.", levelCount: 10, color: 0x527FE5, icon: "circle.hexagongrid.fill",
                    chaptersTasks: [.fullSpectrum, .anyActivityVol, .readArticle]),
        ChapterSeed(title: "Long Horizon & Master Collector", description: "Consistency compounds. Keep the horizon long.", levelCount: 10, color: 0xE0A03A, icon: "hourglass",
                    chaptersTasks: [.consistency30, .anyMeasuresDays, .allTagsSets]),
        ChapterSeed(title: "Longevity Journey", description: "The final stretch — a sustainable, personal practice.", levelCount: 11, color: 0x2F9C8E, icon: "infinity",
                    chaptersTasks: [.fullSpectrum, .anyMeasuresVol, .readArticle])
    ]

    private static let levelTitles: [String] = [
        "Easy Start", "Second Day", "Context is the Key", "Building Consistency", "A Calmer Baseline",
        "First Pair", "Reading the Trend", "Steady Rhythm", "Morning Check", "Evening Reset",
        "Load and Recover", "The Long View", "Tag Explorer", "Stress Signals", "Breath and Pulse",
        "Weekly Review", "Deep Observation", "Pattern Finder", "Rest Protocol", "Full Spectrum",
        "Master Practice"
    ]

    private static func articleReference(for index: Int) -> Article {
        let all = ArticleCatalog.allArticles
        return all[index % all.count]
    }

    private static func tasks(for levelNumber: Int, chapter: ChapterSeed, chapterIndex: Int, indexInChapter: Int) -> [JourneyTask] {
        let base = 2 + levelNumber / 4
        let category = chapter.chaptersTasks[indexInChapter % chapter.chaptersTasks.count]
        let readRef = articleReference(for: levelNumber)
        var tasks: [JourneyTask] = []

        for taskIndex in 0..<3 {
            let taskCategory: JourneyCategory
            switch taskIndex {
            case 0:
                taskCategory = category
            case 1:
                taskCategory = chapter.chaptersTasks[(indexInChapter + 1) % chapter.chaptersTasks.count]
            default:
                taskCategory = .readArticle
            }
            let target = taskCategory == .readArticle ? 1 : max(1, base - taskIndex)
            let reference = taskCategory == .readArticle ? readRef.id : nil
            tasks.append(JourneyTask(
                id: "L\(String(format: "%02d", levelNumber))_\(taskIndex + 1)",
                type: .core,
                category: taskCategory,
                targetValue: target,
                referenceID: reference,
                title: taskCategory.title(target: target, referenceTitle: readRef.title)
            ))
        }

        let optionalCategory: JourneyCategory = levelNumber == 1 ? .appleHealth : (indexInChapter % 2 == 0 ? .allTagsVol : .anyActivityVol)
        let optionalTarget = optionalCategory == .appleHealth ? 1 : max(1, base)
        tasks.append(JourneyTask(
            id: "L\(String(format: "%02d", levelNumber))_4",
            type: .optional,
            category: optionalCategory,
            targetValue: optionalTarget,
            referenceID: nil,
            title: optionalCategory.title(target: optionalTarget)
        ))

        let proCategory: JourneyCategory = (chapterIndex + levelNumber) % 3 == 0 ? .anyPairs : .fullSpectrum
        let proTarget = max(1, levelNumber / 10 + 1)
        tasks.append(JourneyTask(
            id: "L\(String(format: "%02d", levelNumber))_5",
            type: .pro,
            category: proCategory,
            targetValue: proTarget,
            referenceID: nil,
            title: proCategory.title(target: proTarget)
        ))
        return tasks
    }

    private static func build() -> [JourneyChapter] {
        var levelNumber = 1
        return seeds.enumerated().map { chapterIndex, seed in
            var levels: [JourneyLevel] = []
            for indexInChapter in 0..<seed.levelCount {
                let title = levelTitles[(levelNumber - 1) % levelTitles.count]
                let level = JourneyLevel(
                    id: String(format: "L%02d", levelNumber),
                    number: levelNumber,
                    chapterID: String(format: "CH%02d", chapterIndex + 1),
                    title: title,
                    description: "Level \(levelNumber) — \(seed.title). Keep the streak alive and complete your main tasks to unlock the next level.",
                    tasks: tasks(for: levelNumber, chapter: seed, chapterIndex: chapterIndex, indexInChapter: indexInChapter)
                )
                levels.append(level)
                levelNumber += 1
            }
            return JourneyChapter(
                id: String(format: "CH%02d", chapterIndex + 1),
                number: chapterIndex + 1,
                title: seed.title,
                description: seed.description,
                levels: levels,
                colorHex: seed.color,
                icon: seed.icon
            )
        }
    }
}

struct JourneyTaskProgress {
    var current: Int
    var target: Int
    var isComplete: Bool { current >= target }
    var fraction: Double { target == 0 ? 1 : min(Double(current) / Double(target), 1) }
}

enum JourneyEngine {
    static func progress(for task: JourneyTask, store: AppStore) -> JourneyTaskProgress {
        let measurements = store.measurements
        let current: Int
        switch task.category {
        case .anyMeasuresVol:
            current = measurements.count
        case .anyMeasuresDays:
            current = store.measurementDayCount
        case .consistency7:
            current = daysWithMeasurements(measurements, last: 7)
        case .consistency30:
            current = daysWithMeasurements(measurements, last: 30)
        case .anyRestVol:
            current = measurements.filter { tagContext($0.tagID) == "rest" }.count
        case .sleepBefore:
            current = measurements.filter { $0.tagID == "sleep-before" }.count
        case .sleepAfter:
            current = measurements.filter { $0.tagID == "sleep-after" }.count
        case .sleepPairs:
            current = pairs(in: measurements, before: "sleep-before", after: "sleep-after", window: 12 * 3600)
        case .exerciseBefore:
            current = measurements.filter { $0.tagID == "activity-before" }.count
        case .exerciseAfter:
            current = measurements.filter { $0.tagID == "activity-after" }.count
        case .exercisePairs:
            current = pairs(in: measurements, before: "activity-before", after: "activity-after", window: 3 * 3600)
        case .stressBefore:
            current = measurements.filter { $0.tagID == "stress-before" }.count
        case .stressDuring:
            current = measurements.filter { $0.tagID == "stress-during" }.count
        case .stressAfter:
            current = measurements.filter { $0.tagID == "stress-after" }.count
        case .stressPairs:
            current = pairs(in: measurements, before: "stress-before", after: "stress-after", window: 3 * 3600)
        case .meditateBefore:
            current = measurements.filter { $0.tagID == "relax-before" }.count
        case .meditateAfter:
            current = measurements.filter { $0.tagID == "relax-after" }.count
        case .meditationPairs:
            current = pairs(in: measurements, before: "relax-before", after: "relax-after", window: 3 * 3600)
        case .anyPairs:
            current = pairs(in: measurements, before: nil, after: nil, window: 3 * 3600)
        case .anyActivityVol:
            current = measurements.filter { tagContext($0.tagID) == "activity" }.count
        case .allTagsVol:
            current = measurements.filter { $0.tagID != nil }.count
        case .allTagGroups:
            current = Set(measurements.compactMap { store.tag(id: $0.tagID)?.cluster }).intersection(TagCatalog.allClusters).count
        case .allTagsSets:
            let counts = TagCatalog.presets.map { preset in measurements.filter { $0.tagID == preset.id }.count }
            current = counts.min() ?? 0
        case .readArticle:
            current = task.referenceID.map { store.isArticleRead($0) ? 1 : 0 } ?? 0
        case .appleHealth:
            current = store.appleHealthConnected ? 1 : 0
        case .fullSpectrum:
            current = 0
        case .aiCommentsVol:
            current = 0
        }
        return JourneyTaskProgress(current: current, target: task.targetValue)
    }

    static func isComplete(_ level: JourneyLevel, store: AppStore) -> Bool {
        level.coreTasks.allSatisfy { progress(for: $0, store: store).isComplete }
    }

    static func isUnlocked(_ level: JourneyLevel, store: AppStore) -> Bool {
        guard level.number > 1 else { return true }
        guard let previous = JourneyCatalog.allLevels.first(where: { $0.number == level.number - 1 }) else { return true }
        return isUnlocked(previous, store: store) && isComplete(previous, store: store)
    }

    /// A level only counts once it is actually reachable. Locked levels can have
    /// their tasks satisfied by historical data, but they must not inflate the
    /// chapter or journey progress.
    static func isEffectiveComplete(_ level: JourneyLevel, store: AppStore) -> Bool {
        isUnlocked(level, store: store) && isComplete(level, store: store)
    }

    static func completedCoreCount(_ level: JourneyLevel, store: AppStore) -> Int {
        level.coreTasks.filter { progress(for: $0, store: store).isComplete }.count
    }

    static func chapterCompleted(_ chapter: JourneyChapter, store: AppStore) -> Bool {
        chapter.levels.allSatisfy { isEffectiveComplete($0, store: store) }
    }

    static func chapterActive(_ chapter: JourneyChapter, store: AppStore) -> Bool {
        chapter.levels.contains { isUnlocked($0, store: store) && !isComplete($0, store: store) }
    }

    static func currentLevel(store: AppStore) -> JourneyLevel? {
        JourneyCatalog.allLevels.first { isUnlocked($0, store: store) && !isComplete($0, store: store) }
    }

    private static func tagContext(_ id: String?) -> String? {
        guard let id else { return nil }
        if id.hasPrefix("sleep") || id.hasPrefix("relax") { return "rest" }
        if id.hasPrefix("activity") || id.hasPrefix("stress") { return "activity" }
        if id.hasPrefix("eating") { return "food" }
        return nil
    }

    private static func daysWithMeasurements(_ measurements: [HeartRateMeasurement], last days: Int) -> Int {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -days + 1, to: cal.startOfDay(for: Date())) else { return 0 }
        return Set(measurements.filter { $0.date >= start }.map(\.day)).count
    }

    private static func pairs(in measurements: [HeartRateMeasurement], before: String?, after: String?, window: TimeInterval) -> Int {
        let sorted = measurements.sorted { $0.date < $1.date }
        var count = 0
        var used = Set<UUID>()
        for (index, item) in sorted.enumerated() {
            let isBefore = before == nil ? item.tagID?.hasSuffix("-before") == true : item.tagID == before
            guard isBefore, !used.contains(item.id) else { continue }
            for candidate in sorted[(index + 1)...] {
                let isAfter = after == nil ? candidate.tagID?.hasSuffix("-after") == true : candidate.tagID == after
                if isAfter && candidate.date.timeIntervalSince(item.date) <= window {
                    count += 1
                    used.insert(item.id)
                    used.insert(candidate.id)
                    break
                }
                if candidate.date.timeIntervalSince(item.date) > window { break }
            }
        }
        return count
    }
}
