import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var month = Calendar.current.startOfMonth(for: Date())
    @State private var selectedMeasurement: HeartRateMeasurement?
    @State private var pressureEdit: PressureLog?
    @State private var glucoseEdit: GlucoseLog?
    @State private var oxygenEdit: OxygenLog?
    @State private var createLog: LogSheet?
    @State private var deleteEntry: HistoryEntry?
    @State private var showAddMenu = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                monthSelector
                if groupedEntries.isEmpty {
                    EmptyStateView(icon: "calendar.badge.plus", title: "No Records Yet",
                                   subtitle: "Start by adding your first measurement.",
                                   actionTitle: "Add a Measurement") { showAddMenu = true }
                        .padding(.top, 36)
                } else {
                    ForEach(groupedEntries) { group in
                        daySection(day: group.day, entries: group.entries)
                    }
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedMeasurement) { measurement in
            NavigationStack {
                MeasurementDetailView(measurement: measurement, isFresh: false)
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(item: $pressureEdit) { log in
            NavigationStack { PressureLogEditor(existing: log).environmentObject(store).environmentObject(router) }
        }
        .sheet(item: $glucoseEdit) { log in
            NavigationStack { GlucoseLogEditor(existing: log).environmentObject(store).environmentObject(router) }
        }
        .sheet(item: $oxygenEdit) { log in
            NavigationStack { OxygenLogEditor(existing: log).environmentObject(store).environmentObject(router) }
        }
        .sheet(item: $createLog) { type in
            NavigationStack {
                switch type {
                case .pressure: PressureLogEditor(existing: nil)
                case .glucose: GlucoseLogEditor(existing: nil)
                case .oxygen: OxygenLogEditor(existing: nil)
                }
            }
            .environmentObject(store)
            .environmentObject(router)
        }
        .confirmationDialog("Add a Measurement", isPresented: $showAddMenu, titleVisibility: .visible) {
            Button("Measure Heart Rate") { beginMeasure() }
            Button("Log Pressure") { createLog = .pressure }
            Button("Log Glucose") { createLog = .glucose }
            Button("Log Oxygen") { createLog = .oxygen }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete this record?", isPresented: Binding(get: { deleteEntry != nil }, set: { if !$0 { deleteEntry = nil } })) {
            Button("Cancel", role: .cancel) { deleteEntry = nil }
            Button("Delete", role: .destructive) {
                if let entry = deleteEntry { delete(entry) }
                deleteEntry = nil
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("History")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Every measurement, in one place")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Menu {
                Button {
                    beginMeasure()
                } label: {
                    Label("Measure Heart Rate", systemImage: "heart.fill")
                }
                Button { createLog = .pressure } label: {
                    Label("Log Pressure", systemImage: "waveform.path.ecg")
                }
                Button { createLog = .glucose } label: {
                    Label("Log Glucose", systemImage: "drop.fill")
                }
                Button { createLog = .oxygen } label: {
                    Label("Log Oxygen", systemImage: "lungs.fill")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Theme.accent)
                    .clipShape(Circle())
            }
        }
    }

    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation { month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            Spacer()
            Text(Fmt.monthTitle.string(from: month))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button {
                withAnimation { month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(canGoForward ? Theme.textSecondary : Theme.textTertiary.opacity(0.4))
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            .disabled(!canGoForward)
        }
    }

    private var canGoForward: Bool {
        let current = Calendar.current.startOfMonth(for: Date())
        return month < current
    }

    private func daySection(day: Date, entries: [HistoryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Fmt.relativeDay(day))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(Fmt.weekdayShort.string(from: day) + ", " + Fmt.shortDate.string(from: day))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(entries.count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 18, height: 18)
                    .background(Theme.surfaceAlt)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 4)
            VStack(spacing: 1) {
                ForEach(entries) { entry in
                    entryRow(entry)
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        }
    }

    private func entryRow(_ entry: HistoryEntry) -> some View {
        Button {
            switch entry.type {
            case .heartRate:
                selectedMeasurement = store.measurements.first { $0.id.uuidString == entry.id }
            case .pressure:
                pressureEdit = store.pressureLogs.first { $0.id.uuidString == entry.id }
            case .glucose:
                glucoseEdit = store.glucoseLogs.first { $0.id.uuidString == entry.id }
            case .oxygen:
                oxygenEdit = store.oxygenLogs.first { $0.id.uuidString == entry.id }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: entry.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(entry.color)
                    .frame(width: 34, height: 34)
                    .background(entry.color.opacity(0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        if let tag = store.tag(id: entry.tagID) {
                            Text(tag.name)
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(tag.color.color)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(tag.color.softColor)
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 4) {
                        Text(Fmt.time.string(from: entry.date))
                        if entry.source == .appleWatch {
                            Image(systemName: "applewatch")
                        }
                    }
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(entry.status)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(entry.statusColor)
                }
                Menu {
                    Button {
                        switch entry.type {
                        case .heartRate: selectedMeasurement = store.measurements.first { $0.id.uuidString == entry.id }
                        case .pressure: pressureEdit = store.pressureLogs.first { $0.id.uuidString == entry.id }
                        case .glucose: glucoseEdit = store.glucoseLogs.first { $0.id.uuidString == entry.id }
                        case .oxygen: oxygenEdit = store.oxygenLogs.first { $0.id.uuidString == entry.id }
                        }
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deleteEntry = entry
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 22, height: 28)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private var groupedEntries: [HistoryDayGroup] {
        let cal = Calendar.current
        let entries = monthEntries
        let grouped = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }.map {
            HistoryDayGroup(day: $0.key, entries: $0.value.sorted { $0.date > $1.date })
        }
    }

    private var monthEntries: [HistoryEntry] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        var entries: [HistoryEntry] = []
        for measurement in store.measurements where interval.contains(measurement.date) {
            let status = HealthEvaluator.pulse(measurement.pulse)
            entries.append(HistoryEntry(
                id: measurement.id.uuidString,
                type: .heartRate,
                date: measurement.date,
                title: "Heart Rate",
                value: "\(measurement.pulse) bpm",
                status: status.label,
                statusColor: status.color,
                icon: "heart.fill",
                color: Theme.accent,
                tagID: measurement.tagID,
                source: measurement.source
            ))
        }
        for log in store.pressureLogs where interval.contains(log.date) {
            let status = HealthEvaluator.pressure(sys: log.sys, dia: log.dia)
            entries.append(HistoryEntry(
                id: log.id.uuidString,
                type: .pressure,
                date: log.date,
                title: "Blood Pressure",
                value: "\(log.sys)/\(log.dia)",
                status: status.label,
                statusColor: status.color,
                icon: "waveform.path.ecg",
                color: Theme.blue,
                tagID: log.tagID,
                source: .inApp
            ))
        }
        for log in store.glucoseLogs where interval.contains(log.date) {
            let afterMeal = log.tagID == "eating-after"
            let status = HealthEvaluator.glucose(log.valueMgdl, afterMeal: afterMeal)
            entries.append(HistoryEntry(
                id: log.id.uuidString,
                type: .glucose,
                date: log.date,
                title: afterMeal ? "Glucose · After Meal" : "Glucose · Before Meal",
                value: "\(Int(log.valueMgdl)) mg/dL",
                status: status.label,
                statusColor: status.color,
                icon: "drop.fill",
                color: Theme.pink,
                tagID: log.tagID,
                source: .inApp
            ))
        }
        for log in store.oxygenLogs where interval.contains(log.date) {
            let status = HealthEvaluator.oxygen(log.value)
            entries.append(HistoryEntry(
                id: log.id.uuidString,
                type: .oxygen,
                date: log.date,
                title: "Blood Oxygen",
                value: "\(log.value)%",
                status: status.label,
                statusColor: status.color,
                icon: "lungs.fill",
                color: Theme.purple,
                tagID: log.tagID,
                source: .inApp
            ))
        }
        return entries
    }

    private func delete(_ entry: HistoryEntry) {
        switch entry.type {
        case .heartRate:
            if let measurement = store.measurements.first(where: { $0.id.uuidString == entry.id }) {
                store.deleteMeasurement(id: measurement.id)
            }
        case .pressure:
            if let log = store.pressureLogs.first(where: { $0.id.uuidString == entry.id }) { store.deletePressureLog(id: log.id) }
        case .glucose:
            if let log = store.glucoseLogs.first(where: { $0.id.uuidString == entry.id }) { store.deleteGlucoseLog(id: log.id) }
        case .oxygen:
            if let log = store.oxygenLogs.first(where: { $0.id.uuidString == entry.id }) { store.deleteOxygenLog(id: log.id) }
        }
        router.showToast("Record deleted")
    }

    private func beginMeasure() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            router.showMeasure = true
        }
    }
}

private struct HistoryDayGroup: Identifiable {
    let day: Date
    let entries: [HistoryEntry]
    var id: Date { day }
}

struct HistoryEntry: Identifiable {
    var id: String
    var type: HistoryEntryType
    var date: Date
    var title: String
    var value: String
    var status: String
    var statusColor: Color
    var icon: String
    var color: Color
    var tagID: String?
    var source: MeasurementSource
}

enum HistoryEntryType {
    case heartRate, pressure, glucose, oxygen
}
