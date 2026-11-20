import Foundation

enum HealthEngine {
    /// Builds a full measurement from the pulse and HRV values captured by the
    /// measurement pipeline. Stress / energy / health index are derived from the
    /// NN intervals as described by the product specification.
    static func measurement(
        pulse: Int,
        rmssd: Double,
        sdnn: Double? = nil,
        pnn50: Double? = nil,
        csi: Int? = nil,
        date: Date = Date(),
        tagID: String? = nil,
        source: MeasurementSource = .inApp,
        healthKitID: String? = nil
    ) -> HeartRateMeasurement {
        let safeRMSSD = max(rmssd, 1)
        let derivedSDNN = sdnn ?? safeRMSSD * 1.55
        let lnRMSSD = log(safeRMSSD)
        let energy = clamp((lnRMSSD - 3.2) * 45 + 55, 15, 118)
        let stress = clamp(95 - derivedSDNN * 0.6, 8, 95)
        let derivedPnn50 = pnn50 ?? clamp((safeRMSSD - 15) * 1.3, 1, 55)
        let derivedCSI = csi ?? Int(clamp(8500 / safeRMSSD, 20, 650).rounded())
        return HeartRateMeasurement(
            date: date,
            pulse: pulse,
            rmssd: safeRMSSD,
            sdnn: derivedSDNN,
            pnn50: derivedPnn50,
            energy: energy,
            stress: stress,
            healthIndex: lnRMSSD,
            csi: derivedCSI,
            source: source,
            tagID: tagID,
            healthKitID: healthKitID
        )
    }

    /// A small seeded generator keeps demo content stable between launches.
    struct SeededRandom {
        private var state: UInt64
        init(seed: UInt64 = 0xF20F1A) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
        mutating func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let value = Double((state >> 33) & 0xFFFF_FFFF)
            return value / Double(0xFFFF_FFFF)
        }
        mutating func range(_ low: Double, _ high: Double) -> Double {
            low + (high - low) * next()
        }
        mutating func int(_ low: Int, _ high: Int) -> Int {
            Int(range(Double(low), Double(high)).rounded())
        }
    }

    static func randomMeasurement(seed: UInt64, date: Date = Date(), tagID: String? = nil) -> HeartRateMeasurement {
        var rng = SeededRandom(seed: seed)
        let pulse = rng.int(62, 84)
        let rmssd = rng.range(34, 78)
        let sdnn = rmssd * rng.range(1.2, 1.7)
        let pnn50 = clamp((rmssd - 18) * rng.range(0.9, 1.35), 2, 52)
        let m = measurement(
            pulse: pulse,
            rmssd: rmssd,
            sdnn: sdnn,
            pnn50: pnn50,
            date: date,
            tagID: tagID
        )
        return m
    }
}

enum GlucoseUnit: String, CaseIterable, Identifiable {
    case mgdl, mmol
    var id: String { rawValue }
    var title: String { self == .mgdl ? "mg/dL" : "mmol/L" }
    var shortTitle: String { self == .mgdl ? "mg/dL" : "mmol/L" }

    static func mmolValues() -> [Double] {
        var seen = Set<Double>()
        var values: [Double] = []
        for mg in 50...250 {
            let raw = (Double(mg) / 18.0 * 10.0)
            let truncated = (raw >= 0 ? floor(raw) : ceil(raw)) / 10.0
            if seen.insert(truncated).inserted {
                values.append(truncated)
            }
        }
        return values
    }

    static let mmolRange = mmolValues()
}
