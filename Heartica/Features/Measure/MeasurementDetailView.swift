import SwiftUI

struct MeasurementDetailView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var measurement: HeartRateMeasurement
    var isFresh: Bool = false
    var onRetake: (() -> Void)?
    var onDone: (() -> Void)?

    @State private var showTagPicker = false
    @State private var showDeleteConfirm = false
    @State private var showShare = false

    private var current: HeartRateMeasurement {
        store.measurements.first(where: { $0.id == measurement.id }) ?? measurement
    }

    private var tag: TagDefinition? { store.tag(id: current.tagID) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                heroCard
                aiCard
                metricsGrid
                smartComment
                tagSection
                actions
                disclaimer
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selection: Binding(
                get: { current.tagID },
                set: { newValue in
                    var updated = current
                    updated.tagID = newValue
                    store.updateMeasurement(updated)
                }
            ))
            .environmentObject(store)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [
                "I just measured \(current.pulse) bpm with Heartica. Heart health, one beat at a time.",
                URL(string: "https://apps.apple.com/us/app/6742904990")!
            ])
        }
        .alert("Delete this measurement?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteMeasurement(id: current.id)
                close()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            if isFresh {
                Text("Measurement")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    showShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                if !isFresh {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Measurement", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        let pulseStatus = HealthEvaluator.pulse(current.pulse)
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isFresh ? "Measurement Complete" : "Measurement Details")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.accent)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: current.source == .appleWatch ? "applewatch" : "iphone")
                    Text(current.source.shortTitle)
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.surfaceAlt)
                .clipShape(Capsule())
            }
            HStack(alignment: .bottom, spacing: 6) {
                Text("\(current.pulse)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("bpm")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 12)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatusPill(status: pulseStatus)
                    Text(pulseStatus.interpretation)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.bottom, 8)
            }
            RangeBar(value: Double(current.pulse), min: 40, max: 140, color: pulseStatus.color)
            HStack {
                Label(Fmt.dateTime.string(from: current.date), systemImage: "clock")
                Spacer()
                Text(tag?.name ?? "Untagged")
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.textTertiary)
        }
        .cardSurface(padding: 18)
    }

    // MARK: AI

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.purple)
                Text("AI Comment")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("Overall Health State")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: overallSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(overallStatus.color)
                    .frame(width: 46, height: 46)
                    .background(overallStatus.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(overallStatus.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(overallText)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("The analysis uses artificial intelligence and is provided solely for informational and educational purposes.")
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardSurface(padding: 16)
    }

    private var overallStatus: HealthStatus { HealthEvaluator.healthIndex(current.healthIndex) }

    private var overallSymbol: String {
        switch current.healthIndex {
        case ..<3.5: return "battery.25"
        case 3.5..<4.5: return "battery.50"
        case 4.5..<5.5: return "battery.75"
        default: return "battery.100"
        }
    }

    private var overallText: String {
        switch current.healthIndex {
        case ..<3.5:
            return "Your HRV is running low. Your body may be under load, so prioritize sleep, hydration and a calmer pace today."
        case 3.5..<4.5:
            return "Your recovery looks moderate. A short walk, steady meals and an earlier bedtime can help your system settle."
        case 4.5..<5.5:
            return "Your autonomic balance looks healthy. Your body is handling the current load well — keep the routine that works."
        default:
            return "Your recovery signals are strong. Your parasympathetic system is doing its job, so this is a good day to build on good habits."
        }
    }

    // MARK: Metrics

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            metricCard(title: "HRV", value: Fmt.value(current.hrv), unit: "ms", status: HealthEvaluator.hrv(current.hrv), icon: "waveform", color: Theme.teal)
            metricCard(title: "RMSSD", value: Fmt.value(current.rmssd), unit: "ms", status: HealthEvaluator.rmssd(current.rmssd), icon: "waveform.path", color: Theme.blue)
            metricCard(title: "SDNN", value: Fmt.value(current.sdnn), unit: "ms", status: HealthEvaluator.sdnn(current.sdnn), icon: "waveform.path.ecg", color: Theme.purple)
            metricCard(title: "pNN50", value: Fmt.value(current.pnn50), unit: "%", status: HealthEvaluator.pnn50(current.pnn50), icon: "percent", color: Theme.pink)
            metricCard(title: "Energy", value: Fmt.value(current.energy), unit: "%", status: HealthEvaluator.energy(current.energy), icon: "bolt.heart.fill", color: Theme.amber)
            metricCard(title: "Stress", value: Fmt.value(current.stress), unit: "%", status: HealthEvaluator.stress(current.stress), icon: "brain.head.profile", color: Theme.orange)
            metricCard(title: "Health Index", value: Fmt.value(current.healthIndex), unit: "", status: HealthEvaluator.healthIndex(current.healthIndex), icon: "heart.text.square.fill", color: Theme.accent)
            heartAgeCard
        }
    }

    private func metricCard(title: String, value: String, unit: String, status: HealthStatus, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            StatusPill(status: status, compact: true)
            Text(status.interpretation)
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(2)
                .frame(minHeight: 22, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 12, radius: 18)
    }

    private var heartAgeCard: some View {
        let age = Statistics.heartAge(store: store)
        let status = HealthEvaluator.heartAge(age ?? 0, realAge: store.profile.age)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.purple)
                    .frame(width: 24, height: 24)
                    .background(Theme.purple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text("Heart Age")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(age.map(String.init) ?? "—")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("years")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            StatusPill(status: status, compact: true)
            Text(status.interpretation)
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(2)
                .frame(minHeight: 22, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 12, radius: 18)
    }

    // MARK: Smart comment

    private var smartComment: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Smart Comment")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("PERSONALIZED")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.teal)
            }
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Theme.teal)
                    .frame(width: 5, height: 5)
                    .padding(.top, 6)
                Text(partA + " " + partB)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardSurface(padding: 16)
    }

    private var partA: String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: current.date) ?? current.date
        let baselineItems = store.measurements.filter { $0.date < current.date && $0.date >= cutoff && $0.id != current.id }
        guard !baselineItems.isEmpty else {
            return "This is one of your first measurements, so we're still learning your baseline."
        }
        let baseline = baselineItems.reduce(0) { $0 + $1.healthIndex } / Double(baselineItems.count)
        if current.healthIndex < baseline - 0.25 {
            return "Your recovery signal is below your 7-day baseline, which can happen after poor sleep, stress or intense activity."
        } else if current.healthIndex > baseline + 0.25 {
            return "Your recovery signal is above your 7-day baseline — a sign your body is responding well to recent rest."
        }
        return "Your recovery signal is within your personal 7-day range."
    }

    private var partB: String {
        let sorted = store.measurements.sorted { $0.date < $1.date }
        guard let index = sorted.firstIndex(where: { $0.id == current.id }), index > 0 else {
            return "Keep measuring at a similar time to make the next comparison more meaningful."
        }
        let previous = sorted[index - 1]
        let delta = current.healthIndex - previous.healthIndex
        let context = store.tag(id: current.tagID)?.name.lowercased()
        let contextText: String
        if let context {
            if context.contains("sleep") {
                contextText = "around sleep, which is a useful anchor for your recovery pattern."
            } else if context.contains("exercise") || context.contains("activity") {
                contextText = "after exercise, so a temporary shift is expected as your body recovers."
            } else if context.contains("stress") {
                contextText = "during a stress context — breathing and a short pause can help you return to baseline."
            } else if context.contains("meditation") || context.contains("relax") {
                contextText = "around a relaxation session, a good moment to notice how quickly you settle."
            } else {
                contextText = "with useful context attached."
            }
        } else {
            contextText = "without a tag, so adding context next time will make this more useful."
        }
        if delta > 0.2 {
            return "Compared with your previous reading, your recovery has improved \(contextText)"
        } else if delta < -0.2 {
            return "Compared with your previous reading, your recovery is a little lower \(contextText)"
        }
        return "Compared with your previous reading, your recovery is stable \(contextText)"
    }

    // MARK: Tags & actions

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Context Tag")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(tag == nil ? "Add a Tag" : "Change") {
                    showTagPicker = true
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.accent)
            }
            if let tag {
                HStack(spacing: 8) {
                    TagChip(tag: tag, selected: true)
                    Text("Tagging helps you compare similar moments.")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            } else {
                Text("Add what was happening around this measurement — sleep, exercise, stress or food.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardSurface(padding: 16)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if isFresh {
                Button {
                    close()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button {
                    if let onRetake {
                        onRetake()
                    } else {
                        close()
                    }
                } label: {
                    Text("Retake")
                }
                .buttonStyle(SoftButtonStyle())
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                }
                .buttonStyle(PrimaryButtonStyle())
                if !isFresh {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Measurement")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private func close() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }

    private var disclaimer: some View {
        Text("Heartica is not a medical device and does not provide medical advice. If you feel unwell or your numbers change suddenly, talk to a healthcare professional.")
            .font(.system(size: 9, weight: .regular, design: .rounded))
            .foregroundStyle(Theme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }
}

struct RangeBar: View {
    var value: Double
    var min: Double
    var max: Double
    var color: Color

    var body: some View {
        GeometryReader { proxy in
            let fraction = CGFloat(clamp((value - min) / (max - min), 0, 1))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.surfaceAlt)
                Capsule()
                    .fill(
                        LinearGradient(colors: [Theme.teal.opacity(0.6), Theme.amber.opacity(0.7), Theme.accent.opacity(0.7)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: proxy.size.width * 0.7)
                Circle()
                    .fill(color)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .offset(x: proxy.size.width * fraction - 5.5)
            }
        }
        .frame(height: 11)
    }
}

struct TagPickerSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: String?

    @State private var showCreate = false
    @State private var newName = ""
    @State private var newColor: TagColor = .green
    @State private var newCluster: TagCluster = .general

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Button {
                        selection = nil
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "circle.slash")
                                .foregroundStyle(Theme.textSecondary)
                            Text("No Tag")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if selection == nil {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(14)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    ForEach(TagCatalog.allClusters) { cluster in
                        let tags = store.allTags.filter { $0.cluster == cluster }
                        if !tags.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Circle().fill(tags.first?.color.color ?? Theme.accent).frame(width: 6, height: 6)
                                    Text(cluster.title)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .tracking(1)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                FlowLayout(spacing: 8, lineSpacing: 8) {
                                    ForEach(tags) { tag in
                                        Button {
                                            selection = tag.id
                                            dismiss()
                                        } label: {
                                            TagChip(tag: tag, selected: selection == tag.id)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    if !store.customTags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CUSTOM TAGS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(Theme.textSecondary)
                            FlowLayout(spacing: 8, lineSpacing: 8) {
                                ForEach(store.customTags) { tag in
                                    Button {
                                        selection = tag.id
                                        dismiss()
                                    } label: {
                                        TagChip(tag: tag, selected: selection == tag.id)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Button {
                        showCreate = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Create a Custom Tag")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreate) {
                createSheet
                    .presentationDetents([.medium])
            }
        }
    }

    private var createSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Custom Tag")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 22)
            TextField("Tag name", text: $newName)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(14)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack(spacing: 12) {
                ForEach(TagColor.allCases) { color in
                    Button {
                        newColor = color
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().strokeBorder(.white, lineWidth: newColor == color ? 3 : 0))
                            .overlay(Circle().strokeBorder(color.color.opacity(0.4), lineWidth: newColor == color ? 6 : 0))
                    }
                }
            }
            Menu {
                ForEach(TagCluster.allCases.filter { $0 != .general }) { cluster in
                    Button(cluster.title) { newCluster = cluster }
                }
            } label: {
                HStack {
                    Text("Cluster: \(newCluster.title)")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Spacer()
            Button {
                let cleaned = newName.trimmingCharacters(in: .whitespaces)
                guard !cleaned.isEmpty else { return }
                let tag = TagDefinition(id: "custom-\(UUID().uuidString)", name: cleaned, cluster: newCluster, color: newColor, isCustom: true)
                store.addCustomTag(tag)
                selection = tag.id
                showCreate = false
                dismiss()
            } label: {
                Text("Save Tag")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(newName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 22)
        .background(Theme.background.ignoresSafeArea())
    }
}
