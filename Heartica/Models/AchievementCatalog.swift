import Foundation
import SwiftUI

enum AchievementShape: String, CaseIterable {
    case circle, hexagon, rhombus, square, capsule, shield
    var symbol: String {
        switch self {
        case .circle: return "circle.fill"
        case .hexagon: return "hexagon.fill"
        case .rhombus: return "diamond.fill"
        case .square: return "square.fill"
        case .capsule: return "capsule.fill"
        case .shield: return "shield.fill"
        }
    }
}

enum AchievementRibbon: String {
    case blue, red, purple
    var color: Color {
        switch self {
        case .blue: return Theme.blue
        case .red: return Theme.accent
        case .purple: return Theme.purple
        }
    }
}

enum AchievementMetric: String {
    case measurements, days, daysStreak, weeks, pairsClosed, articles, aiComments, streak30days, streak90days, allTagsSets, setup
    var format: String {
        switch self {
        case .measurements: return "%@ measurements"
        case .days: return "%@ days"
        case .daysStreak: return "%@ days streak"
        case .weeks: return "%@ weeks"
        case .pairsClosed: return "%@ pairs closed"
        case .articles: return "%@ articles"
        case .aiComments: return "%@ AI comments"
        case .streak30days: return "%@ / 30 days"
        case .streak90days: return "%@ / 90 days"
        case .allTagsSets: return "%@ all-tags set"
        case .setup: return "%@ connected"
        }
    }
}

struct AchievementCategory: Identifiable, Hashable {
    var id: String
    var title: String
    var icon: String
    var colorHex: UInt
    var color: Color { Color(hex: colorHex) }
    var achievements: [Achievement]
}

struct AchievementTier: Identifiable, Hashable {
    var id: Int
    var rewardValue: Int
    var ribbon: AchievementRibbon?
}

struct Achievement: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var description: String
    var shape: AchievementShape
    var categoryID: String
    var metric: AchievementMetric
    var tiers: [AchievementTier]
    var rewardTitle: String

    var finalTarget: Int { tiers.last?.rewardValue ?? 1 }
}

enum AchievementCatalog {
    static let categories: [AchievementCategory] = build()
    static var all: [Achievement] { categories.flatMap(\.achievements) }

    static func achievement(id: String) -> Achievement? {
        all.first { $0.id == id }
    }

    private static func tierList(_ values: [Int], ribbonsAt: [(Int, AchievementRibbon)] = []) -> [AchievementTier] {
        values.enumerated().map { index, value in
            AchievementTier(
                id: index,
                rewardValue: value,
                ribbon: ribbonsAt.first(where: { $0.0 == index })?.1
            )
        }
    }

    private static let standardRibbons: [(Int, AchievementRibbon)] = [(5, .blue), (8, .red), (11, .purple)]

    private static func build() -> [AchievementCategory] {
        let daily = AchievementCategory(
            id: "daily_rhythm",
            title: "Daily Rhythm",
            icon: "sun.max.fill",
            colorHex: 0xE4515A,
            achievements: [
                Achievement(id: "achv_measure_volume", title: "Total Measurements", subtitle: "Your total number of measurements", description: "Every measurement adds a data point to your personal baseline. Keep going to build a fuller picture of your heart health.", shape: .hexagon, categoryID: "daily_rhythm", metric: .measurements, tiers: tierList([10, 20, 30, 45, 60, 75, 100, 150, 200, 300, 400, 500, 750, 1000, 1500], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Pulse Collector %@"),
                Achievement(id: "achv_days_active", title: "Days Active", subtitle: "Days with at least one measurement", description: "Showing up on more days is the simplest way to make your trends meaningful.", shape: .circle, categoryID: "daily_rhythm", metric: .days, tiers: tierList([3, 7, 14, 30, 50, 75, 100, 150, 200, 250, 300, 350, 400, 450, 500], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Daily Explorer %@"),
                Achievement(id: "achv_consistency_window", title: "Daily Consistency", subtitle: "Measure on consecutive days", description: "Consistency is what turns isolated readings into a trend you can trust.", shape: .square, categoryID: "daily_rhythm", metric: .daysStreak, tiers: tierList([3, 5, 10, 15, 20, 30, 60, 90, 120, 180, 270, 365], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Steady Heart %@"),
                Achievement(id: "achv_morning_check", title: "Morning Check", subtitle: "Start the day with a measurement", description: "A morning reading gives you a clean baseline before the day gets busy.", shape: .rhombus, categoryID: "daily_rhythm", metric: .daysStreak, tiers: tierList([2, 3, 7, 14, 21, 30, 45, 60, 90, 120, 150, 180], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Sunrise Pulse %@")
            ]
        )

        let sleep = AchievementCategory(
            id: "sleep_night_routine",
            title: "Sleep & Night Routine",
            icon: "moon.stars.fill",
            colorHex: 0x527FE5,
            achievements: [
                Achievement(id: "achv_sleep_control", title: "Sleep Control", subtitle: "Measure before sleep consistently", description: "Evening readings reveal how your body winds down after the day.", shape: .shield, categoryID: "sleep_night_routine", metric: .daysStreak, tiers: tierList([2, 3, 7, 14, 21, 30, 45, 60, 90, 120, 150, 180, 210, 240, 270], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Night Guardian %@"),
                Achievement(id: "achv_morning_bird", title: "After Sleep", subtitle: "Measure after waking up", description: "After-sleep readings show how well your body recovered overnight.", shape: .circle, categoryID: "sleep_night_routine", metric: .days, tiers: tierList([1, 3, 5, 7, 14, 21, 30, 45, 60, 90, 120, 150], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Morning Bird %@"),
                Achievement(id: "achv_sleep_keeper", title: "Before Sleep", subtitle: "Measure before going to bed", description: "A quiet evening reading is a useful anchor for your sleep routine.", shape: .circle, categoryID: "sleep_night_routine", metric: .days, tiers: tierList([1, 3, 5, 7, 14, 21, 30, 45, 60, 90, 120, 150], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Night Keeper %@"),
                Achievement(id: "achv_perfect_pair", title: "Perfect Pair", subtitle: "Close a before/after sleep pair", description: "Pairing readings around sleep shows the size of your overnight recovery.", shape: .hexagon, categoryID: "sleep_night_routine", metric: .pairsClosed, tiers: tierList([1, 3, 5, 7, 14, 21, 30, 45, 60, 90, 120, 150], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Sleep Pair Pro %@")
            ]
        )

        let mental = AchievementCategory(
            id: "mental_load_stress",
            title: "Mental Load & Stress",
            icon: "brain.head.profile",
            colorHex: 0x8B6BD9,
            achievements: [
                Achievement(id: "achv_tagged_measures", title: "Tagged Measures", subtitle: "Use context tags regularly", description: "Tags turn a number into a story. Label what was happening around each reading.", shape: .square, categoryID: "mental_load_stress", metric: .measurements, tiers: tierList([10, 20, 30, 45, 60, 75, 100, 150, 200, 300, 400, 500, 750, 1000, 1500], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Context Collector %@"),
                Achievement(id: "achv_meditation_lab", title: "Meditation Lab", subtitle: "Close a meditation pair", description: "Compare before and after a short mindfulness session to see your response.", shape: .capsule, categoryID: "mental_load_stress", metric: .pairsClosed, tiers: tierList([1, 3, 5, 7, 14, 21, 30, 45, 60, 90, 120, 150], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Mindful Lab %@"),
                Achievement(id: "achv_resilience_loop", title: "Resilience Loop", subtitle: "Close a stress pair", description: "Before and after readings around stressful moments reveal how quickly you recover.", shape: .circle, categoryID: "mental_load_stress", metric: .pairsClosed, tiers: tierList([1, 3, 5, 7, 14, 21, 30, 45, 60, 90, 120, 150], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Resilience Builder %@"),
                Achievement(id: "achv_baseline_guardian", title: "Rest Control", subtitle: "Build a rest-measurement baseline", description: "Three or more rest readings in a week gives you a dependable recovery baseline.", shape: .shield, categoryID: "mental_load_stress", metric: .weeks, tiers: tierList([1, 2, 3, 5, 7, 9, 12, 15, 18, 21, 24, 27, 30, 40, 50], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Baseline Guardian %@")
            ]
        )

        let activity = AchievementCategory(
            id: "activity_fitness",
            title: "Activity & Fitness",
            icon: "figure.run",
            colorHex: 0xE07B3F,
            achievements: [
                Achievement(id: "achv_workout_reaction", title: "Exercise Response", subtitle: "Close an exercise pair", description: "Measure before and after exercise to learn how your heart responds to load.", shape: .capsule, categoryID: "activity_fitness", metric: .pairsClosed, tiers: tierList([1, 3, 5, 10, 20, 30, 45, 60, 75, 100, 150, 200, 300, 400, 500], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Workout Reaction %@"),
                Achievement(id: "achv_full_spectrum", title: "Full Spectrum", subtitle: "Pairs in every cluster", description: "Collect pairs across rest, load, performance and food to complete the picture.", shape: .hexagon, categoryID: "activity_fitness", metric: .pairsClosed, tiers: tierList([1, 2, 3, 5, 7, 9, 12, 15, 18, 21, 24, 30, 50, 75, 100], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Full Spectrum %@"),
                Achievement(id: "achv_3_hour_lab", title: "3-Hour Lab", subtitle: "Close pairs within three hours", description: "Fast pair windows are ideal for seeing acute responses to load and stress.", shape: .capsule, categoryID: "activity_fitness", metric: .pairsClosed, tiers: tierList([10, 20, 30, 45, 60, 75, 100, 150, 200, 300, 400, 500], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Rapid Response %@")
            ]
        )

        let insights = AchievementCategory(
            id: "self_tracking_insights",
            title: "Self-Tracking & Insights",
            icon: "book.fill",
            colorHex: 0x2F9C8E,
            achievements: [
                Achievement(id: "achv_insight_scholar", title: "Learning Hub", subtitle: "Read articles in Insights", description: "The more you understand your signals, the better your decisions become.", shape: .square, categoryID: "self_tracking_insights", metric: .articles, tiers: tierList([3, 5, 7, 10, 15, 20, 30, 40, 50, 60, 70, 80], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Insight Scholar %@"),
                Achievement(id: "achv_ai_explorer", title: "AI Comments", subtitle: "Read AI explanations", description: "AI comments translate the numbers into everyday language and next steps.", shape: .square, categoryID: "self_tracking_insights", metric: .aiComments, tiers: tierList([10, 20, 30, 45, 60, 75, 100, 150, 200, 300, 400, 500], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "AI Explorer %@"),
                Achievement(id: "achv_30_day_consistency", title: "30-Day Consistency", subtitle: "Stay active across 30 days", description: "A month of regular readings gives you a reliable personal baseline.", shape: .circle, categoryID: "self_tracking_insights", metric: .streak30days, tiers: tierList([3, 4, 5, 6, 7, 8, 10, 12, 15, 20, 25, 30], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Monthly Rhythm %@"),
                Achievement(id: "achv_90_day_consistency", title: "90-Day Consistency", subtitle: "Stay active across 90 days", description: "Three months of consistency reveals seasonal and lifestyle patterns.", shape: .circle, categoryID: "self_tracking_insights", metric: .streak90days, tiers: tierList([30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 90], ribbonsAt: [(5, .blue), (8, .red), (11, .purple)]), rewardTitle: "Seasoned Tracker %@"),
                Achievement(id: "achv_context_atlas", title: "Tagged Measures", subtitle: "Use every context tag", description: "The Context Atlas is complete when every one of the eleven tags has been used.", shape: .square, categoryID: "self_tracking_insights", metric: .allTagsSets, tiers: tierList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 18, 25], ribbonsAt: [(8, .blue), (11, .red), (14, .purple)]), rewardTitle: "Tag Master  %@"),
                Achievement(id: "achv_setup_health", title: "Setup", subtitle: "Apple Health Sync", description: "Connect Apple Health to get additional heart rate measurements from your Apple Watch.", shape: .square, categoryID: "self_tracking_insights", metric: .setup, tiers: tierList([1]), rewardTitle: "Watch Sync Master %@")
            ]
        )

        return [daily, sleep, mental, activity, insights]
    }
}

enum AchievementEngine {
    static func value(for achievement: Achievement, store: AppStore) -> Int {
        switch achievement.metric {
        case .measurements: return store.measurementCount
        case .days: return store.measurementDayCount
        case .daysStreak: return store.measurementStreak
        case .weeks: return restWeeks(store)
        case .pairsClosed: return pairCount(store)
        case .articles: return store.articlesReadCount
        case .aiComments: return 0
        case .streak30days: return daysWithMeasurements(store, last: 30)
        case .streak90days: return daysWithMeasurements(store, last: 90)
        case .allTagsSets:
            return TagCatalog.presets.map { tag in store.measurements.filter { $0.tagID == tag.id }.count }.min() ?? 0
        case .setup:
            return store.appleHealthConnected ? 1 : 0
        }
    }

    static func unlockedTierIndex(_ achievement: Achievement, store: AppStore) -> Int {
        let value = value(for: achievement, store: store)
        return achievement.tiers.filter { $0.rewardValue <= value }.count
    }

    static func nextTier(_ achievement: Achievement, store: AppStore) -> AchievementTier? {
        let value = value(for: achievement, store: store)
        return achievement.tiers.first { $0.rewardValue > value }
    }

    static func progress(_ achievement: Achievement, store: AppStore) -> Double {
        min(Double(value(for: achievement, store: store)) / Double(max(achievement.finalTarget, 1)), 1)
    }

    static func completedCount(store: AppStore) -> Int {
        AchievementCatalog.all.filter { value(for: $0, store: store) >= ($0.tiers.first?.rewardValue ?? 1) }.count
    }

    private static func daysWithMeasurements(_ store: AppStore, last days: Int) -> Int {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -days + 1, to: cal.startOfDay(for: Date())) else { return 0 }
        return Set(store.measurements.filter { $0.date >= start }.map(\.day)).count
    }

    private static func restWeeks(_ store: AppStore) -> Int {
        var counts: [Date: Int] = [:]
        let cal = Calendar.current
        for m in store.measurements where (m.tagID ?? "").hasPrefix("sleep") || (m.tagID ?? "").hasPrefix("relax") {
            if let week = cal.dateInterval(of: .weekOfYear, for: m.date)?.start {
                counts[week, default: 0] += 1
            }
        }
        return counts.values.filter { $0 >= 3 }.count
    }

    private static func pairCount(_ store: AppStore) -> Int {
        let measurements = store.measurements.sorted { $0.date < $1.date }
        var count = 0
        var used = Set<UUID>()
        for (index, item) in measurements.enumerated() {
            guard let tag = item.tagID, tag.hasSuffix("-before"), !used.contains(item.id) else { continue }
            let family = String(tag.dropLast("-before".count))
            for candidate in measurements[(index + 1)...] {
                if candidate.tagID == "\(family)-after", candidate.date.timeIntervalSince(item.date) <= 12 * 3600 {
                    count += 1
                    used.insert(item.id)
                    used.insert(candidate.id)
                    break
                }
                if candidate.date.timeIntervalSince(item.date) > 12 * 3600 { break }
            }
        }
        return count
    }
}
