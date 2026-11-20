import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var selectedArticle: Article?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    summaryCard
                    SectionHeading(title: "Chapters")
                    VStack(spacing: 10) {
                        ForEach(JourneyCatalog.chapters) { chapter in
                            NavigationLink(value: chapter) {
                                chapterCard(chapter)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityIdentifier("journey.chapter.\(chapter.id)")
                            .disabled(!JourneyEngine.chapterActive(chapter, store: store) && !JourneyEngine.chapterCompleted(chapter, store: store))
                        }
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: JourneyChapter.self) { chapter in
                JourneyChapterView(chapter: chapter)
                    .environmentObject(store)
                    .environmentObject(router)
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleReaderView(article: article)
                .environmentObject(store)
                .environmentObject(router)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("MY JOURNEY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Theme.teal)
                Text("Building a habit,\none level at a time")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            IconButton(systemName: "xmark", size: 38, identifier: "journey.close") { dismiss() }
        }
        .padding(.top, 8)
    }

    private var summaryCard: some View {
        let current = JourneyEngine.currentLevel(store: store)
        let completedLevels = JourneyCatalog.allLevels.filter { JourneyEngine.isEffectiveComplete($0, store: store) }.count
        let progress = current.map { Double(JourneyEngine.completedCoreCount($0, store: store)) / Double(max($0.coreTasks.count, 1)) } ?? 1
        return HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Theme.teal.opacity(0.14), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.teal, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(completedLevels)")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ 100")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 6) {
                Text(current.map { "Level \($0.number) · \($0.title)" } ?? "Journey complete")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(current.map { "\(JourneyEngine.completedCoreCount($0, store: store)) of \($0.coreTasks.count) main tasks completed" } ?? "You've completed every level.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                ProgressBarView(progress: progress, color: Theme.teal, height: 5)
                Text("Complete main tasks to unlock the next level")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(18)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private func chapterCard(_ chapter: JourneyChapter) -> some View {
        let completed = JourneyEngine.chapterCompleted(chapter, store: store)
        let active = JourneyEngine.chapterActive(chapter, store: store)
        let unlocked = active || completed
        let completedLevels = chapter.levels.filter { JourneyEngine.isEffectiveComplete($0, store: store) }.count
        let progress = Double(completedLevels) / Double(max(chapter.levels.count, 1))
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(unlocked ? chapter.color.opacity(0.14) : Theme.surfaceAlt)
                Image(systemName: completed ? "checkmark.seal.fill" : (unlocked ? chapter.icon : "lock.fill"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(unlocked ? chapter.color : Theme.textTertiary)
            }
            .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text("Chapter \(chapter.number)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(unlocked ? chapter.color : Theme.textTertiary)
                    if active {
                        Text("CURRENT")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.teal)
                            .clipShape(Capsule())
                    }
                }
                Text(chapter.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    ProgressBarView(progress: progress, color: chapter.color, height: 4)
                    Text("\(completedLevels)/\(chapter.levels.count)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        .opacity(unlocked ? 1 : 0.6)
    }
}

struct JourneyChapterView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    var chapter: JourneyChapter

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                    .accessibilityIdentifier("journey.back")
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("CHAPTER \(chapter.number)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(chapter.color)
                    Text(chapter.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(chapter.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                VStack(spacing: 10) {
                    ForEach(chapter.levels) { level in
                        NavigationLink(value: level) {
                            levelRow(level)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!JourneyEngine.isUnlocked(level, store: store))
                    }
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: JourneyLevel.self) { level in
            JourneyLevelView(level: level, chapter: chapter)
                .environmentObject(store)
                .environmentObject(router)
        }
    }

    private func levelRow(_ level: JourneyLevel) -> some View {
        let unlocked = JourneyEngine.isUnlocked(level, store: store)
        let complete = JourneyEngine.isEffectiveComplete(level, store: store)
        let progress = Double(JourneyEngine.completedCoreCount(level, store: store)) / Double(max(level.coreTasks.count, 1))
        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .stroke(complete ? Theme.teal.opacity(0.16) : Theme.surfaceAlt, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: complete ? 1 : progress)
                    .stroke(complete ? Theme.teal : chapter.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                } else if complete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.teal)
                } else {
                    Text("\(level.number)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("Level \(level.number)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.textTertiary)
                Text(level.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(JourneyEngine.completedCoreCount(level, store: store)) / \(level.coreTasks.count) main tasks")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        .opacity(unlocked ? 1 : 0.55)
    }
}

struct JourneyLevelView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var level: JourneyLevel
    var chapter: JourneyChapter

    @State private var selectedArticle: Article?

    private var unlocked: Bool { JourneyEngine.isUnlocked(level, store: store) }
    private var complete: Bool { JourneyEngine.isEffectiveComplete(level, store: store) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                    .accessibilityIdentifier("journey.back")
                    Spacer()
                    Text("CHAPTER \(chapter.number) · LEVEL \(level.number)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textTertiary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(level.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(level.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 16) {
                    ProgressRing(progress: Double(JourneyEngine.completedCoreCount(level, store: store)) / Double(max(level.coreTasks.count, 1)),
                                 color: complete ? Theme.teal : chapter.color, lineWidth: 7,
                                 label: "\(Int(Double(JourneyEngine.completedCoreCount(level, store: store)) / Double(max(level.coreTasks.count, 1)) * 100))%",
                                 detail: "core")
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(complete ? "Level completed" : (unlocked ? "In progress" : "Locked"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text(unlocked ? "Tasks completed: \(level.tasks.filter { JourneyEngine.progress(for: $0, store: store).isComplete }.count) / \(level.tasks.count)" : "Finish your current level to unlock the next one")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))

                ForEach([JourneyTaskType.core, .optional, .pro], id: \.self) { type in
                    let tasks = level.tasks.filter { $0.type == type }
                    if !tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(type.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary)
                                if type == .pro {
                                    Text("PREMIUM")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.amber)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.amber.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                Spacer()
                                Text("\(tasks.filter { JourneyEngine.progress(for: $0, store: store).isComplete }.count)/\(tasks.count)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            VStack(spacing: 8) {
                                ForEach(tasks) { task in
                                    taskRow(task)
                                }
                            }
                        }
                    }
                }
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedArticle) { article in
            ArticleReaderView(article: article)
                .environmentObject(store)
                .environmentObject(router)
        }
    }

    private func taskRow(_ task: JourneyTask) -> some View {
        let progress = JourneyEngine.progress(for: task, store: store)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: progress.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(progress.isComplete ? Theme.teal : Theme.textTertiary)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(chapter.color)
                        Text(task.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ProgressBarView(progress: progress.fraction, color: progress.isComplete ? Theme.teal : chapter.color, height: 4)
                    HStack {
                        Text("\(min(progress.current, progress.target)) / \(progress.target)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                        Spacer()
                        if !progress.isComplete && unlocked {
                            Button {
                                switch task.category {
                                case .readArticle:
                                    if let id = task.referenceID, let article = ArticleCatalog.article(id: id) {
                                        selectedArticle = article
                                    }
                                case .appleHealth:
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        router.showAppleHealth = true
                                    }
                                default:
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        router.showMeasure = true
                                    }
                                }
                            } label: {
                                Text(task.cta)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(chapter.color)
                            }
                        }
                    }
                }
            }
        }
        .padding(13)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        .opacity(unlocked ? 1 : 0.55)
    }
}
