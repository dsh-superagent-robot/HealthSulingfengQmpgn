import Foundation
import SwiftUI

enum TagCatalog {
    static let presets: [TagDefinition] = [
        TagDefinition(id: "sleep-before", name: "Before Sleep", cluster: .rest, color: .blue),
        TagDefinition(id: "sleep-after", name: "After Sleep", cluster: .rest, color: .blue),
        TagDefinition(id: "activity-before", name: "Before Exercise", cluster: .load, color: .orange),
        TagDefinition(id: "activity-after", name: "After Exercise", cluster: .load, color: .orange),
        TagDefinition(id: "stress-before", name: "Before Stress", cluster: .load, color: .red),
        TagDefinition(id: "stress-during", name: "During Stress", cluster: .load, color: .red),
        TagDefinition(id: "stress-after", name: "After Stress", cluster: .load, color: .red),
        TagDefinition(id: "relax-before", name: "Before Meditation", cluster: .performance, color: .green),
        TagDefinition(id: "relax-after", name: "After Meditation", cluster: .performance, color: .green),
        TagDefinition(id: "eating-before", name: "Before Meal", cluster: .food, color: .yellow),
        TagDefinition(id: "eating-after", name: "After Meal", cluster: .food, color: .yellow)
    ]

    static let allClusters: [TagCluster] = [.rest, .load, .performance, .food]

    static func context(for id: String) -> String? {
        if id.hasPrefix("sleep") { return "sleep" }
        if id.hasPrefix("activity") { return "activity" }
        if id.hasPrefix("stress") { return "stress" }
        if id.hasPrefix("relax") { return "relax" }
        if id.hasPrefix("eating") { return "food" }
        return nil
    }
}

enum Metric: String, CaseIterable, Codable, Identifiable {
    case healthIndex, energy, stress, pulse, hrv, sdnn, rmssd, pnn50, csi, pressureSystolic, pressureDiastolic, oxygen, glucoseBeforeMeal, glucoseAfterMeal, heartAge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healthIndex: return "Health Index"
        case .energy: return "Energy"
        case .stress: return "Stress"
        case .pulse: return "Pulse"
        case .hrv: return "HRV"
        case .sdnn: return "SDNN"
        case .rmssd: return "RMSSD"
        case .pnn50: return "pNN50"
        case .csi: return "Stress Index"
        case .pressureSystolic: return "Pressure SYS"
        case .pressureDiastolic: return "Pressure DIA"
        case .oxygen: return "Blood Oxygen"
        case .glucoseBeforeMeal: return "Glucose Before Meal"
        case .glucoseAfterMeal: return "Glucose After Meal"
        case .heartAge: return "Heart Age"
        }
    }

    var shortTitle: String {
        switch self {
        case .healthIndex: return "Health"
        case .energy: return "Energy"
        case .stress: return "Stress"
        case .pulse: return "Pulse"
        case .hrv: return "HRV"
        case .sdnn: return "SDNN"
        case .rmssd: return "RMSSD"
        case .pnn50: return "pNN50"
        case .csi: return "CSI"
        case .pressureSystolic: return "SYS"
        case .pressureDiastolic: return "DIA"
        case .oxygen: return "SpO₂"
        case .glucoseBeforeMeal: return "Before Meal"
        case .glucoseAfterMeal: return "After Meal"
        case .heartAge: return "Heart Age"
        }
    }

    var unit: String {
        switch self {
        case .pulse: return "bpm"
        case .hrv, .sdnn, .rmssd: return "ms"
        case .pnn50, .energy, .stress: return "%"
        case .pressureSystolic, .pressureDiastolic: return "mmHg"
        case .oxygen: return "%"
        case .glucoseBeforeMeal, .glucoseAfterMeal: return "mg/dL"
        case .heartAge: return "years"
        case .healthIndex, .csi: return ""
        }
    }

    var icon: String {
        switch self {
        case .healthIndex: return "heart.text.square.fill"
        case .energy: return "bolt.heart.fill"
        case .stress: return "waveform.path.ecg"
        case .pulse: return "heart.fill"
        case .hrv, .sdnn, .rmssd, .pnn50: return "waveform"
        case .csi: return "brain.head.profile"
        case .pressureSystolic, .pressureDiastolic: return "gauge.with.dots.needle.50percent"
        case .oxygen: return "lungs.fill"
        case .glucoseBeforeMeal, .glucoseAfterMeal: return "drop.fill"
        case .heartAge: return "hourglass"
        }
    }

    var color: Color {
        switch self {
        case .healthIndex, .pulse, .heartAge: return Theme.accent
        case .energy: return Theme.amber
        case .stress, .csi: return Theme.orange
        case .hrv, .sdnn, .rmssd, .pnn50: return Theme.teal
        case .pressureSystolic, .pressureDiastolic: return Theme.blue
        case .oxygen: return Theme.purple
        case .glucoseBeforeMeal, .glucoseAfterMeal: return Theme.pink
        }
    }

    var decimals: Int {
        switch self {
        case .pulse, .csi, .pressureSystolic, .pressureDiastolic, .oxygen, .heartAge: return 0
        case .glucoseBeforeMeal, .glucoseAfterMeal: return 0
        default: return 1
        }
    }
}

struct MetricPoint: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double
    var secondary: Double?
}

enum Statistics {
    static func measurements(in range: ClosedRange<Date>, from store: AppStore) -> [HeartRateMeasurement] {
        store.measurements.filter { range.contains($0.date) }.sortedAscending
    }

    static func averagePulse(_ items: [HeartRateMeasurement]) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.map(\.pulse).reduce(0, +)) / Double(items.count)
    }

    static func average(_ items: [HeartRateMeasurement], _ keyPath: KeyPath<HeartRateMeasurement, Double>) -> Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(items.count)
    }

    static func csiAverage(_ items: [HeartRateMeasurement], days: Int = 7) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = items.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return nil }
        return Double(recent.map(\.csi).reduce(0, +)) / Double(recent.count)
    }

    static func uniqueDays(_ items: [HeartRateMeasurement]) -> Int {
        Set(items.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    static func streak(_ dates: [Date]) -> Int {
        let days = Set(dates.map { Calendar.current.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted(by: >)
        var streak = 1
        var cursor = sorted[0]
        for day in sorted.dropFirst() {
            guard let next = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            if Calendar.current.isDate(day, inSameDayAs: next) {
                streak += 1
                cursor = day
            } else {
                break
            }
        }
        return streak
    }

    static func heartAge(store: AppStore) -> Int? {
        guard let age = store.profile.age else { return nil }
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let items = store.measurements.filter { $0.date >= cutoff }
        guard Set(items.map(\.day)).count >= 3 else { return nil }
        let avg = average(items, \.rmssd)
        let delta = (55.0 - avg) / 8.0
        return Int(clamp(Double(age) + delta, 18, 90).rounded())
    }

    static func dailySeries(_ items: [HeartRateMeasurement], keyPath: KeyPath<HeartRateMeasurement, Double>, days: Int) -> [MetricPoint] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -(days - 1), to: Date()) ?? Date())
        return (0..<days).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let dayItems = items.filter { cal.isDate($0.date, inSameDayAs: day) }
            guard !dayItems.isEmpty else { return nil }
            let avg = dayItems.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(dayItems.count)
            return MetricPoint(date: day, value: avg)
        }
    }
}
