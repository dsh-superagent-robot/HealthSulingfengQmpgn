import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter

    @State private var selectedMetric: Metric?
    @State private var showGraphSettings = false
    @State private var showProfile = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                highlights
                SectionHeading(title: "Metrics", actionTitle: "Chart Settings") {
                    showGraphSettings = true
                }
                metricsGrid
                csiCard
                heartAgeCard
                monthlyCard
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
        .sheet(isPresented: $showGraphSettings) {
            GraphSettingsView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView()
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR HEALTH")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Theme.accent)
                Text("Dashboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Trends from your latest measurements")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            IconButton(systemName: "slider.horizontal.3", size: 42) {
                showGraphSettings = true
            }
        }
    }

    private var highlights: some View {
        HStack(spacing: 10) {
            miniHighlight(icon: "heart.fill", color: Theme.accent, value: latest.map { "\($0.pulse)" } ?? "—", unit: "bpm", label: "Pulse")
            miniHighlight(icon: "waveform", color: Theme.teal, value: latest.map { Fmt.value($0.hrv) } ?? "—", unit: "ms", label: "HRV")
            miniHighlight(icon: "bolt.heart.fill", color: Theme.amber, value: latest.map { Fmt.value($0.energy) } ?? "—", unit: "%", label: "Energy")
            miniHighlight(icon: "brain.head.profile", color: Theme.orange, value: latest.map { Fmt.value($0.stress) } ?? "—", unit: "%", label: "Stress")
        }
    }

    private func miniHighlight(icon: String, color: Color, value: String, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(unit)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            dashboardCard(.healthIndex)
            dashboardCard(.hrv)
            dashboardCard(.rmssd)
            dashboardCard(.pnn50)
            energyStressCard
            dashboardCard(.sdnn)
        }
    }

    private func dashboardCard(_ metric: Metric) -> some View {
        let latestValue = latestValue(metric)
        let status = statusFor(metric: metric, value: latestValue)
        let points = points(for: metric, days: 14)
        return Button {
            selectedMetric = metric
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(metric.color)
                        .frame(width: 24, height: 24)
                        .background(metric.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text(metric.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(latestValue.map { Fmt.value($0, decimals: metric.decimals) } ?? "—")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    if latestValue != nil, !metric.unit.isEmpty {
                        Text(metric.unit)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Sparkline(values: points.map(\.value), color: metric.color)
                    .frame(height: 34)
                if let status {
                    StatusPill(status: status, compact: true)
                } else {
                    Text("No data")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 13, radius: 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var energyStressCard: some View {
        let measurements = store.measurementsInLast(days: 14)
        let energy = measurements.isEmpty ? nil : measurements.reduce(0) { $0 + $1.energy } / Double(measurements.count)
        let stress = measurements.isEmpty ? nil : measurements.reduce(0) { $0 + $1.stress } / Double(measurements.count)
        return Button {
            selectedMetric = .energy
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                        .frame(width: 24, height: 24)
                        .background(Theme.amber.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text("Energy & Stress")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(energy.map { Fmt.value($0) } ?? "—")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Energy")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.amber)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stress.map { Fmt.value($0) } ?? "—")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Stress")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.orange)
                    }
                    Spacer()
                }
                HStack(spacing: 4) {
                    BarSparkline(values: measurements.suffix(10).map(\.energy), color: Theme.amber)
                    BarSparkline(values: measurements.suffix(10).map(\.stress), color: Theme.orange)
                }
                .frame(height: 30)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(padding: 13, radius: 20)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var csiCard: some View {
        let value = Statistics.csiAverage(store.measurements)
        let status = value.map { HealthEvaluator.csi($0) }
        let days = csiDays
        return Button {
            selectedMetric = .csi
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.orange)
                            .frame(width: 32, height: 32)
                            .background(Theme.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Chronic Stress Index")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("7-day average of SI")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                HStack(alignment: .bottom, spacing: 5) {
                    Text(value.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    if let status {
                        StatusPill(status: status, compact: true)
                            .padding(.bottom, 6)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(0..<7) { index in
                            Circle()
                                .fill(index < days ? Theme.green : Theme.surfaceAlt)
                                .frame(width: 9, height: 9)
                                .overlay(
                                    Circle().strokeBorder(index < days ? Color.clear : Theme.separator, lineWidth: 0.6)
                                )
                        }
                    }
                    .padding(.bottom, 8)
                }
                if value == nil {
                    Text("Measure your heart rate for 7 days to unlock your stress baseline.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                } else if let status {
                    Text(status.interpretation)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: 8) {
                    Text("Day \(days) of 7")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text(days >= 7 ? "View Details" : "Measure Now")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
            }
            .cardSurface(padding: 16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var csiDays: Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) ?? Date()
        return Set(store.measurements.filter { $0.date >= start }.map(\.day)).count
    }

    private var heartAgeCard: some View {
        let age = Statistics.heartAge(store: store)
        let status = age.map { HealthEvaluator.heartAge($0, realAge: store.profile.age) }
        let days = min(Set(store.measurements.map(\.day)).count, 3)
        return Button {
            if store.profile.age == nil || store.profile.gender == .none {
                showProfile = true
            } else {
                selectedMetric = .heartAge
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.purple.opacity(0.12))
                    Image(systemName: "hourglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.purple)
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heart Age")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    if let age {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(age)")
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("years")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            if let status { StatusPill(status: status, compact: true) }
                        }
                    } else if store.profile.age == nil {
                        Text("Add Your Age & Gender")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text("Measure for 3 days to calculate")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    HStack(spacing: 5) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(index < days ? Theme.purple : Theme.surfaceAlt)
                                .frame(width: 24, height: 4)
                        }
                        Text("\(days)/3 days")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.leading, 2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardSurface(padding: 16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var monthlyCard: some View {
        Button {
            router.showMonthly = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.teal.opacity(0.12))
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Overview")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Calendar, daily averages and 14 metrics")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardSurface(padding: 16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Data

    private var latest: HeartRateMeasurement? { store.latestMeasurement }

    private func latestValue(_ metric: Metric) -> Double? {
        guard let latest else { return nil }
        switch metric {
        case .pulse: return Double(latest.pulse)
        case .hrv: return latest.hrv
        case .sdnn: return latest.sdnn
        case .rmssd: return latest.rmssd
        case .pnn50: return latest.pnn50
        case .energy: return latest.energy
        case .stress: return latest.stress
        case .healthIndex: return latest.healthIndex
        case .csi: return Statistics.csiAverage(store.measurements)
        case .heartAge: return Statistics.heartAge(store: store).map(Double.init)
        default: return nil
        }
    }

    private func statusFor(metric: Metric, value: Double?) -> HealthStatus? {
        guard let value else { return nil }
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
        case .heartAge: return HealthEvaluator.heartAge(Int(value), realAge: store.profile.age)
        default: return nil
        }
    }

    func points(for metric: Metric, days: Int) -> [MetricPoint] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -days + 1, to: cal.startOfDay(for: Date())) else { return [] }
        var raw: [(Date, Double)] = []
        switch metric {
        case .csi:
            let grouped = Dictionary(grouping: store.measurements.filter { $0.date >= start }) { $0.day }
            raw = grouped.map { day, items in
                (day, items.reduce(0) { $0 + Double($1.csi) } / Double(items.count))
            }
        case .heartAge:
            raw = []
        default:
            for measurement in store.measurements where measurement.date >= start {
                let value: Double?
                switch metric {
                case .pulse: value = Double(measurement.pulse)
                case .hrv: value = measurement.hrv
                case .sdnn: value = measurement.sdnn
                case .rmssd: value = measurement.rmssd
                case .pnn50: value = measurement.pnn50
                case .energy: value = measurement.energy
                case .stress: value = measurement.stress
                case .healthIndex: value = measurement.healthIndex
                default: value = nil
                }
                if let value { raw.append((measurement.date, value)) }
            }
        }
        return raw.sorted { $0.0 < $1.0 }.map { MetricPoint(date: $0.0, value: $0.1) }
    }
}

// MARK: - Metric chart

struct MetricChart: View {
    var points: [MetricPoint]
    var color: Color
    var kind: ChartKind = .line
    var showTrendLine: Bool = true
    var height: CGFloat = 160
    var showAxes: Bool = false

    var body: some View {
        if points.isEmpty {
            EmptyStateView(icon: "chart.xyaxis.line", title: "No Data", subtitle: "Take measurements to see your trends.")
                .frame(height: height)
        } else {
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    if kind.isBar {
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color.opacity(0.8))
                        .cornerRadius(3)
                    } else {
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [color.opacity(0.24), color.opacity(0.01)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
                if showTrendLine && points.count > 2 {
                    ForEach(Array(trendPoints.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(color.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1.4, dash: [4, 4]))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxis(showAxes ? .visible : .hidden)
            .chartYAxis(showAxes ? .visible : .hidden)
            .frame(height: height)
        }
    }

    private var trendPoints: [MetricPoint] {
        guard points.count >= 3 else { return [] }
        let window = 5
        return points.enumerated().compactMap { index, point in
            guard index >= window - 1 else { return nil }
            let slice = points[(index - window + 1)...index]
            let avg = slice.reduce(0) { $0 + $1.value } / Double(slice.count)
            return MetricPoint(date: point.date, value: avg)
        }
    }
}

// MARK: - Metric detail

struct MetricDetailView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var metric: Metric
    @State private var period: ChartPeriod = .week
    @State private var showSettings = false
    @AppStorage("chartKind") private var chartKindRaw = ChartKind.lineWithThresholds.rawValue
    @AppStorage("showTrendLine") private var showTrendLine = true

    private var chartKind: ChartKind { ChartKind(rawValue: chartKindRaw) ?? .line }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryCard
                periodPicker
                chartCard
                thresholdCard
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            GraphSettingsView(metric: metric)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(metric.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Compare your latest result with your average values")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            IconButton(systemName: "slider.horizontal.3", size: 36) { showSettings = true }
        }
    }

    private var summaryCard: some View {
        let value = latestValue
        let status = value.map { statusFor($0) }
        let average = points.isEmpty ? nil : points.map(\.value).reduce(0, +) / Double(points.count)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(value.map { Fmt.value($0, decimals: metric.decimals) } ?? "—")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(metric.unit)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 9)
                Spacer()
                if let status { StatusPill(status: status) }
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(period.title + " average")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text(average.map { Fmt.value($0, decimals: metric.decimals) + " " + metric.unit } ?? "No Data")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Last measurement")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text(store.latestMeasurement.map { Fmt.shortDate.string(from: $0.date) } ?? "—")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .cardSurface(padding: 18)
    }

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(ChartPeriod.allCases) { item in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { period = item }
                } label: {
                    Text(item.shortTitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(period == item ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(period == item ? Theme.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(period.title) trend")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(chartKind.title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            MetricChart(points: points, color: metric.color, kind: chartKind, showTrendLine: showTrendLine, height: 190, showAxes: true)
        }
        .cardSurface(padding: 16)
    }

    private var thresholdCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status ranges")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            ForEach(thresholdRows, id: \.0) { row in
                HStack {
                    Circle()
                        .fill(row.2)
                        .frame(width: 7, height: 7)
                    Text(row.0)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(row.1)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .cardSurface(padding: 16)
    }

    private var latestValue: Double? {
        guard let latest = store.latestMeasurement else { return nil }
        switch metric {
        case .pulse: return Double(latest.pulse)
        case .hrv: return latest.hrv
        case .sdnn: return latest.sdnn
        case .rmssd: return latest.rmssd
        case .pnn50: return latest.pnn50
        case .energy: return latest.energy
        case .stress: return latest.stress
        case .healthIndex: return latest.healthIndex
        case .csi: return Statistics.csiAverage(store.measurements)
        case .heartAge: return Statistics.heartAge(store: store).map(Double.init)
        default: return nil
        }
    }

    private var points: [MetricPoint] {
        let dashboard = DashboardView()
        return dashboard.points(for: metric, days: period.days)
    }

    private func statusFor(_ value: Double) -> HealthStatus {
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
        case .heartAge: return HealthEvaluator.heartAge(Int(value), realAge: store.profile.age)
        default: return HealthStatus(label: "—", interpretation: "", color: Theme.textTertiary)
        }
    }

    private var thresholdRows: [(String, String, Color)] {
        switch metric {
        case .pulse:
            return [("Low", "< 60 bpm", Theme.blue), ("Normal", "60–100 bpm", Theme.green), ("High", "100–120 bpm", Theme.orange), ("Very High", "> 120 bpm", Theme.accent)]
        case .rmssd:
            return [("Very Low", "< 20 ms", Theme.accent), ("Low", "20–30 ms", Theme.orange), ("Average", "30–50 ms", Theme.amber), ("Good", "50–80 ms", Theme.green), ("Excellent", "> 80 ms", Theme.teal)]
        case .pnn50:
            return [("Low", "< 10%", Theme.orange), ("Reduced", "10–20%", Theme.amber), ("Normal", "20–30%", Theme.green), ("Excellent", "> 30%", Theme.teal)]
        case .energy:
            return [("Low", "< 60%", Theme.orange), ("Average", "60–80%", Theme.amber), ("Good", "80–100%", Theme.green), ("Excellent", "> 100%", Theme.teal)]
        case .stress:
            return [("Relaxed", "0–25%", Theme.teal), ("Low", "25–35%", Theme.green), ("Average", "35–70%", Theme.amber), ("High", "70–80%", Theme.orange), ("Very High", "80–100%", Theme.accent)]
        case .healthIndex:
            return [("Low", "< 3.5", Theme.orange), ("Average", "3.5–4.5", Theme.amber), ("Good", "4.5–5.5", Theme.green), ("Excellent", "5.5–6.5", Theme.teal), ("Athlete", "> 6.5", Theme.purple)]
        case .csi:
            return [("Low Stress", "< 50", Theme.blue), ("Normal", "50–149", Theme.green), ("Elevated", "150–299", Theme.amber), ("High", "300–499", Theme.orange), ("Very High", "> 500", Theme.accent)]
        case .heartAge:
            return [("Good", "below your age", Theme.green), ("Equal", "matches your age", Theme.amber), ("High", "above your age", Theme.orange)]
        default:
            return [("Low", "< 50 ms", Theme.orange), ("Normal", "50–100 ms", Theme.green), ("High", "> 100 ms", Theme.teal)]
        }
    }
}

// MARK: - Graph settings

struct GraphSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var metric: Metric?

    @AppStorage("chartKind") private var chartKindRaw = ChartKind.lineWithThresholds.rawValue
    @AppStorage("showTrendLine") private var showTrendLine = true
    @AppStorage("showThresholds") private var showThresholds = true
    @AppStorage("defaultPeriod") private var defaultPeriodRaw = ChartPeriod.week.rawValue

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chart Type")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        VStack(spacing: 8) {
                            ForEach(ChartKind.allCases) { kind in
                                Button {
                                    chartKindRaw = kind.rawValue
                                    showThresholds = kind.showsThresholds
                                } label: {
                                    HStack {
                                        Image(systemName: kind.isBar ? "chart.bar.fill" : "chart.line.uptrend.xyaxis")
                                            .foregroundStyle(kind == currentKind ? Theme.accent : Theme.textSecondary)
                                        Text(kind.title)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Theme.textPrimary)
                                        Spacer()
                                        Image(systemName: kind == currentKind ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(kind == currentKind ? Theme.accent : Theme.separator)
                                    }
                                    .padding(13)
                                    .background(Theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Time Range")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 6) {
                            ForEach(ChartPeriod.allCases) { period in
                                Button {
                                    defaultPeriodRaw = period.rawValue
                                } label: {
                                    Text(period.shortTitle)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(defaultPeriod == period ? .white : Theme.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(defaultPeriod == period ? Theme.accent : Theme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }
                    Toggle(isOn: $showTrendLine) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Trend Line")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text("A smoothed moving average of your data")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .tint(Theme.accent)
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Toggle(isOn: $showThresholds) {
                        Text("Show Thresholds")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .tint(Theme.accent)
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Chart Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        chartKindRaw = ChartKind.lineWithThresholds.rawValue
                        showTrendLine = true
                        showThresholds = true
                        defaultPeriodRaw = ChartPeriod.week.rawValue
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var currentKind: ChartKind { ChartKind(rawValue: chartKindRaw) ?? .line }
    private var defaultPeriod: ChartPeriod { ChartPeriod(rawValue: defaultPeriodRaw) ?? .week }

    private var preview: some View {
        let chosenMetric = metric ?? .healthIndex
        let dashboard = DashboardView()
        let points = dashboard.points(for: chosenMetric, days: 14)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            MetricChart(points: points, color: chosenMetric.color, kind: currentKind, showTrendLine: showTrendLine, height: 120)
            Text("Settings apply to all charts and are saved on this device.")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardSurface(padding: 14)
    }
}
