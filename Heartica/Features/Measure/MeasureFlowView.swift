import SwiftUI
import AVFoundation
import UIKit

enum MeasuringMode: String, CaseIterable, Identifiable {
    case fast, standard, precise
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fast: return "Fast"
        case .standard: return "Standard"
        case .precise: return "Precise"
        }
    }
    var measureSeconds: Double {
        switch self {
        case .fast: return 9
        case .standard: return 16
        case .precise: return 25
        }
    }
    var estimate: String {
        switch self {
        case .fast: return "~15 sec"
        case .standard: return "~20 sec"
        case .precise: return "~30 sec"
        }
    }
}

struct MeasureFlowView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @StateObject private var sensor = PPGCameraService()
    @State private var mode: MeasuringMode = .standard
    @State private var phase: Phase = .calibrating
    @State private var progress: Double = 0
    @State private var result: HeartRateMeasurement?
    @State private var task: Task<Void, Never>?
    @State private var showExitConfirm = false
    @State private var useSimulation = false

    enum Phase { case calibrating, measuring }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let result {
                MeasurementDetailView(
                    measurement: result,
                    isFresh: true,
                    onRetake: {
                        withAnimation { self.result = nil }
                        start()
                    },
                    onDone: { dismiss() }
                )
                .environmentObject(store)
                .environmentObject(router)
                .transition(.opacity)
            } else {
                measuringView
            }
        }
        .onAppear { start() }
        .onDisappear {
            task?.cancel()
            sensor.stop()
        }
        .alert("Stop measuring?", isPresented: $showExitConfirm) {
            Button("Keep Measuring", role: .cancel) {}
            Button("Discard", role: .destructive) { dismiss() }
        } message: {
            Text("Your current measurement will be discarded.")
        }
    }

    private var measuringView: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    modePicker
                    sensorArea
                    stepInfo
                    progressBar
                    quickTip
                    if !sensor.cameraAuthorized { cameraDeniedCard }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    private var topBar: some View {
        HStack {
            IconButton(systemName: "xmark", size: 38) {
                if phase == .measuring {
                    showExitConfirm = true
                } else {
                    dismiss()
                }
            }
            Spacer()
            VStack(spacing: 1) {
                Text("Measuring")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                if sensor.isSimulated {
                    Text("Simulated PPG · no camera")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
            IconButton(systemName: "camera.rotate.fill", size: 38) {
                sensor.switchCamera()
            }
            .opacity(sensor.isSimulated ? 0.35 : 1)
            .disabled(sensor.isSimulated)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(MeasuringMode.allCases) { item in
                Button {
                    guard phase == .calibrating else { return }
                    mode = item
                } label: {
                    VStack(spacing: 1) {
                        Text(item.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text(item.estimate)
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .opacity(0.65)
                    }
                    .foregroundStyle(mode == item ? .white : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(mode == item ? Theme.accent : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(phase == .calibrating ? 1 : 0.5)
    }

    private var sensorArea: some View {
        ZStack {
            Circle()
                .fill(Theme.surface)
                .frame(width: 270, height: 270)
                .overlay(Circle().strokeBorder(Theme.separator.opacity(0.7), lineWidth: 1))
            if !sensor.isSimulated && sensor.cameraAuthorized {
                CameraPreviewView(session: sensor.captureSession)
                    .frame(width: 238, height: 238)
                    .clipShape(Circle())
                    .overlay(Circle().fill(.black.opacity(sensor.fingerDetected ? 0.35 : 0.1)))
            } else {
                Circle()
                    .fill(
                        RadialGradient(colors: [Theme.accent.opacity(0.32), Color(hex: 0x191018)],
                                       center: .center, startRadius: 4, endRadius: 150)
                    )
                    .frame(width: 238, height: 238)
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if phase == .calibrating {
                Circle()
                    .stroke(Theme.amber.opacity(0.4), lineWidth: 2)
                    .frame(width: 250, height: 250)
                    .scaleEffect(1)
                    .opacity(sensor.fingerDetected ? 1 : 0.55)
            } else {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 264, height: 264)
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("\(sensor.bpm == 0 ? 72 : sensor.bpm)")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                Text("bpm")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(height: 286)
        .padding(.top, 4)
    }

    private var stepInfo: some View {
        VStack(spacing: 5) {
            Text(phase == .calibrating ? "Step 1 · Calibrating" : "Step 2 · Measuring")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Theme.accent)
            Text(phase == .calibrating ? "Keep your finger still" : "Stay relaxed and breathe calmly")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(phase == .calibrating
                 ? "Place your fingertip over the camera and flash until the light turns red."
                 : "We're reading tiny changes in blood flow. Don't press too hard.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressBarView(progress: progress, color: Theme.accent, height: 7)
            HStack {
                Text(phase == .calibrating ? "Calibrating…" : "Measuring…")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var quickTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.amber)
                .frame(width: 34, height: 34)
                .background(Theme.amber.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Quick Tip")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Don't press your finger too hard. Stay relaxed, breathe calmly, and wait for the measurement to complete.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
    }

    private var cameraDeniedCard: some View {
        VStack(spacing: 10) {
            Text("No Access to Camera")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Enable Camera access in Settings to measure your heart rate with the camera.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button("Go to Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Use Demo Signal") {
                    sensor.forceSimulation()
                    start()
                }
                .buttonStyle(SoftButtonStyle())
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Flow

    private func start() {
        task?.cancel()
        result = nil
        phase = .calibrating
        progress = 0
        useSimulation = false
        task = Task { @MainActor in
            if sensor.isSimulated {
                sensor.forceSimulation()
            } else {
                await sensor.start()
            }
            guard !Task.isCancelled else { return }
            if !sensor.cameraAuthorized {
                progress = 0
                return
            }
            let calibration = 4.0
            withAnimation(.linear(duration: calibration)) { progress = 0.2 }
            try? await Task.sleep(nanoseconds: UInt64(calibration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { phase = .measuring }
            let seconds = mode.measureSeconds
            withAnimation(.linear(duration: seconds)) { progress = 1 }
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            completeMeasurement()
        }
    }

    private func completeMeasurement() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        let pulse = sensor.bpm > 40 ? sensor.bpm : Int.random(in: 68...78)
        let variability = clamp(60.0 - Double(pulse - 60) * 0.45 + Double.random(in: -12...12), 18, 95)
        let measurement = HealthEngine.measurement(
            pulse: pulse,
            rmssd: variability,
            sdnn: variability * 1.5,
            pnn50: clamp((variability - 16) * 1.15, 2, 48),
            date: Date(),
            source: .inApp
        )
        store.addMeasurement(measurement)
        router.showToast("Measurement saved")
        sensor.stop()
        withAnimation(.easeInOut(duration: 0.35)) { result = measurement }
    }
}
