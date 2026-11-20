import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @State private var selectedArticle: Article?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                popularSection
                ForEach(Array(ArticleCatalog.categories.enumerated()), id: \.element.id) { index, category in
                    categorySection(category)
                    if index == 3 { insightsBanner }
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedArticle) { article in
            ArticleReaderView(article: article)
                .environmentObject(store)
                .environmentObject(router)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HEART LIBRARY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                    Text("Insights")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(store.articlesReadCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                    Text("articles read")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 6)
            }
            Text("Evidence-led reads about your heart, recovery and daily habits.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(ArticleCatalog.popularArticles.count) stories")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ArticleCatalog.popularArticles) { article in
                        Button {
                            selectedArticle = article
                        } label: {
                            PopularArticleCard(article: article, isRead: store.isArticleRead(article.id))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("popular.\(article.id)")
                    }
                }
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
        }
    }

    private func categorySection(_ category: ArticleCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(category.articles.count) articles")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            if category.layout == "horizontal" {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(category.articles) { article in
                            Button {
                                selectedArticle = article
                            } label: {
                                CompactArticleCard(article: article, isRead: store.isArticleRead(article.id))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityIdentifier("category.\(article.id)")
                        }
                    }
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
            } else {
                VStack(spacing: 9) {
                    ForEach(category.articles) { article in
                        Button {
                            selectedArticle = article
                        } label: {
                            ArticleRow(article: article, isRead: store.isArticleRead(article.id))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("row.\(article.id)")
                    }
                }
            }
        }
    }

    private var insightsBanner: some View {
        Button {
            router.openPaywall("insights")
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock All Features")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Try all premium features for free")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Text("Try Premium")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Theme.heartGradient)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ArticleCover: View {
    var article: Article
    var height: CGFloat = 150
    var showsSymbol: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(article.gradient)
            ForEach(0..<3) { index in
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 90 + CGFloat(index) * 44, height: 90 + CGFloat(index) * 44)
                    .offset(x: 60, y: -20)
            }
            if showsSymbol {
                Image(systemName: article.coverSymbol)
                    .font(.system(size: height * 0.24, weight: .light))
                    .foregroundStyle(.white.opacity(0.36))
                    .offset(x: 50, y: 30)
            }
            VStack(alignment: .leading, spacing: 5) {
                Spacer()
                Text(article.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    Text("\(article.pages.count) pages")
                    Text("·")
                    Text("\(article.readSeconds)s read")
                }
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct PopularArticleCard: View {
    var article: Article
    var isRead: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ArticleCover(article: article, height: 180)
            if isRead {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .padding(10)
            }
        }
        .frame(width: 230)
    }
}

struct CompactArticleCard: View {
    var article: Article
    var isRead: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ArticleCover(article: article, height: 140)
            if isRead {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(8)
            }
        }
        .frame(width: 190)
    }
}

struct ArticleRow: View {
    var article: Article
    var isRead: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(article.gradient)
                Image(systemName: article.coverSymbol)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 62, height: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(article.pages.count) pages · \(article.readSeconds)s")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            if isRead {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.teal)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }
}

// MARK: - Reader

struct ArticleReaderView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var article: Article

    @State private var page = 0
    @State private var progress: Double = 0
    @State private var isPlaying = true
    @State private var showSource = false
    @State private var showShare = false
    @State private var completed = false

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let pageDuration: Double = 5

    var body: some View {
        ZStack {
            article.gradient.ignoresSafeArea()
                .overlay {
                    GeometryReader { proxy in
                        ZStack {
                            ForEach(0..<4) { index in
                                Circle()
                                    .stroke(.white.opacity(0.06), lineWidth: 1)
                                    .frame(width: 260 + CGFloat(index) * 120, height: 260 + CGFloat(index) * 120)
                                    .position(x: proxy.size.width - 130, y: 80 - CGFloat(index) * 40)
                            }
                            Image(systemName: article.coverSymbol)
                                .font(.system(size: 220, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.07))
                                .position(x: proxy.size.width - 100, y: proxy.size.height - 260)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                    }
                }

            VStack(spacing: 0) {
                topBar
                ZStack {
                    ArticlePageView(page: article.pages[page], article: article, index: page)
                        .id(page)
                        .transition(.opacity)
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { previousPage() }
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { nextPage() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                bottomBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .onReceive(timer) { _ in
            guard isPlaying, !showShare, !showSource else { return }
            progress += 0.1 / pageDuration
            if progress >= 1 {
                if page < article.pages.count - 1 {
                    withAnimation { page += 1 }
                    progress = 0
                } else {
                    progress = 1
                    isPlaying = false
                    if !completed {
                        completed = true
                        store.markArticleRead(article.id)
                        router.showToast("Article completed")
                    }
                }
            }
        }
        .onChange(of: page) { _, _ in progress = 0 }
        .onAppear {
            store.markArticleRead(article.id)
        }
        .sheet(isPresented: $showSource) {
            if let url = article.sourceURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [
                "\(article.title) — from Heartica Insights",
                article.sourceURL ?? URL(string: "https://heartica.pro")!
            ])
        }
        .onTapGesture { isPlaying.toggle() }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.16))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("article.close")
                Text(article.categoryID.replacingOccurrences(of: "-", with: " ").uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                Spacer()
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.16))
                        .clipShape(Circle())
                }
            }
            HStack(spacing: 4) {
                ForEach(article.pages.indices, id: \.self) { index in
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.25))
                            Capsule()
                                .fill(.white)
                                .frame(width: proxy.size.width * fill(index))
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .frame(maxWidth: .infinity)
    }

    private func fill(_ index: Int) -> Double {
        if index < page { return 1 }
        if index == page { return progress }
        return 0
    }

    private var bottomBar: some View {
        HStack {
            Button {
                showSource = true
            } label: {
                Label("Source", systemImage: "link")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.13))
                    .clipShape(Capsule())
            }
            Spacer()
            Text("\(page + 1) / \(article.pages.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            Button {
                showShare = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.13))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
    }

    private func previousPage() {
        guard page > 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) { page -= 1 }
        progress = 0
    }

    private func nextPage() {
        guard page < article.pages.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
        progress = 0
    }
}

struct ArticlePageView: View {
    var page: ArticlePage
    var article: Article
    var index: Int

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 12)
                Text("PAGE \(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.5))
                Text(page.title)
                    .font(.system(size: index == 0 ? 36 : 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.subtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 44, height: 1)
                Text(page.body)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 20)
                Text(article.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}
