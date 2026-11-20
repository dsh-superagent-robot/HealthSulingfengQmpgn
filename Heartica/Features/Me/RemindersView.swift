import SwiftUI

struct RemindersView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var authorized = true
    @State private var showEditor = false
    @State private var editing: ReminderItem?
    @State private var deleteTarget: ReminderItem?
    @State private var showPermission = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                if !authorized { permissionCard }
                if store.reminders.isEmpty {
                    EmptyStateView(icon: "bell.slash", title: "No Reminders",
                                   subtitle: "Set a reminder and it will be displayed here. Gentle prompts help you build consistency.",
                                   actionTitle: "Set Reminder") { showEditor = true }
                        .padding(.top, 30)
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.reminders) { reminder in
                            reminderRow(reminder)
                        }
                    }
                }
                if !store.reminders.isEmpty {
                    Button {
                        showEditor = true
                    } label: {
                        Text("Set Reminder")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            authorized = await NotificationManager.shared.isAuthorized()
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                SetReminderView(initial: nil)
                    .environmentObject(store)
            }
        }
        .sheet(item: $editing) { reminder in
            NavigationStack {
                SetReminderView(initial: reminder)
                    .environmentObject(store)
            }
        }
        .alert("Delete reminder?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("Cancel", role: .cancel) { deleteTarget = nil }
            Button("Delete", role: .destructive) {
                if let deleteTarget {
                    NotificationManager.shared.cancel(deleteTarget)
                    store.deleteReminder(id: deleteTarget.id)
                }
                deleteTarget = nil
            }
        } message: {
            Text("Are you sure you want to delete this reminder?")
        }
        .alert("Notifications Disabled", isPresented: $showPermission) {
            Button("Cancel", role: .cancel) {}
            Button("Go to Settings") { NotificationManager.shared.openSettings() }
        } message: {
            Text("Allow push notifications in Settings to set and receive reminders.")
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
            .accessibilityIdentifier("reminders.close")
            VStack(alignment: .leading, spacing: 1) {
                Text("Daily Reminders")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Notifications repeat daily at the time you choose")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var permissionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(Theme.orange)
                .frame(width: 34, height: 34)
                .background(Theme.orange.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Notifications Disabled")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Allow push notifications in Settings to set and receive reminders.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Button("Go to Settings") { NotificationManager.shared.openSettings() }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }
        }
        .cardSurface(padding: 14)
    }

    private func reminderRow(_ reminder: ReminderItem) -> some View {
        HStack(spacing: 13) {
            Image(systemName: reminder.type.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.type.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(Fmt.time.string(from: reminder.time) + " · Every day")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { reminder.isScheduled },
                set: { value in
                    if value {
                        Task {
                            var granted = await NotificationManager.shared.isAuthorized()
                            if !granted {
                                granted = await NotificationManager.shared.requestAuthorization()
                            }
                            authorized = granted
                            if granted {
                                var updated = reminder
                                updated.isScheduled = true
                                store.upsertReminder(updated)
                                NotificationManager.shared.schedule(updated)
                            } else {
                                showPermission = true
                            }
                        }
                    } else {
                        store.setReminderScheduled(id: reminder.id, scheduled: false)
                        NotificationManager.shared.cancel(reminder)
                    }
                }
            ))
            .labelsHidden()
            .tint(Theme.accent)
            Menu {
                Button {
                    editing = reminder
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    deleteTarget = reminder
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 28, height: 30)
            }
        }
        .cardSurface(padding: 13)
    }
}

struct SetReminderView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var initial: ReminderItem?

    @State private var type: ReminderType = .pulse
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var enabled = true
    @State private var showPermission = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button("Close") { dismiss() }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Set Reminder")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Select the measurement type you want to set a reminder for.")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(ReminderType.allCases) { item in
                        Button {
                            type = item
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(item.title)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(type == item ? .white : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(type == item ? Theme.accent : Theme.surface)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Reminder time")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Toggle("", isOn: $enabled)
                            .labelsHidden()
                            .tint(Theme.accent)
                    }
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .clipped()
                        .opacity(enabled ? 1 : 0.35)
                        .disabled(!enabled)
                    Text("Repeats daily on this device. You can change it anytime.")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardSurface(padding: 16)

                Button {
                    save()
                } label: {
                    Text("Confirm")
                }
                .buttonStyle(PrimaryButtonStyle())
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let initial {
                type = initial.type
                time = initial.time
                enabled = initial.isScheduled
            }
        }
        .alert("Notifications Disabled", isPresented: $showPermission) {
            Button("Cancel", role: .cancel) {}
            Button("Go to Settings") { NotificationManager.shared.openSettings() }
        } message: {
            Text("Allow push notifications in Settings to set and receive reminders.")
        }
    }

    private func save() {
        Task {
            var granted = await NotificationManager.shared.isAuthorized()
            if !granted, enabled {
                granted = await NotificationManager.shared.requestAuthorization()
            }
            if !granted, enabled {
                showPermission = true
                return
            }
            var reminder = initial ?? ReminderItem(type: type, time: time, isScheduled: enabled)
            reminder.type = type
            reminder.time = time
            reminder.isScheduled = enabled
            store.upsertReminder(reminder)
            if enabled {
                NotificationManager.shared.schedule(reminder)
            } else {
                NotificationManager.shared.cancel(reminder)
            }
            dismiss()
        }
    }
}
