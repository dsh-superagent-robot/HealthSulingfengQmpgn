import Foundation
import SwiftUI

struct ArticlePage: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var subtitle: String
    var body: String
}

struct Article: Identifiable, Hashable {
    var id: String
    var categoryID: String
    var title: String
    var subtitle: String
    var pages: [ArticlePage]
    var isPopular: Bool
    var sourceURL: URL?
    var colorHex: UInt
    var readSeconds: Int { pages.count * 5 }

    var color: Color { Color(hex: colorHex) }
    var gradient: LinearGradient {
        LinearGradient(colors: [color.opacity(0.95), color.opacity(0.58), Color(hex: 0x14131A)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var coverSymbol: String {
        switch categoryID {
        case "hrv-basics", "hrv-explained", "hrv-context": return "waveform.path.ecg"
        case "ppg": return "hand.point.up.left.fill"
        case "ecg": return "waveform.path.ecg.rectangle"
        case "arrhythmia": return "heart.text.square"
        case "heart-attack": return "cross.case.fill"
        case "sleep": return "moon.stars.fill"
        case "stress": return "brain.head.profile"
        case "activity": return "figure.run"
        default: return "heart.fill"
        }
    }
}

struct ArticleCategory: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var layout: String
    var articles: [Article]
}

enum ArticleCatalog {
    static let categories: [ArticleCategory] = build()

    static var allArticles: [Article] { categories.flatMap(\.articles) }
    static var popularArticles: [Article] { allArticles.filter(\.isPopular) }

    static func articles(in categoryID: String) -> [Article] {
        categories.first(where: { $0.id == categoryID })?.articles ?? []
    }

    static func article(id: String) -> Article? {
        allArticles.first { $0.id == id }
    }

    private struct CategorySeed {
        let id: String
        let title: String
        let subtitle: String
        let layout: String
        let slugs: [String]
        let popular: Set<Int>
        let source: String
        let colorBase: UInt
    }

    private static let seeds: [CategorySeed] = [
        CategorySeed(
            id: "hrv-basics",
            title: "Heart Rate Variability (HRV): Basics",
            subtitle: "Start here — the fundamentals of your heart's natural rhythm.",
            layout: "vertical",
            slugs: ["what_is_hrv", "how_hrv_works", "what_affects_hrv", "measuring_hrv", "improving_hrv"],
            popular: [1],
            source: "https://my.clevelandclinic.org/health/diagnostics/23332-heart-rate-variability",
            colorBase: 0x4F83D8
        ),
        CategorySeed(
            id: "hrv-explained",
            title: "Heart Rate Variability Explained (Deep Dive)",
            subtitle: "The physiology and analysis behind every beat.",
            layout: "vertical",
            slugs: ["definition", "variability", "clinical_significance", "psychological_aspects", "analysis_methods", "physiological_correlates", "artifact_and_limits"],
            popular: [],
            source: "https://en.wikipedia.org/wiki/Heart_rate_variability",
            colorBase: 0x8B6BD9
        ),
        CategorySeed(
            id: "hrv-context",
            title: "HRV in Context: How to Interpret Changes Correctly",
            subtitle: "A number only makes sense when it has a story.",
            layout: "horizontal",
            slugs: ["why_context_matters", "rest_and_recovery", "readiness_and_load", "food_and_metabolism", "personalization_and_tags", "decrease_interpretation"],
            popular: [1, 3],
            source: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/",
            colorBase: 0x2F9C8E
        ),
        CategorySeed(
            id: "ppg",
            title: "Photoplethysmography (PPG) Explained",
            subtitle: "How a phone camera can read the pulse in your fingertip.",
            layout: "vertical",
            slugs: ["fundamentals", "measurement_methods", "signal_analysis", "clinical_use", "limitations_and_artifacts"],
            popular: [0],
            source: "https://en.wikipedia.org/wiki/Photoplethysmogram",
            colorBase: 0xE0A03A
        ),
        CategorySeed(
            id: "ecg",
            title: "ECG made simple",
            subtitle: "What an electrocardiogram records and why it matters.",
            layout: "vertical",
            slugs: ["about", "why", "types", "procedure", "results", "symptoms", "safe", "after", "screening", "facts"],
            popular: [0, 5, 8, 9],
            source: "https://www.mayoclinic.org/tests-procedures/ekg/about/pac-20384983",
            colorBase: 0xD95C9A
        ),
        CategorySeed(
            id: "arrhythmia",
            title: "About Arrhythmia",
            subtitle: "When the heart's electrical rhythm loses its steady beat.",
            layout: "vertical",
            slugs: ["about", "types", "heart", "circuit", "causes", "misfiring", "diagnosing", "normal", "kids", "livingwith"],
            popular: [1, 5],
            source: "https://www.heart.org/en/health-topics/arrhythmia",
            colorBase: 0xE4515A
        ),
        CategorySeed(
            id: "heart-attack",
            title: "Heart Attack Basics",
            subtitle: "Recognise the warning signs and understand recovery.",
            layout: "horizontal",
            slugs: ["about", "damage", "recovery", "signs", "terms", "othertriggers", "arrest", "prevention", "hopeafter", "takeaways"],
            popular: [2, 3, 7],
            source: "https://www.heart.org/en/health-topics/heart-attack",
            colorBase: 0xCB6A3C
        ),
        CategorySeed(
            id: "sleep",
            title: "Your Guide to Healthy Sleep",
            subtitle: "Recovery starts while you are resting.",
            layout: "vertical",
            slugs: ["about", "benefits", "science", "sleepy", "safety", "timing", "myths", "disrupt", "tips", "disorder"],
            popular: [1, 5, 6, 7, 8],
            source: "https://www.nhlbi.nih.gov/health-topics/sleep-deprivation-and-deficiency",
            colorBase: 0x527FE5
        ),
        CategorySeed(
            id: "stress",
            title: "Stress and Body Function",
            subtitle: "How pressure shows up in your heart, brain and immunity.",
            layout: "vertical",
            slugs: ["about", "brain", "memory", "cognition", "immunity", "cardio", "gastro", "hormones", "allsystems", "managing"],
            popular: [1, 4, 8],
            source: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5579396/",
            colorBase: 0x8B6BD9
        ),
        CategorySeed(
            id: "activity",
            title: "Physical Activity Guidelines (by AHA)",
            subtitle: "Move more, sit less — a practical place to begin.",
            layout: "horizontal",
            slugs: ["howtostart", "benefits", "recforadults", "recforkids", "types", "firststeps", "intensity", "movement", "motivation", "push"],
            popular: [1, 4, 7, 9],
            source: "https://www.heart.org/en/healthy-living/fitness",
            colorBase: 0x4D9C5C
        )
    ]

    private static let titleOverrides: [String: String] = [
        "what_is_hrv": "What Is HRV?",
        "how_hrv_works": "How HRV Works in the Body",
        "what_affects_hrv": "What Affects HRV",
        "measuring_hrv": "Measuring HRV",
        "improving_hrv": "Improving Your HRV",
        "clinical_significance": "Clinical Significance",
        "psychological_aspects": "Psychological Aspects",
        "analysis_methods": "Analysis Methods",
        "physiological_correlates": "Physiological Correlates",
        "artifact_and_limits": "Artifacts and Limitations",
        "why_context_matters": "Why Context Matters",
        "rest_and_recovery": "Rest & Recovery Context",
        "readiness_and_load": "Readiness and Load",
        "food_and_metabolism": "Food and Metabolic Context",
        "personalization_and_tags": "Personalization and Tags",
        "decrease_interpretation": "Interpreting a Decrease",
        "fundamentals": "PPG Fundamentals",
        "measurement_methods": "Measurement Methods",
        "signal_analysis": "Signal Analysis",
        "clinical_use": "Clinical Use",
        "limitations_and_artifacts": "Limitations and Artifacts",
        "about": "The Basics",
        "why": "Why It Matters",
        "types": "Types and Variations",
        "procedure": "What Happens During the Test",
        "results": "Understanding Your Results",
        "symptoms": "Common Symptoms to Watch",
        "safe": "Is It Safe?",
        "after": "After the Test",
        "screening": "Screening and Prevention",
        "facts": "Quick Facts",
        "heart": "How the Heart Works",
        "circuit": "The Heart's Electrical Circuit",
        "causes": "What Causes Arrhythmia",
        "misfiring": "When the Heart Misfires",
        "diagnosing": "Diagnosing an Arrhythmia",
        "normal": "What Is a Normal Rhythm?",
        "kids": "Arrhythmia in Children",
        "livingwith": "Living With Arrhythmia",
        "damage": "Heart Attack and Heart Damage",
        "recovery": "Recovering from a Heart Attack",
        "signs": "Know the Warning Signs",
        "terms": "Terms You Should Know",
        "othertriggers": "Other Triggers to Watch",
        "arrest": "Cardiac Arrest vs. Heart Attack",
        "prevention": "Heart Attack Prevention",
        "hopeafter": "Hope After a Heart Attack",
        "takeaways": "Key Takeaways",
        "benefits": "What Sleep Gives You",
        "science": "The Science of Sleep",
        "sleepy": "Why You Feel Sleepy",
        "safety": "Sleep and Daily Safety",
        "timing": "How Much Sleep Is Enough?",
        "myths": "Sleep Myths Busted",
        "disrupt": "What Disrupts Sleep",
        "tips": "Tips for Better Sleep",
        "disorder": "When Sleep Becomes a Disorder",
        "brain": "Stress and the Brain",
        "memory": "Stress and Memory",
        "cognition": "Stress and Cognition",
        "immunity": "Immunity and Stress",
        "cardio": "Stress and the Heart",
        "gastro": "Stress and Digestion",
        "hormones": "Stress Hormones",
        "allsystems": "Stress Affects All Systems",
        "managing": "Managing Stress Day to Day",
        "howtostart": "How to Start Being Active",
        "recforadults": "Recommendations for Adults",
        "recforkids": "Recommendations for Children",
        "firststeps": "Your First Steps",
        "intensity": "Understanding Intensity",
        "movement": "Movement for Health",
        "motivation": "Finding Motivation",
        "push": "Push to Action"
    ]

    private static func title(for slug: String) -> String {
        if let override = titleOverrides[slug] { return override }
        let words = slug.replacingOccurrences(of: "-", with: "_").split(separator: "_").map(String.init)
        return words.map { word in
            if word.lowercased() == "hrv" { return "HRV" }
            if word.lowercased() == "ppg" { return "PPG" }
            if word.lowercased() == "ecg" { return "ECG" }
            if word.lowercased() == "aha" { return "AHA" }
            return word.prefix(1).uppercased() + word.dropFirst()
        }.joined(separator: " ")
    }

    private static func pages(for articleTitle: String, category: CategorySeed, index: Int) -> [ArticlePage] {
        let opening = "\(articleTitle) is part of the \(category.title) collection. This guide keeps the science practical and readable, so you can use it in daily life without turning every heartbeat into a test."
        let first = ArticlePage(
            title: articleTitle,
            subtitle: "A clear, practical guide",
            body: "\(opening)\n\nHeart health is a long game. The patterns you collect over days and weeks are more useful than any single reading. In this series we focus on what the measurement means, what can move it, and what to do next."
        )
        let second = ArticlePage(
            title: "Why it matters",
            subtitle: "Connect the signal to your daily life",
            body: "Your cardiovascular system responds constantly to sleep, movement, food, stress and recovery. That variability is not noise — it is information.\n\nWhen you pair a reading with context, you can see how your choices shape your baseline. A calm morning after a full night's sleep looks very different from an evening reading taken after a hard workout.\n\nUse the trend, not a single number. One unusual reading is rarely a reason to worry."
        )
        let third = ArticlePage(
            title: "What you can do",
            subtitle: "Small actions, repeated often",
            body: "• Measure at a similar time of day when you want to compare readings.\n• Tag each reading with what was happening around it.\n• Give yourself a few minutes of stillness before you start.\n• Look at weekly averages instead of reacting to every point.\n• Share persistent changes with a healthcare professional."
        )
        let fourth = ArticlePage(
            title: "When to seek help",
            subtitle: "Know the line between curiosity and concern",
            body: "Heartica is a wellness tool, not a medical device. It cannot diagnose or rule out a condition.\n\nSeek urgent care for chest pain, fainting, severe shortness of breath, or a sudden racing heartbeat that does not settle. For ongoing questions about your readings, talk with a clinician who knows your history."
        )
        let pages = [first, second, third, fourth]
        let count = min(2 + (index % 3), pages.count)
        return Array(pages.prefix(max(count, 2)))
    }

    private static func build() -> [ArticleCategory] {
        seeds.map { seed in
            let articles = seed.slugs.enumerated().map { index, slug in
                let articleTitle = title(for: slug)
                return Article(
                    id: "\(seed.id).\(slug)",
                    categoryID: seed.id,
                    title: articleTitle,
                    subtitle: seed.subtitle,
                    pages: pages(for: articleTitle, category: seed, index: index),
                    isPopular: seed.popular.contains(index),
                    sourceURL: URL(string: seed.source),
                    colorHex: seed.colorBase &+ UInt(index * 0x0E1B05) & 0xFFFFFF
                )
            }
            return ArticleCategory(
                id: seed.id,
                title: seed.title,
                subtitle: seed.subtitle,
                layout: seed.layout,
                articles: articles
            )
        }
    }
}
