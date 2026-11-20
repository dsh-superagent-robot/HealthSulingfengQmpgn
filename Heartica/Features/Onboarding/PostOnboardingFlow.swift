import SwiftUI

struct PostOnboardingFlow: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @AppStorage("postOnboardingCompleted") private var postOnboardingCompleted = false

    @State private var step: Step = .appleHealth
    @State private var quizIndex = 0
    @State private var answers: [Int?] = [nil, nil, nil]
    @State private var showDisclaimer = false
    @State private var progress: Double = 0
    @State private var calculationDone = false
    @State private var didConnectHealth = false

    // Editable profile copy for the review step.
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""

    enum Step: Int, CaseIterable {
        case appleHealth, sync, checkData, quiz, calculation, results
    }

    private let quiz: [QuizQuestion] = [
        QuizQuestion(title: "Has your doctor recommended tracking your heart rate or blood pressure?",
                     options: ["Yes", "No"], disclaimers: [false, false]),
        QuizQuestion(title: "How often do you feel anxious?",
                     options: ["Rarely", "Sometimes", "Often"], disclaimers: [false, false, true]),
        QuizQuestion(title: "Have you ever been diagnosed with high blood pressure or another heart condition?",
                     options: ["Yes", "No"], disclaimers: [false, false])
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            SoftOrbBackground(color: step == .results ? Theme.teal : Theme.accent)
            VStack(spacing: 0) {
                header
                Group {
                    switch step {
                    case .appleHealth: appleHealthStep
                    case .sync: syncStep
                    case .checkData: checkDataStep
                    case .quiz: quizStep
                    case .calculation: calculationStep
                    case .results: resultsStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                         removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .alert("Important", isPresented: $showDisclaimer) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text("Heartica is not a medical device and does not provide medical advice. It does not diagnose or treat high blood pressure, heart disease, or any medical condition. Always consult a healthcare professional for medical advice.")
        }
        .onAppear {
            ageText = store.profile.age.map(String.init) ?? ""
            heightText = store.profile.heightCm.map { Fmt.value($0, decimals: 0) } ?? ""
            weightText = store.profile.weightKg.map { Fmt.value($0, decimals: 0) } ?? ""
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                if step == .appleHealth || step == .results {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.heartGradient)
                        .font(.system(size: 18, weight: .semibold))
                } else {
                    Button {
                        previous()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                }
                Text("Heartica")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(stepLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(spacing: 5) {
                ForEach(Step.allCases, id: \.rawValue) { item in
                    Capsule()
                        .fill(item.rawValue <= step.rawValue ? Theme.accent : Theme.separator)
                        .frame(height: 3)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var stepLabel: String {
        switch step {
        case .appleHealth: return "Apple Health"
        case .sync: return "Syncing"
        case .checkData: return "Your details"
        case .quiz: return "Question \(quizIndex + 1) of 3"
        case .calculation: return "Analysis"
        case .results: return "Your results"
        }
    }

    // MARK: Apple Health

    private var appleHealthStep: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Theme.calmGradient)
                    .frame(height: 260)
                VStack(spacing: 18) {
                    HStack(spacing: 18) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 86, height: 86)
                            .background(.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 86, height: 86)
                            .background(.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    Text("Takes less than 10 seconds")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Get 2× More Health Data\nwith Apple Health")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Bring in watch measurements, HRV, workouts, mindfulness and sleep to make your insights richer.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 10) {
                    healthBenefit("Automatic HRV tracking", "waveform.path.ecg")
                    healthBenefit("Detailed health insights", "chart.line.uptrend.xyaxis")
                    healthBenefit("Sleep & activity integration", "moon.stars.fill")
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            Spacer()
            VStack(spacing: 10) {
                Button {
                    didConnectHealth = true
                    store.setAppleHealthConnected(true)
                    step = .sync
                } label: {
                    Text("Connect Apple Health")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button {
                    step = .checkData
                } label: {
                    Text("Proceed Without Apple Health")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func healthBenefit(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.teal)
                .frame(width: 26, height: 26)
                .background(Theme.teal.opacity(0.12))
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: Sync

    private var syncStep: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.teal.opacity(0.14), lineWidth: 12)
                    .frame(width: 160, height: 160)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.teal, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "heart.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.teal)
            }
            Text(progress >= 1 ? "Successfully Synced" : "Syncing with Apple Health…")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("We only access the data needed to provide your health insights.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .task {
            progress = 0
            withAnimation(.easeInOut(duration: 2.2)) { progress = 1 }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if step == .sync { step = .checkData }
        }
    }

    // MARK: Check data

    private var checkDataStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review your\npersonal information")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("We use age, gender, height and weight to personalize risk estimates and Heart Age.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        postField("Age", text: $ageText, keyboard: .numberPad)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Gender")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            Menu {
                                ForEach(Gender.allCases) { gender in
                                    Button(gender.title) { store.updateProfile(profileWith(gender: gender)) }
                                }
                            } label: {
                                HStack {
                                    Text(store.profile.gender == .none ? "Not Set" : store.profile.gender.title)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        postField("Height (cm)", text: $heightText, keyboard: .decimalPad)
                        postField("Weight (kg)", text: $weightText, keyboard: .decimalPad)
                    }
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").foregroundStyle(Theme.teal)
                        Text("Your details stay on this device.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text("This information comes from Apple Health when connected. Please edit anything that's incorrect.")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                saveProfileMetrics()
                step = .quiz
            } label: {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(Theme.background.opacity(0.96))
        }
    }

    private func profileWith(gender: Gender) -> Profile {
        var profile = store.profile
        profile.gender = gender
        return profile
    }

    private func postField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            TextField("—", text: text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .keyboardType(keyboard)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func saveProfileMetrics() {
        var profile = store.profile
        if let age = Int(ageText), age > 0, age <= 120 { profile.age = age }
        if let height = Double(heightText.replacingOccurrences(of: ",", with: ".")), height > 0, height <= 300 { profile.heightCm = height }
        if let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")), weight > 0, weight <= 500 { profile.weightKg = weight }
        store.updateProfile(profile)
    }

    // MARK: Quiz

    private var quizStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(quiz[quizIndex].title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("This helps us understand your starting point. It is not a diagnosis.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 30)

            VStack(spacing: 10) {
                ForEach(Array(quiz[quizIndex].options.enumerated()), id: \.offset) { index, option in
                    Button {
                        answers[quizIndex] = index
                        if quiz[quizIndex].disclaimers.indices.contains(index), quiz[quizIndex].disclaimers[index] {
                            showDisclaimer = true
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: answers[quizIndex] == index ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(answers[quizIndex] == index ? Theme.accent : Theme.separator)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 60)
                        .background(answers[quizIndex] == index ? Theme.accentSoft : Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(answers[quizIndex] == index ? Theme.accent.opacity(0.4) : Theme.separator.opacity(0.7), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Spacer()
            Button {
                if quizIndex < quiz.count - 1 {
                    withAnimation { quizIndex += 1 }
                } else {
                    step = .calculation
                }
            } label: {
                Text(quizIndex < quiz.count - 1 ? "Next" : "See My Analysis")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(answers[quizIndex] == nil)
            .opacity(answers[quizIndex] == nil ? 0.5 : 1)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Calculation

    private var calculationStep: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)
            ZStack {
                Circle()
                    .stroke(Theme.accent.opacity(0.12), lineWidth: 10)
                    .frame(width: 150, height: 150)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.heartGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                }
            }
            Text(calculationDone ? "All Set" : statusTitle)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(calculationDone ? "Thank you for your patience. You're incredible!" : statusSubtitle)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 35)
                .frame(height: 44)

            VStack(alignment: .leading, spacing: 10) {
                Text("DID YOU KNOW?")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Theme.accent)
                Text(calculationDone ? "Your first health insights are ready." : fact)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
            .padding(.horizontal, 24)

            Spacer()
            if calculationDone {
                Button {
                    step = .results
                } label: {
                    Text("See Results")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 54).padding(.bottom, 24)
            }
        }
        .task {
            guard !calculationDone else { return }
            progress = 0
            withAnimation(.linear(duration: 4.0)) { progress = 1 }
            try? await Task.sleep(nanoseconds: 4_200_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { calculationDone = true }
        }
    }

    private var statusTitle: String {
        switch progress {
        case ..<0.25: return "Building your profile…"
        case ..<0.5: return "Analyzing your data…"
        case ..<0.75: return "Reviewing patterns…"
        default: return "Preparing insights…"
        }
    }

    private var statusSubtitle: String {
        switch progress {
        case ..<0.25: return "Building your personal health profile"
        case ..<0.5: return "Analyzing your heart health data"
        case ..<0.75: return "Reviewing your activity patterns"
        default: return "Preparing your first health insights"
        }
    }

    private var fact: String {
        let facts = [
            "In about 4–5 days, your heart pumps a container's worth of blood.",
            "Your heart pumps about 2,000 gallons of blood every day.",
            "Your body produces over 2 million red blood cells every second.",
            "In one year, your blood vessels could stretch about 440,000–500,000 kilometers."
        ]
        return facts[min(Int(progress * 3.99), facts.count - 1)]
    }

    // MARK: Results

    private var resultsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Theme.heartGradient)
                        .padding(.top, 16)
                    Text("Your Heart Health\nRisk Score")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("A first look based on the information you shared.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 10) {
                    riskRow(title: "Age-Related Risk", subtitle: ageRiskSubtitle, value: ageRiskValue,
                            color: ageRiskValue == "High" ? Theme.orange : Theme.green, icon: "person.fill")
                    if answers[1] == 2 {
                        riskRow(title: "Stress & Anxiety Risk", subtitle: "Frequent anxiety", value: "High",
                                color: Theme.orange, icon: "brain.head.profile")
                    }
                    riskRow(title: "Blood Pressure", subtitle: "Not recorded", value: "No Data",
                            color: Theme.textTertiary, icon: "gauge.with.dots.needle.50percent")
                    riskRow(title: "Body Mass Index", subtitle: bmiSubtitle, value: bmiValue,
                            color: bmiColor, icon: "figure.stand")
                }

                Text("Heartica is not a medical device. These estimates are educational and do not replace advice from a healthcare professional.")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button {
                    finish(openMeasure: false)
                } label: {
                    Text("Start Your Journey")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    finish(openMeasure: true)
                } label: {
                    Text("Measure Heart Rate")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }

    private func riskRow(title: String, subtitle: String, value: String, color: Color, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private var ageRiskValue: String {
        guard let age = store.profile.age else { return "No Data" }
        return age >= 40 ? "High" : "Low"
    }

    private var ageRiskSubtitle: String {
        guard let age = store.profile.age else { return "Age not provided" }
        return age >= 40 ? "40 years or older" : "Under 40 years"
    }

    private var bmiValue: String {
        guard let bmi = store.profile.bmi else { return "No Data" }
        switch bmi {
        case ..<18.5: return "Low"
        case ..<25: return "Normal"
        case ..<30: return "Overweight"
        default: return "Obese"
        }
    }

    private var bmiSubtitle: String {
        guard let bmi = store.profile.bmi else { return "Add height and weight" }
        return String(format: "BMI %.1f", bmi)
    }

    private var bmiColor: Color {
        guard let bmi = store.profile.bmi else { return Theme.textTertiary }
        return bmi >= 18.5 && bmi < 25 ? Theme.green : Theme.amber
    }

    private func finish(openMeasure: Bool) {
        postOnboardingCompleted = true
        if openMeasure {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                router.showMeasure = true
            }
        }
    }

    private func previous() {
        switch step {
        case .appleHealth: break
        case .sync: step = .appleHealth
        case .checkData: step = didConnectHealth ? .sync : .appleHealth
        case .quiz:
            if quizIndex > 0 { quizIndex -= 1 } else { step = .checkData }
        case .calculation: step = .quiz
        case .results: step = .calculation
        }
    }
}

private struct QuizQuestion {
    var title: String
    var options: [String]
    var disclaimers: [Bool]
}
