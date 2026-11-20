import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter

    @State private var selectedDay = Date()
    @State private var carouselPage = 0
    @State private var measurementIndex = 0
    @State private var detailMeasurement: HeartRateMeasurement?
    @State private var logSheet: LogSheet?
    @State private var infoSheet: HomeInfo?

    private let carouselTimer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                weekStrip
                carousel
                measurementsSection
                journeyCard
                if !store.isPremium { proBanner }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(carouselTimer) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                carouselPage = (carouselPage + 1) % 4
            }
        }
        .sheet(item: $detailMeasurement) { measurement in
            NavigationStack {
                MeasurementDetailView(measurement: measurement, isFresh: false)
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(item: $logSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .pressure: PressureLogEditor(existing: nil)
                case .glucose: GlucoseLogEditor(existing: nil)
                case .oxygen: OxygenLogEditor(existing: nil)
                }
            }
            .environmentObject(store)
            .environmentObject(router)
        }
        .sheet(item: $infoSheet) { info in
            HomeInfoSheet(info: info)
                .environmentObject(store)
                .environmentObject(router)
        }
        .onChange(of: selectedDay) { _, _ in measurementIndex = 0 }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(dayTitle)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(Fmt.shortDate.string(from: selectedDay))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(Fmt.longDate.string(from: selectedDay))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 9) {
                Button {
                    router.selectedTab = .me
                } label: {
                    AvatarView(profile: store.profile, size: 42)
                }
                .buttonStyle(ScaleButtonStyle())
                IconButton(systemName: "gearshape.fill", size: 42, identifier: "home.settings") {
                    router.showSettings = true
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = store.profile.name.isEmpty ? "" : ", \(store.profile.name)"
        switch hour {
        case ..<12: return "Good morning\(name)"
        case ..<18: return "Good afternoon\(name)"
        default: return "Good evening\(name)"
        }
    }

    private var dayTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDay) { return "Today" }
        if cal.isDateInYesterday(selectedDay) { return "Yesterday" }
        if cal.isDateInTomorrow(selectedDay) { return "Tomorrow" }
        return Fmt.weekdayShort.string(from: selectedDay)
    }

    // MARK: Week strip

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { day in
                let selected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { selectedDay = day }
                } label: {
                    VStack(spacing: 7) {
                        Text(Fmt.weekdayLetter.string(from: day).uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(selected ? .white.opacity(0.8) : Theme.textTertiary)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(selected ? .white : Theme.textPrimary)
                        Circle()
                            .fill(selected ? Color.white : (hasMeasurements(day) ? Theme.accent : Color.clear))
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(selected ? Theme.accent : Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(selected ? Color.clear : Theme.separator.opacity(0.7), lineWidth: 0.8))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private var weekDays: [Date] {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: selectedDay)?.start ?? selectedDay
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func hasMeasurements(_ day: Date) -> Bool {
        !store.measurements(on: day).isEmpty
    }

    // MARK: Carousel

    private var carousel: some View {
        VStack(spacing: 12) {
            TabView(selection: $carouselPage) {
                carouselHeartRate.tag(0)
                carouselCSI.tag(1)
                carouselHeartAge.tag(2)
                carouselPromo.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 188)

            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    Capsule()
                        .fill(index == carouselPage ? Theme.accent : Theme.separator)
                        .frame(height: 4)
                        .overlay(alignment: .leading) {
                            if index == carouselPage {
                                Capsule().fill(Theme.accent.opacity(0.4))
                            }
                        }
                }
            }
        }
    }

    private var carouselHeartRate: some View {
        Button {
            infoSheet = .heartRate
        } label: {
            CarouselCard(
                eyebrow: "LIVE PULSE",
                title: latestToday.map { "\($0.pulse) bpm" } ?? "Take a measurement",
                subtitle: latestToday.map { HealthEvaluator.pulse($0.pulse).interpretation } ?? "Your heart rate in seconds",
                symbol: "heart.fill",
                gradient: Theme.heartGradient,
                footer: latestToday.map { Fmt.time.string(from: $0.date) } ?? "Tap to measure"
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var carouselCSI: some View {
        Button {
            infoSheet = .csi
        } label: {
            CarouselCard(
                eyebrow: "CHRONIC STRESS INDEX",
                title: csiValue.map { "\(Int($0.rounded()))" } ?? "—",
                subtitle: csiValue.map { HealthEvaluator.csi($0).interpretation } ?? "Measure for 7 days to unlock",
                symbol: "brain.head.profile",
                gradient: Theme.calmGradient,
                footer: csiValue.map { HealthEvaluator.csi($0).label } ?? "Day 1 of 7"
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var carouselHeartAge: some View {
        Button {
            infoSheet = .heartAge
        } label: {
            CarouselCard(
                eyebrow: "HEART AGE",
                title: heartAge.map { "\($0)" } ?? "—",
                subtitle: heartAge.map { _ in "years" } ?? "Measure for 3 days to learn",
                symbol: "hourglass",
                gradient: Theme.duskGradient,
                footer: heartAge == nil ? "Add age & gender" : "Updated today"
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var carouselPromo: some View {
        Button {
            router.openPaywall("home_banner")
        } label: {
            CarouselCard(
                eyebrow: store.isPremium ? "PREMIUM ACTIVE" : "HEARTICA PREMIUM",
                title: store.isPremium ? "You're all set" : "Go Premium",
                subtitle: store.isPremium ? "Every feature is unlocked" : "Access all features without limits",
                symbol: "crown.fill",
                gradient: Theme.goldGradient,
                footer: store.isPremium ? "Thank you for your support" : "Try for Free"
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var latestToday: HeartRateMeasurement? {
        let items = store.measurements(on: selectedDay)
        guard !items.isEmpty else { return nil }
        return items[min(measurementIndex, items.count - 1)]
    }

    private var csiValue: Double? {
        Statistics.csiAverage(store.measurements)
    }

    private var heartAge: Int? {
        Statistics.heartAge(store: store)
    }

    // MARK: Measurements

    private var measurementsSection: some View {
        VStack(spacing: 12) {
            SectionHeading(title: "Measurements", actionTitle: "History", actionIdentifier: "home.history") {
                router.showHistory = true
            }
            heartRateCard
            pressureCard
            HStack(spacing: 12) {
                oxygenCard
                glucoseCard
            }
        }
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(icon: "heart.fill", title: "Heart Rate", color: Theme.accent, trailing: {
                if latestToday != nil {
                    StatusPill(status: HealthEvaluator.pulse(latestToday?.pulse ?? 0))
                } else {
                    EmptyView()
                }
            })
            if let measurement = latestToday {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(measurement.pulse)")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("bpm")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        HStack(spacing: 6) {
                            Text(HealthEvaluator.pulse(measurement.pulse).interpretation)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            if store.measurements(on: selectedDay).count > 1 {
                                Text("\(measurementIndex + 1)/\(store.measurements(on: selectedDay).count)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Sparkline(values: pulseSeries, color: Theme.accent)
                        .frame(width: 120, height: 54)
                }
                if store.measurements(on: selectedDay).count > 1 {
                    HStack(spacing: 6) {
                        ForEach(Array(store.measurements(on: selectedDay).enumerated()), id: \.offset) { index, _ in
                            Capsule()
                                .fill(index == measurementIndex ? Theme.accent : Theme.separator)
                                .frame(width: index == measurementIndex ? 16 : 6, height: 5)
                        }
                        Spacer()
                        Button {
                            measurementIndex = max(measurementIndex - 1, 0)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(measurementIndex == 0)
                        Button {
                            measurementIndex = min(measurementIndex + 1, store.measurements(on: selectedDay).count - 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(measurementIndex >= store.measurements(on: selectedDay).count - 1)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                }
                HStack(spacing: 8) {
                    Button {
                        detailMeasurement = measurement
                    } label: {
                        Text("Details")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        router.showMeasure = true
                    } label: {
                        Label("Measure", systemImage: "plus")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .accessibilityIdentifier("home.heart.actions")
            } else {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.accentSoft)
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Theme.accent.opacity(0.7))
                    }
                    .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Take a measurement\nto see it here")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text("No Data")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Button {
                        router.showMeasure = true
                    } label: {
                        Text("Measure")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .cardSurface(padding: 16)
    }

    private var pulseSeries: [Double] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: selectedDay)) ?? selectedDay
        return (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let items = store.measurements(on: day)
            guard !items.isEmpty else { return nil }
            return Double(items.map(\.pulse).reduce(0, +)) / Double(items.count)
        }
    }

    private var pressureCard: some View {
        let latest = store.pressureLogs.first
        return VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "gauge.with.dots.needle.50percent", title: "Pressure", color: Theme.blue, trailing: {
                if let latest { StatusPill(status: HealthEvaluator.pressure(sys: latest.sys, dia: latest.dia), compact: true) } else { EmptyView() }
            })
            if let latest {
                HStack(alignment: .bottom, spacing: 18) {
                    valueBlock(value: "\(latest.sys)", unit: "SYS", label: "mmHg")
                    valueBlock(value: "\(latest.dia)", unit: "DIA", label: "mmHg")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(Fmt.relativeDay(latest.date))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text(Fmt.time.string(from: latest.date))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                HStack {
                    Text(HealthEvaluator.pressure(sys: latest.sys, dia: latest.dia).interpretation)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button { logSheet = .pressure } label: {
                        Label("Log", systemImage: "plus")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.blue)
                    }
                }
            } else {
                emptyLogRow(icon: "waveform.path.ecg", color: Theme.blue, text: "Log your blood pressure to see it here", action: "Log Pressure") {
                    logSheet = .pressure
                }
            }
        }
        .cardSurface(padding: 16)
    }

    private var oxygenCard: some View {
        let latest = store.oxygenLogs.first
        return VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "lungs.fill", title: "Oxygen", color: Theme.purple)
            if let latest {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(latest.value)%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(HealthEvaluator.oxygen(latest.value).label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(HealthEvaluator.oxygen(latest.value).color)
                }
                Button { logSheet = .oxygen } label: {
                    Text("Log Oxygen")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.purple)
                }
            } else {
                emptyLogRow(icon: "lungs.fill", color: Theme.purple, text: "Log your oxygen", action: "Log") { logSheet = .oxygen }
            }
        }
        .cardSurface(padding: 14)
    }

    private var glucoseCard: some View {
        let latest = store.glucoseLogs.first
        return VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "drop.fill", title: "Glucose", color: Theme.pink)
            if let latest {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Int(latest.valueMgdl))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("mg/dL · \(store.tag(id: latest.tagID)?.name ?? "—")")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Button { logSheet = .glucose } label: {
                    Text("Log Glucose")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.pink)
                }
            } else {
                emptyLogRow(icon: "drop.fill", color: Theme.pink, text: "Log your glucose", action: "Log") { logSheet = .glucose }
            }
        }
        .cardSurface(padding: 14)
    }

    private func cardHeader(icon: String, title: String, color: Color) -> some View {
        cardHeader(icon: icon, title: title, color: color) { EmptyView() }
    }

    private func cardHeader<Trailing: View>(icon: String, title: String, color: Color, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            trailing()
        }
    }

    private func valueBlock(value: String, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func emptyLogRow(icon: String, color: Color, text: String, action: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
            Spacer(minLength: 4)
            Button(action: onTap) {
                Text(action)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(color)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: Journey + banner

    private var journeyCard: some View {
        let current = JourneyEngine.currentLevel(store: store)
        let progress = current.map { Double(JourneyEngine.completedCoreCount($0, store: store)) / Double(max($0.coreTasks.count, 1)) } ?? 1
        return Button {
            router.showJourney = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.teal.opacity(0.12))
                    Image(systemName: "map.fill")
                        .foregroundStyle(Theme.teal)
                }
                .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(current.map { "Level \($0.number)" } ?? "Journey complete")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("My Journey")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    ProgressBarView(progress: progress, color: Theme.teal, height: 5)
                    Text(current.map { "\(JourneyEngine.completedCoreCount($0, store: store)) of \($0.coreTasks.count) main tasks" } ?? "All chapters completed")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("home.journey")
    }

    private var proBanner: some View {
        Button {
            router.openPaywall("home_banner")
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Go Premium")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Access all features without limits")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Text("Try for Free")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Theme.duskGradient)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("home.premium")
    }
}

// MARK: - Supporting views

struct AvatarView: View {
    var profile: Profile
    var size: CGFloat = 44
    var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [Theme.accent.opacity(0.22), Theme.purple.opacity(0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(profile.initials)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Theme.surface, lineWidth: 2))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

struct CarouselCard: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var symbol: String
    var gradient: LinearGradient
    var footer: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(gradient)
            GeometryReader { proxy in
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 150 + CGFloat(index) * 74, height: 150 + CGFloat(index) * 74)
                        .position(x: proxy.size.width - 40 + CGFloat(index) * 38, y: 20 - CGFloat(index) * 32)
                }
            }
            .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(eyebrow)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Text(title)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                HStack {
                    Text(footer)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.top, 2)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.primaryColor(for: 0).opacity(0.16), radius: 18, y: 10)
    }
}

enum HomeInfo: String, Identifiable {
    case heartRate, csi, heartAge
    var id: String { rawValue }
}

struct HomeInfoSheet: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    var info: HomeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                IconButton(systemName: "xmark", size: 36) { dismiss() }
            }
            .padding(.top, 22)

            if info == .heartRate {
                metricHero(value: latest.map { "\($0.pulse)" } ?? "—", unit: "bpm",
                           status: latest.map { HealthEvaluator.pulse($0.pulse).label } ?? "No Data",
                           text: "Your pulse reflects how fast your heart is beating. Measure while resting for the most comparable readings.")
            } else if info == .csi {
                metricHero(value: csi.map { "\(Int($0.rounded()))" } ?? "—", unit: "",
                           status: csi.map { HealthEvaluator.csi($0).label } ?? "Day 1",
                           text: "The Chronic Stress Index is the 7-day average of Stress Index (SI) measures. Keep measuring daily to unlock your baseline.")
            } else {
                metricHero(value: heartAge.map(String.init) ?? "—", unit: "years",
                           status: heartAge == nil ? "Add age & gender" : "Heart Age",
                           text: "Heart Age is estimated from your average RMSSD over recent measurements and your profile. Measure for 3 days to calculate it.")
            }

            VStack(alignment: .leading, spacing: 10) {
                infoRow("How it is calculated", detail: info == .heartRate ? "Pulse is taken from the measured NN intervals." : (info == .csi ? "Average SI over the last 7 days, split into five status bands." : "A simplified linear model using average RMSSD, age and gender."))
                infoRow("What can change it", detail: "Sleep, activity, stress, hydration, caffeine and the time of day.")
                infoRow("Keep in mind", detail: "Measurements are for wellness insight, not diagnosis.")
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))

            Spacer()
            Button {
                dismiss()
                if info == .heartRate {
                    router.showMeasure = true
                } else {
                    router.selectedTab = .dashboard
                }
            } label: {
                Text(info == .heartRate ? "Measure Now" : "View Dashboard")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .background(Theme.background.ignoresSafeArea())
    }

    private var title: String {
        switch info {
        case .heartRate: return "Pulse"
        case .csi: return "Chronic Stress Index"
        case .heartAge: return "Heart Age"
        }
    }

    private var latest: HeartRateMeasurement? { store.latestMeasurement }
    private var csi: Double? { Statistics.csiAverage(store.measurements) }
    private var heartAge: Int? { Statistics.heartAge(store: store) }

    private func metricHero(value: String, unit: String, status: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(status)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accentSoft)
                    .clipShape(Capsule())
            }
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private func infoRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(detail)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum LogSheet: String, Identifiable {
    case pressure, glucose, oxygen
    var id: String { rawValue }
}
