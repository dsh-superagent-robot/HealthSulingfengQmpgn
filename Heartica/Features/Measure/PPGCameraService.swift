import Foundation
import AVFoundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class PPGCameraService: NSObject, ObservableObject {
    @Published private(set) var bpm: Int = 0
    @Published private(set) var signalQuality: Double = 0
    @Published private(set) var fingerDetected = false
    @Published private(set) var isSimulated = false
    @Published private(set) var cameraAuthorized = true
    @Published private(set) var isRunning = false

    private let session = AVCaptureSession()
    private let frameQueue = DispatchQueue(label: "heartica.ppg.frames")
    private var cameraPosition: AVCaptureDevice.Position = .back
    private var samples: [(time: TimeInterval, red: Double)] = []
    private var simulationTask: Task<Void, Never>?
    private var simulatedBase: Double = 72

    var captureSession: AVCaptureSession { session }

    func start() async {
        guard !isRunning else { return }
        isRunning = true
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            beginSimulation(reason: "Camera unavailable")
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                cameraAuthorized = false
                isRunning = false
                return
            }
        } else if status == .denied || status == .restricted {
            cameraAuthorized = false
            isRunning = false
            return
        }

        do {
            try configure(device: device)
            let captureSession = session
            frameQueue.async {
                captureSession.startRunning()
            }
        } catch {
            beginSimulation(reason: "Camera configuration failed")
        }
    }

    func stop() {
        isRunning = false
        simulationTask?.cancel()
        simulationTask = nil
        let captureSession = session
        frameQueue.async {
            if captureSession.isRunning { captureSession.stopRunning() }
        }
    }

    func forceSimulation() {
        stop()
        beginSimulation(reason: "User chose demo")
    }

    func switchCamera() {
        guard !isSimulated else { return }
        cameraPosition = cameraPosition == .back ? .front : .back
        stop()
        isRunning = false
        Task { await start() }
    }

    private func configure(device: AVCaptureDevice) throws {
        session.beginConfiguration()
        session.sessionPreset = .medium
        for input in session.inputs { session.removeInput(input) }
        for output in session.outputs { session.removeOutput(output) }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw NSError(domain: "Heartica.PPG", code: 1) }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: frameQueue)
        guard session.canAddOutput(output) else { throw NSError(domain: "Heartica.PPG", code: 2) }
        session.addOutput(output)
        session.commitConfiguration()

        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    private func beginSimulation(reason: String) {
        isSimulated = true
        cameraAuthorized = true
        simulatedBase = Double(Int.random(in: 68...80))
        simulationTask?.cancel()
        simulationTask = Task { @MainActor in
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { break }
                tick += 1
                let wave = sin(Double(tick) * 0.33) * 2.6 + cos(Double(tick) * 0.11) * 1.4
                let value = Int((simulatedBase + wave).rounded())
                bpm = min(max(value, 52), 96)
                signalQuality = 0.72 + 0.2 * abs(sin(Double(tick) * 0.2))
                fingerDetected = true
            }
        }
        _ = reason
    }

    private func process(red: Double, green: Double, blue: Double, at time: TimeInterval) {
        samples.append((time, red))
        if samples.count > 360 { samples.removeFirst(samples.count - 360) }
        let detected = red > 30 && red > green * 0.9 && red > blue * 1.05
        fingerDetected = detected
        signalQuality = detected ? min(1, abs(red - blue) / 120 + 0.2) : 0.1
        if detected {
            detectPulse()
        }
    }

    nonisolated static func averageColors(in pixelBuffer: CVPixelBuffer) -> (red: Double, green: Double, blue: Double)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bytes = base.assumingMemoryBound(to: UInt8.self)

        let step = 12
        let startX = max(0, width / 4)
        let endX = min(width, width * 3 / 4)
        let startY = max(0, height / 4)
        let endY = min(height, height * 3 / 4)
        var redTotal = 0.0
        var greenTotal = 0.0
        var blueTotal = 0.0
        var count = 0.0
        var x = startX
        while x < endX {
            var y = startY
            while y < endY {
                let offset = y * bytesPerRow + x * 4
                blueTotal += Double(bytes[offset])
                greenTotal += Double(bytes[offset + 1])
                redTotal += Double(bytes[offset + 2])
                count += 1
                y += step
            }
            x += step
        }
        guard count > 0 else { return nil }
        return (redTotal / count, greenTotal / count, blueTotal / count)
    }

    private func detectPulse() {
        guard samples.count > 40 else { return }
        let recent = Array(samples.suffix(220))
        guard let minTime = recent.first?.time, let maxTime = recent.last?.time, maxTime - minTime > 3 else { return }
        let mean = recent.map(\.red).reduce(0, +) / Double(recent.count)
        var peaks: [TimeInterval] = []
        var index = 1
        while index < recent.count - 1 {
            let previous = recent[index - 1].red
            let current = recent[index].red
            let next = recent[index + 1].red
            if current > mean && current > previous && current >= next {
                if let last = peaks.last, recent[index].time - last < 0.34 {
                    // Too close, keep the larger peak.
                } else {
                    peaks.append(recent[index].time)
                }
            }
            index += 1
        }
        guard peaks.count >= 3 else { return }
        let intervals = zip(peaks.dropFirst(), peaks).map { $0 - $1 }.filter { $0 > 0.33 && $0 < 1.8 }
        guard !intervals.isEmpty else { return }
        let sorted = intervals.sorted()
        let median = sorted[sorted.count / 2]
        let value = Int((60.0 / median).rounded())
        if value >= 40 && value <= 200 {
            bpm = value
            signalQuality = min(1, Double(intervals.count) / 6)
        }
    }
}

extension PPGCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        guard let rgb = Self.averageColors(in: pixelBuffer) else { return }
        Task { @MainActor [weak self] in
            self?.process(red: rgb.red, green: rgb.green, blue: rgb.blue, at: time)
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    var session: AVCaptureSession

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}
