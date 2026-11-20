import SwiftUI

// MARK: - Shared

private struct LogEditorHeader: View {
    var title: String
    var icon: String
    var color: Color
    var trailing: AnyView?
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}

private struct TagMenuRow: View {
    @EnvironmentObject var store: AppStore
    @Binding var tagID: String?

    var body: some View {
        Menu {
            Button("No Tag") { tagID = nil }
            ForEach(store.allTags) { tag in
                Button {
                    tagID = tag.id
                } label: {
                    Text(tag.name)
                }
            }
        } label: {
            HStack {
                Text("Tag")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if let tag = store.tag(id: tagID) {
                    TagChip(tag: tag, selected: false)
                } else {
                    Text("Add a Tag")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct TimeRow: View {
    @Binding var date: Date

    var body: some View {
        HStack {
            Text("Time")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.compact)
            Button("Now") {
                date = Date()
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DeleteLogButton: View {
    var action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text("Delete the measurement")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }
}

// MARK: - Pressure

struct PressureLogEditor: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var existing: PressureLog?
    @State private var sys = 120
    @State private var dia = 80
    @State private var date = Date()
    @State private var tagID: String?
    @State private var loaded = false
    @State private var showDelete = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                LogEditorHeader(title: "Blood Pressure", icon: "waveform.path.ecg", color: Theme.blue,
                                trailing: existing == nil ? nil : AnyView(Button {
                                    showDelete = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                })) {
                    dismiss()
                }
                .padding(.top, 4)
                valueCard
                TimeRow(date: $date)
                TagMenuRow(tagID: $tagID)
                Button {
                    save()
                } label: {
                    Text(existing == nil ? "Log Blood Pressure" : "Save Changes")
                }
                .buttonStyle(PrimaryButtonStyle())
                if existing != nil {
                    DeleteLogButton { showDelete = true }
                }
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            if let existing {
                sys = existing.sys
                dia = existing.dia
                date = existing.date
                tagID = existing.tagID
            }
        }
        .alert("Delete the measurement?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let existing { store.deletePressureLog(id: existing.id) }
                router.showToast("Blood pressure deleted")
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
        }
    }

    private var valueCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("SYS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(sys)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Text("/")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Theme.textTertiary)
                VStack(spacing: 2) {
                    Text("DIA")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(dia)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                VStack(spacing: 2) {
                    Text("UNIT")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text("mmHg")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.top, 4)
            HStack(spacing: 0) {
                Picker("Systolic", selection: $sys) {
                    ForEach(80...260, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Picker("Diastolic", selection: $dia) {
                    ForEach(40...140, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 150)
            .clipped()
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private func save() {
        if var existing {
            existing.sys = sys
            existing.dia = dia
            existing.date = date
            existing.tagID = tagID
            store.updatePressureLog(existing)
        } else {
            store.addPressureLog(PressureLog(date: date, sys: sys, dia: dia, tagID: tagID))
        }
        router.showToast("Blood pressure saved")
        dismiss()
    }
}

// MARK: - Glucose

struct GlucoseLogEditor: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var existing: GlucoseLog?
    @State private var valueMgdl: Double = 100
    @State private var afterMeal = false
    @State private var date = Date()
    @State private var unit: GlucoseUnit = .mgdl
    @State private var loaded = false
    @State private var showDelete = false

    private var mmolValues: [Double] { GlucoseUnit.mmolRange }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                LogEditorHeader(title: "Blood Sugar", icon: "drop.fill", color: Theme.pink,
                                trailing: existing == nil ? nil : AnyView(Button {
                                    showDelete = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                })) {
                    dismiss()
                }
                .padding(.top, 4)

                HStack(spacing: 6) {
                    ForEach(GlucoseUnit.allCases) { item in
                        Button {
                            unit = item
                        } label: {
                            Text(item.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(unit == item ? .white : Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(unit == item ? Theme.pink : Theme.surfaceAlt)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(unit == .mgdl ? "\(Int(valueMgdl.rounded()))" : Fmt.value(valueMgdl / 18.0, decimals: 1))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text(unit.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Picker("Value", selection: valueBinding) {
                        if unit == .mgdl {
                            ForEach(50...250, id: \.self) { value in
                                Text("\(value)").tag(Double(value))
                            }
                        } else {
                            ForEach(mmolValues, id: \.self) { value in
                                Text(Fmt.value(value, decimals: 1)).tag(value)
                            }
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .clipped()
                }
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))

                HStack(spacing: 6) {
                    ForEach([false, true], id: \.self) { isAfter in
                        Button {
                            afterMeal = isAfter
                        } label: {
                            Text(isAfter ? "After Meal" : "Before Meal")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(afterMeal == isAfter ? .white : Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(afterMeal == isAfter ? Theme.pink : Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                TimeRow(date: $date)
                Button {
                    save()
                } label: {
                    Text(existing == nil ? "Log Sugar" : "Save Changes")
                }
                .buttonStyle(PrimaryButtonStyle())
                if existing != nil {
                    DeleteLogButton { showDelete = true }
                }
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            unit = GlucoseUnit(rawValue: UserDefaults.standard.string(forKey: "glucoseUnit") ?? "mgdl") ?? .mgdl
            if let existing {
                valueMgdl = existing.valueMgdl
                afterMeal = existing.tagID == "eating-after"
                date = existing.date
            }
        }
        .alert("Delete the measurement?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let existing { store.deleteGlucoseLog(id: existing.id) }
                router.showToast("Blood sugar deleted")
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
        }
    }

    private var valueBinding: Binding<Double> {
        Binding(
            get: {
                if unit == .mgdl {
                    return min(max(valueMgdl.rounded(), 50), 250)
                }
                let target = valueMgdl / 18.0
                return mmolValues.min(by: { abs($0 - target) < abs($1 - target) }) ?? 5.5
            },
            set: { newValue in
                if unit == .mgdl {
                    valueMgdl = newValue.rounded()
                } else {
                    valueMgdl = newValue * 18.0
                }
            }
        )
    }

    private func save() {
        UserDefaults.standard.set(unit.rawValue, forKey: "glucoseUnit")
        let tag = afterMeal ? "eating-after" : "eating-before"
        if var existing {
            existing.valueMgdl = valueMgdl
            existing.date = date
            existing.tagID = tag
            store.updateGlucoseLog(existing)
        } else {
            store.addGlucoseLog(GlucoseLog(date: date, valueMgdl: valueMgdl, tagID: tag))
        }
        router.showToast("Blood sugar saved")
        dismiss()
    }
}

// MARK: - Oxygen

struct OxygenLogEditor: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var existing: OxygenLog?
    @State private var value = 98
    @State private var date = Date()
    @State private var tagID: String?
    @State private var loaded = false
    @State private var showDelete = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                LogEditorHeader(title: "Blood Oxygen", icon: "lungs.fill", color: Theme.purple,
                                trailing: existing == nil ? nil : AnyView(Button {
                                    showDelete = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                })) {
                    dismiss()
                }
                .padding(.top, 4)
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(value)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("%")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Picker("Oxygen", selection: $value) {
                        ForEach(1...100, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .clipped()
                }
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
                TimeRow(date: $date)
                TagMenuRow(tagID: $tagID)
                Button {
                    save()
                } label: {
                    Text(existing == nil ? "Log Oxygen" : "Save Changes")
                }
                .buttonStyle(PrimaryButtonStyle())
                if existing != nil {
                    DeleteLogButton { showDelete = true }
                }
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            if let existing {
                value = existing.value
                date = existing.date
                tagID = existing.tagID
            }
        }
        .alert("Delete the measurement?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let existing { store.deleteOxygenLog(id: existing.id) }
                router.showToast("Blood oxygen deleted")
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this measurement?")
        }
    }

    private func save() {
        if var existing {
            existing.value = value
            existing.date = date
            existing.tagID = tagID
            store.updateOxygenLog(existing)
        } else {
            store.addOxygenLog(OxygenLog(date: date, value: value, tagID: tagID))
        }
        router.showToast("Blood oxygen saved")
        dismiss()
    }
}
