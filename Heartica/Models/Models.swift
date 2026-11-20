import Foundation
import SwiftUI

// MARK: - Core records

enum Gender: String, Codable, CaseIterable, Identifiable {
    case female, male, none
    var id: String { rawValue }
    var title: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .none: return "Not Set"
        }
    }
}

enum MeasurementSource: String, Codable, CaseIterable {
    case inApp
    case appleWatch
    var title: String { self == .appleWatch ? "Apple Watch" : "In-app" }
    var shortTitle: String { self == .appleWatch ? "Watch" : "App" }
}

struct Profile: Codable, Equatable {
    var name: String = ""
    var surname: String = ""
    var age: Int?
    var gender: Gender = .none
    var weightKg: Double?
    var heightCm: Double?
    var avatarFilename: String?

    var displayName: String {
        let full = "\(name) \(surname)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? "Your Profile" : full
    }

    var initials: String {
        let first = name.first.map(String.init) ?? ""
        let last = surname.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "H" : value
    }

    var bmi: Double? {
        guard let weight = weightKg, let height = heightCm, height > 0 else { return nil }
        let m = height / 100
        return weight / (m * m)
    }

    var bmiCategory: String? {
        guard let bmi else { return nil }
        switch bmi {
        case ..<18.5: return "Low"
        case ..<25: return "Normal"
        case ..<30: return "Overweight"
        default: return "Obese"
        }
    }
}

struct HeartRateMeasurement: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var pulse: Int
    var rmssd: Double
    var sdnn: Double
    var pnn50: Double
    var energy: Double
    var stress: Double
    var healthIndex: Double
    var csi: Int
    var source: MeasurementSource = .inApp
    var tagID: String?
    var healthKitID: String?

    var hrv: Double { sdnn }
    var pulseValue: Double { Double(pulse) }
    var bpmText: String { "\(pulse)" }
    var day: Date { Calendar.current.startOfDay(for: date) }
}

struct PressureLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var sys: Int
    var dia: Int
    var tagID: String?
    var day: Date { Calendar.current.startOfDay(for: date) }
}

struct GlucoseLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var valueMgdl: Double
    var tagID: String?
    var day: Date { Calendar.current.startOfDay(for: date) }

    /// The app stores glucose canonically in mg/dL.
    var valueMmol: Double { valueMgdl / 18.0 }
}

struct OxygenLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var value: Int
    var tagID: String?
    var day: Date { Calendar.current.startOfDay(for: date) }
}

struct ReminderItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: ReminderType
    var time: Date
    var isScheduled: Bool = true
}

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case pulse, pressure, glucose, oxygen, heartAge, pulseCSI
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pulse: return "Pulse"
        case .pressure: return "Pressure"
        case .glucose: return "Glucose"
        case .oxygen: return "Oxygen"
        case .heartAge: return "Heart Age"
        case .pulseCSI: return "Pulse CSI"
        }
    }
    var pushTitle: String {
        switch self {
        case .pulse: return "Pulse reminder"
        case .pressure: return "Pressure reminder"
        case .glucose: return "Glucose reminder"
        case .oxygen: return "Oxygen reminder"
        case .heartAge: return "Heart Age reminder"
        case .pulseCSI: return "Pulse CSI reminder"
        }
    }
    var icon: String {
        switch self {
        case .pulse: return "heart.fill"
        case .pressure: return "waveform.path.ecg"
        case .glucose: return "drop.fill"
        case .oxygen: return "lungs.fill"
        case .heartAge: return "hourglass"
        case .pulseCSI: return "brain.head.profile"
        }
    }
}

// MARK: - Tags

enum TagColor: String, Codable, CaseIterable, Identifiable {
    case red, orange, yellow, green, blue, darkBlue
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .red: return Color(hex: 0xE0525B)
        case .orange: return Color(hex: 0xE68A3C)
        case .yellow: return Color(hex: 0xE0B23C)
        case .green: return Color(hex: 0x51A56A)
        case .blue: return Color(hex: 0x4F83D8)
        case .darkBlue: return Color(hex: 0x4454A6)
        }
    }
    var softColor: Color { color.opacity(0.14) }
}

enum TagCluster: String, Codable, CaseIterable, Identifiable {
    case rest, load, performance, food, general
    var id: String { rawValue }
    var title: String {
        switch self {
        case .rest: return "Rest"
        case .load: return "Load"
        case .performance: return "Performance"
        case .food: return "Food"
        case .general: return "General"
        }
    }
}

struct TagDefinition: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var cluster: TagCluster
    var color: TagColor
    var isCustom: Bool = false
}

// MARK: - Enumerations used across UI

enum AppTab: String, CaseIterable, Identifiable {
    case home, dashboard, insights, me
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"
        case .dashboard: return "Dashboard"
        case .insights: return "Insights"
        case .me: return "Me"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .dashboard: return "chart.xyaxis.line"
        case .insights: return "book.fill"
        case .me: return "person.fill"
        }
    }
}

enum ChartKind: String, CaseIterable, Codable, Identifiable {
    case bar, barWithThresholds, line, lineWithThresholds
    var id: String { rawValue }
    var title: String {
        switch self {
        case .bar: return "Bar"
        case .barWithThresholds: return "Bar + Thresholds"
        case .line: return "Line"
        case .lineWithThresholds: return "Line + Thresholds"
        }
    }
    var showsThresholds: Bool { self == .barWithThresholds || self == .lineWithThresholds }
    var isBar: Bool { self == .bar || self == .barWithThresholds }
}

enum ChartPeriod: String, CaseIterable, Codable, Identifiable {
    case day, week, month, quarter, year
    var id: String { rawValue }
    var shortTitle: String {
        switch self {
        case .day: return "D"
        case .week: return "W"
        case .month: return "M"
        case .quarter: return "3M"
        case .year: return "Y"
        }
    }
    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "3 Months"
        case .year: return "Year"
        }
    }
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Status evaluation

struct HealthStatus {
    var label: String
    var interpretation: String
    var color: Color
    var isGood: Bool = true
}

enum HealthEvaluator {
    static func pulse(_ bpm: Int) -> HealthStatus {
        switch bpm {
        case ..<60:
            return HealthStatus(label: "Low", interpretation: "Bradycardia", color: Theme.blue)
        case 60...100:
            return HealthStatus(label: "Normal", interpretation: "Resting Heart Rate", color: Theme.green)
        case 101...120:
            return HealthStatus(label: "High", interpretation: "Mild Tachycardia", color: Theme.orange)
        default:
            return HealthStatus(label: "Very High", interpretation: "Severe Tachycardia", color: Theme.accent, isGood: false)
        }
    }

    static func hrv(_ value: Double) -> HealthStatus {
        switch value {
        case ..<50:
            return HealthStatus(label: "Low", interpretation: "Possible chronic stress or ANS imbalance", color: Theme.orange)
        case 50...100:
            return HealthStatus(label: "Normal", interpretation: "Moderate stress or age-related changes", color: Theme.green)
        default:
            return HealthStatus(label: "High", interpretation: "Excellent variability, good health status", color: Theme.teal)
        }
    }

    static func rmssd(_ value: Double) -> HealthStatus {
        switch value {
        case ..<20:
            return HealthStatus(label: "Very Low", interpretation: "High stress, or poor recovery", color: Theme.accent)
        case 20..<30:
            return HealthStatus(label: "Low", interpretation: "Possible chronic stress or ANS imbalance", color: Theme.orange)
        case 30..<50:
            return HealthStatus(label: "Average", interpretation: "Balanced autonomic function", color: Theme.amber)
        case 50...80:
            return HealthStatus(label: "Good", interpretation: "Well-trained individuals", color: Theme.green)
        default:
            return HealthStatus(label: "Excellent", interpretation: "Typically seen in elite athletes", color: Theme.teal)
        }
    }

    static func sdnn(_ value: Double) -> HealthStatus { hrv(value) }

    static func pnn50(_ value: Double) -> HealthStatus {
        switch value {
        case ..<10:
            return HealthStatus(label: "Low", interpretation: "Chronic stress or poor recovery", color: Theme.orange)
        case 10..<20:
            return HealthStatus(label: "Reduced", interpretation: "Possible mild stress or early autonomic fatigue", color: Theme.amber)
        case 20...30:
            return HealthStatus(label: "Normal", interpretation: "Healthy, with moderate activity", color: Theme.green)
        default:
            return HealthStatus(label: "Excellent", interpretation: "Healthy cardiovascular system", color: Theme.teal)
        }
    }

    static func energy(_ value: Double) -> HealthStatus {
        switch value {
        case ..<60:
            return HealthStatus(label: "Low", interpretation: "High stress, poor recovery", color: Theme.orange)
        case 60..<80:
            return HealthStatus(label: "Average", interpretation: "Increased stress or fatigue", color: Theme.amber)
        case 80...100:
            return HealthStatus(label: "Good", interpretation: "Balanced state, normal autonomic function", color: Theme.green)
        default:
            return HealthStatus(label: "Excellent", interpretation: "Strong recovery, high parasympathetic tone", color: Theme.teal)
        }
    }

    static func stress(_ value: Double) -> HealthStatus {
        switch value {
        case ..<25:
            return HealthStatus(label: "Relaxed", interpretation: "Deeply relaxed", color: Theme.teal)
        case 25..<35:
            return HealthStatus(label: "Low", interpretation: "Quite relaxed", color: Theme.green)
        case 35..<70:
            return HealthStatus(label: "Average", interpretation: "Mildly calm", color: Theme.amber)
        case 70..<80:
            return HealthStatus(label: "High", interpretation: "Slightly tense", color: Theme.orange)
        default:
            return HealthStatus(label: "Very High", interpretation: "Highly tense", color: Theme.accent, isGood: false)
        }
    }

    static func healthIndex(_ value: Double) -> HealthStatus {
        switch value {
        case ..<3.5:
            return HealthStatus(label: "Low", interpretation: "High stress, poor recovery", color: Theme.orange)
        case 3.5..<4.5:
            return HealthStatus(label: "Average", interpretation: "Moderate stress, possible fatigue", color: Theme.amber)
        case 4.5..<5.5:
            return HealthStatus(label: "Good", interpretation: "Balanced state, normal recovery", color: Theme.green)
        case 5.5..<6.5:
            return HealthStatus(label: "Excellent", interpretation: "Optimal recovery, low stress", color: Theme.teal)
        default:
            return HealthStatus(label: "Athlete", interpretation: "High parasympathetic activity", color: Theme.purple)
        }
    }

    /// Baevsky-style stress index bands (7-day average).
    static func csi(_ value: Double) -> HealthStatus {
        switch value {
        case ..<50:
            return HealthStatus(label: "Low Stress", interpretation: "Calm and relaxed state", color: Theme.blue)
        case 50..<150:
            return HealthStatus(label: "Normal", interpretation: "Healthy and well-balanced state", color: Theme.green)
        case 150..<300:
            return HealthStatus(label: "Elevated Stress", interpretation: "Physical and mental exertion", color: Theme.amber)
        case 300..<500:
            return HealthStatus(label: "High Stress", interpretation: "Significant strain and tension", color: Theme.orange)
        default:
            return HealthStatus(label: "Very High Stress", interpretation: "Risk of burnout and chronic stress", color: Theme.accent, isGood: false)
        }
    }

    static func heartAge(_ heartAge: Int, realAge: Int?) -> HealthStatus {
        guard let realAge else {
            return HealthStatus(label: "Add age", interpretation: "Add your age & gender to compare", color: Theme.textSecondary)
        }
        if heartAge < realAge - 1 {
            return HealthStatus(label: "Good", interpretation: "Heart age is below your biological age", color: Theme.green)
        } else if heartAge > realAge + 1 {
            return HealthStatus(label: "High", interpretation: "Heart age is above your biological age", color: Theme.orange)
        }
        return HealthStatus(label: "Equal", interpretation: "Heart age matches your biological age", color: Theme.amber)
    }

    static func pressure(sys: Int, dia: Int) -> HealthStatus {
        switch (sys, dia) {
        case (..<90, ..<60):
            return HealthStatus(label: "Low", interpretation: "Below the typical range", color: Theme.blue)
        case (..<120, ..<80):
            return HealthStatus(label: "Normal", interpretation: "Healthy blood pressure", color: Theme.green)
        case (..<130, ..<80):
            return HealthStatus(label: "Elevated", interpretation: "Slightly above the healthy range", color: Theme.amber)
        case (..<140, ..<90):
            return HealthStatus(label: "High", interpretation: "Stage 1 hypertension range", color: Theme.orange)
        default:
            return HealthStatus(label: "Very High", interpretation: "Stage 2 hypertension range", color: Theme.accent, isGood: false)
        }
    }

    static func oxygen(_ value: Int) -> HealthStatus {
        switch value {
        case ..<90:
            return HealthStatus(label: "Very Low", interpretation: "Seek medical advice if this persists", color: Theme.accent, isGood: false)
        case 90..<95:
            return HealthStatus(label: "Low", interpretation: "Below the usual resting range", color: Theme.orange)
        default:
            return HealthStatus(label: "Normal", interpretation: "Healthy oxygen saturation", color: Theme.green)
        }
    }

    static func glucose(_ mgdl: Double, afterMeal: Bool = false) -> HealthStatus {
        let threshold = afterMeal ? 180.0 : 130.0
        switch mgdl {
        case ..<70:
            return HealthStatus(label: "Low", interpretation: "Below the typical range", color: Theme.blue)
        case ..<threshold:
            return HealthStatus(label: "Normal", interpretation: "Within the target range", color: Theme.green)
        case ..<(afterMeal ? 250 : 180):
            return HealthStatus(label: "Elevated", interpretation: "Above the target range", color: Theme.amber)
        default:
            return HealthStatus(label: "High", interpretation: "Well above the target range", color: Theme.accent, isGood: false)
        }
    }
}

// MARK: - Formatters

enum Fmt {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let longDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    static let monthTitle: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let monthShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    static let dayNumber: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    static let weekdayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    static let weekdayLetter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f
    }()

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func value(_ value: Double, decimals: Int = 0) -> String {
        String(format: "%.\(decimals)f", value)
    }

    static func signed(_ value: Double, decimals: Int = 0) -> String {
        let text = Fmt.value(value, decimals: decimals)
        return value > 0 ? "+\(text)" : text
    }

    static func int(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        return shortDate.string(from: date)
    }

    static func duration(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}

// MARK: - Shared helpers

func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
    min(max(value, lower), upper)
}

extension Array where Element == HeartRateMeasurement {
    var sortedAscending: [HeartRateMeasurement] { sorted { $0.date < $1.date } }
    var latest: HeartRateMeasurement? { max(by: { $0.date < $1.date }) }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? startOfDay(for: date)
    }

    func monthDays(for date: Date) -> [Date] {
        guard let range = range(of: .day, in: .month, for: date) else { return [] }
        let start = startOfMonth(for: date)
        return range.compactMap { day in
            self.date(byAdding: .day, value: day - 1, to: start)
        }
    }
}
