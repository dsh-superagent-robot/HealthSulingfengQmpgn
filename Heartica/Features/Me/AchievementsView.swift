import SwiftUI

struct AchievementsOverviewView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Achievement?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                summary
                ForEach(AchievementCatalog.categories) { category in
                    categorySection(category)
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selected) { achievement in
            NavigationStack {
                AchievementDetailView(achievement: achievement)
                    .environmentObject(store)
            }
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
                Text("Achievements")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Milestones for a steady practice")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var summary: some View {
        let completed = AchievementEngine.completedCount(store: store)
        let total = AchievementCatalog.all.count
        let progress = Double(completed) / Double(max(total, 1))
        return HStack(spacing: 18) {
            ProgressRing(progress: progress, color: Theme.amber, lineWidth: 7,
                         label: "\(completed)", detail: "of \(total)")
                .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 5) {
                Text("Your collection")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Every tier is earned by consistent measurement and context. Keep collecting.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    ForEach(AchievementCatalog.categories) { category in
                        Image(systemName: category.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(category.color)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private func categorySection(_ category: AchievementCategory) -> some View {
        let completed = category.achievements.filter { AchievementEngine.value(for: $0, store: store) >= ($0.tiers.first?.rewardValue ?? 1) }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(category.color)
                Text(category.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(completed)/\(category.achievements.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            VStack(spacing: 8) {
                ForEach(category.achievements) { achievement in
                    Button {
                        selected = achievement
                    } label: {
                        achievementRow(achievement, category: category)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private func achievementRow(_ achievement: Achievement, category: AchievementCategory) -> some View {
        let value = AchievementEngine.value(for: achievement, store: store)
        let unlockedTiers = AchievementEngine.unlockedTierIndex(achievement, store: store)
        let next = AchievementEngine.nextTier(achievement, store: store)
        let ribbon = achievement.tiers[safe: max(0, unlockedTiers - 1)]?.ribbon
        return HStack(spacing: 12) {
            AchievementBadge(shape: achievement.shape, color: ribbon?.color ?? category.color, unlocked: unlockedTiers > 0)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 6) {
                    ProgressBarView(progress: AchievementEngine.progress(achievement, store: store), color: category.color, height: 4)
                    Text("\(value)/\(next?.rewardValue ?? achievement.finalTarget)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(achievement.metric.format.replacingOccurrences(of: "%@", with: "\(value)"))
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("\(unlockedTiers)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(unlockedTiers > 0 ? category.color : Theme.textTertiary)
                Text("tiers")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }
}

struct AchievementBadge: View {
    var shape: AchievementShape
    var color: Color
    var unlocked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(unlocked ? 0.14 : 0.06))
            Image(systemName: shape.symbol)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(unlocked ? color : Theme.textTertiary.opacity(0.5))
            if unlocked {
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color)
                    .offset(x: 12, y: -12)
            }
        }
    }
}

struct AchievementDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var achievement: Achievement

    private var category: AchievementCategory? {
        AchievementCatalog.categories.first { $0.id == achievement.categoryID }
    }

    private var value: Int { AchievementEngine.value(for: achievement, store: store) }
    private var next: AchievementTier? { AchievementEngine.nextTier(achievement, store: store) }
    private var unlocked: Int { AchievementEngine.unlockedTierIndex(achievement, store: store) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                VStack(spacing: 12) {
                    AchievementBadge(shape: achievement.shape, color: category?.color ?? Theme.accent, unlocked: unlocked > 0)
                        .frame(width: 88, height: 88)
                    Text(achievement.title)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(achievement.subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    if let category {
                        Text(category.title.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.3)
                            .foregroundStyle(category.color)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(value) / \(next?.rewardValue ?? achievement.finalTarget)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    ProgressBarView(progress: AchievementEngine.progress(achievement, store: store), color: category?.color ?? Theme.accent, height: 8)
                    Text(achievement.metric.format.replacingOccurrences(of: "%@", with: "\(value)"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text(achievement.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardSurface(padding: 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tiers")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    ForEach(Array(achievement.tiers.enumerated()), id: \.offset) { index, tier in
                        let reached = value >= tier.rewardValue
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(reached ? (tier.ribbon?.color ?? category?.color ?? Theme.accent).opacity(0.15) : Theme.surfaceAlt)
                                if reached {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(tier.ribbon?.color ?? category?.color ?? Theme.accent)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                            }
                            .frame(width: 24, height: 24)
                            Text(achievement.rewardTitle.replacingOccurrences(of: "%@", with: "\(index + 1)"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(reached ? Theme.textPrimary : Theme.textSecondary)
                            Spacer()
                            Text("\(tier.rewardValue)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(reached ? (tier.ribbon?.color ?? Theme.textPrimary) : Theme.textTertiary)
                            if let ribbon = tier.ribbon {
                                Text(ribbon.rawValue.capitalized)
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundStyle(ribbon.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ribbon.color.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
                .cardSurface(padding: 16)
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
