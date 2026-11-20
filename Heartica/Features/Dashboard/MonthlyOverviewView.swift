import SwiftUI

struct MonthlyOverviewView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var month = Calendar.current.startOfMonth(for: Date())
    @State private var metric: Metric = .pulse
    @State private var selectedDay = Date()
    @State private var showPaywall = false

    private let monthMetrics: [Metric] = [.healthIndex, .energy, .stress, .pulse, .hrv, .sdnn, .rmssd, .pnn50, .csi, .pressureSystolic, .pressureDiastolic, .oxygen, .glucoseBeforeMeal, .glucoseAfterMeal]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                scrollContent
            }
            if !store.isPremium {
                promoOverlay
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(placement: "in_app")
                .environmentObject(store)
                .environmentObject(router)
        }
        .onAppear {
            if !Calendar.current.isDate(selectedDay, equalTo: Date(), toGranularity: .month) {
                selectedDay = Date()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MONTHLY OVERVIEW")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(Theme.teal)
                Text(Fmt.monthTitle.string(from: month))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    withAnimation { shiftMonth(-1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                Button {
                    withAnimation { shiftMonth(1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                IconButton(systemName: "xmark", size: 36, identifier: "monthly.close") { dismiss() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                metricPicker
                calendarCard
                dayCard
                Color.clear.frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private var metricPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(monthMetrics) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { metric = item }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(metric == item ? .white : Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(metric == item ? Theme.accent : Theme.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(metric == item ? Color.clear : Theme.separator.opacity(0.7), lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
    }

    private var calendarCard: some View {
        VStack(spacing: 10) {
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(Array(calendarCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private var weekdaySymbols: [String] {
        let cal = Calendar.current
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var calendarCells: [Date?] {
        let cal = Calendar.current
        let start = cal.startOfMonth(for: month)
        let weekday = cal.component(.weekday, from: start)
        let leading = (weekday - cal.firstWeekday + 7) % 7
        let days = cal.monthDays(for: month)
        return Array(repeating: nil, count: leading) + days.map { Optional($0) }
    }

    private func dayCell(_ date: Date) -> some View {
        let selected = Calendar.current.isDate(date, inSameDayAs: selectedDay)
        let value = value(on: date, for: metric)
        let dayNumber = Calendar.current.component(.day, from: date)
        let isToday = Calendar.current.isDateInToday(date)
        let future = date > Date()
        return Button {
            selectedDay = date
        } label: {
            VStack(spacing: 3) {
                Text("\(dayNumber)")
                    .font(.system(size: 11, weight: isToday ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(selected ? .white : (future ? Theme.textTertiary.opacity(0.5) : Theme.textPrimary))
                Circle()
                    .fill(value == nil ? Color.clear : (selected ? Color.white : metric.color))
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(selected ? Theme.accent : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isToday && !selected ? Theme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dayCard: some View {
        let values = values(on: selectedDay, for: metric)
        let average = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        let status = average.flatMap { statusFor($0) }
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day Average")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Theme.textTertiary)
                    Text(Fmt.longDate.string(from: selectedDay))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if let currentStatus = status { StatusPill(status: currentStatus) }
            }
            HStack(alignment: .bottom, spacing: 4) {
                Text(average.map { Fmt.value($0, decimals: metric.decimals) } ?? "—")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(metric.unit)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 7)
                Spacer()
                if let average, average != 0 {
                    trendView(average)
                }
            }
            if values.count > 1 {
                BarSparkline(values: values, color: metric.color)
                    .frame(height: 48)
            } else if values.isEmpty {
                Text("Take measurements to see your stats")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("\(values.count) reading\(values.count == 1 ? "" : "s") · \(metric.title)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 16)
    }

    private func trendView(_ average: Double) -> some View {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) ?? selectedDay
        let previousValues = values(on: previousDay, for: metric)
        let previous = previousValues.isEmpty ? nil : previousValues.reduce(0, +) / Double(previousValues.count)
        let delta = (previous ?? average) - average
        return HStack(spacing: 3) {
            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text("\(Fmt.value(abs(delta), decimals: metric.decimals))")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(delta >= 0 ? Theme.orange : Theme.teal)
    }

    private func shiftMonth(_ delta: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: month) else { return }
        month = Calendar.current.startOfMonth(for: newMonth)
        if let first = Calendar.current.monthDays(for: month).first {
            selectedDay = first
        }
        let today = Date()
        if Calendar.current.isDate(today, equalTo: month, toGranularity: .month) { selectedDay = today }
    }

    private var promoOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.16))
                    .clipShape(Circle())
                Text("Monthly Insights")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Unlock Premium to see full trends")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Button {
                    showPaywall = true
                } label: {
                    Text("Unlock")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accentDeep)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 12)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
                Button("Not now") { dismiss() }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(30)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.duskGradient).opacity(0.9))
            )
        }
    }

    private func value(on date: Date, for metric: Metric) -> Double? {
        let values = values(on: date, for: metric)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func values(on date: Date, for metric: Metric) -> [Double] {
        let cal = Calendar.current
        switch metric {
        case .pressureSystolic:
            return store.pressureLogs.filter { cal.isDate($0.date, inSameDayAs: date) }.map { Double($0.sys) }
        case .pressureDiastolic:
            return store.pressureLogs.filter { cal.isDate($0.date, inSameDayAs: date) }.map { Double($0.dia) }
        case .oxygen:
            return store.oxygenLogs.filter { cal.isDate($0.date, inSameDayAs: date) }.map { Double($0.value) }
        case .glucoseBeforeMeal:
            return store.glucoseLogs.filter { cal.isDate($0.date, inSameDayAs: date) && $0.tagID == "eating-before" }.map(\.valueMgdl)
        case .glucoseAfterMeal:
            return store.glucoseLogs.filter { cal.isDate($0.date, inSameDayAs: date) && $0.tagID == "eating-after" }.map(\.valueMgdl)
        case .csi:
            return store.measurements.filter { cal.isDate($0.date, inSameDayAs: date) }.map { Double($0.csi) }
        case .heartAge:
            return []
        default:
            return store.measurements.filter { cal.isDate($0.date, inSameDayAs: date) }.map { measurement in
                switch metric {
                case .pulse: return Double(measurement.pulse)
                case .hrv: return measurement.hrv
                case .sdnn: return measurement.sdnn
                case .rmssd: return measurement.rmssd
                case .pnn50: return measurement.pnn50
                case .energy: return measurement.energy
                case .stress: return measurement.stress
                case .healthIndex: return measurement.healthIndex
                default: return 0
                }
            }
        }
    }

    private func statusFor(_ value: Double) -> HealthStatus? {
        switch metric {
        case .pulse: return HealthEvaluator.pulse(Int(value))
        case .hrv: return HealthEvaluator.hrv(value)
        case .sdnn: return HealthEvaluator.sdnn(value)
        case .rmssd: return HealthEvaluator.rmssd(value)
        case .pnn50: return HealthEvaluator.pnn50(value)
        case .energy: return HealthEvaluator.energy(value)
        case .stress: return HealthEvaluator.stress(value)
        case .healthIndex: return HealthEvaluator.healthIndex(value)
        case .csi: return HealthEvaluator.csi(value)
        case .pressureSystolic, .pressureDiastolic: return nil
        case .oxygen: return HealthEvaluator.oxygen(Int(value))
        case .glucoseBeforeMeal: return HealthEvaluator.glucose(value, afterMeal: false)
        case .glucoseAfterMeal: return HealthEvaluator.glucose(value, afterMeal: true)
        case .heartAge: return nil
        }
    }
}
