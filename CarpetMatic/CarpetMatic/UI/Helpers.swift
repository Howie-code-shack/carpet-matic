import Foundation

enum DimensionFormat {
    static func metres(fromCM cm: Int) -> String {
        String(format: "%.2f", Double(cm) / 100.0)
    }

    static func parseMetresToCM(_ s: String) -> Int? {
        let trimmed = s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let m = Double(trimmed), m.isFinite, m >= 0 else { return nil }
        return Int((m * 100.0).rounded())
    }
}
