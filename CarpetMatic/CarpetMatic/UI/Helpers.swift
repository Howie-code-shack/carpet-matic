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

enum MoneyFormat {
    static var currencySymbol: String {
        Locale.current.currencySymbol ?? "£"
    }

    /// "12.50" from 1250 pence (no symbol — for text fields).
    static func pounds(fromPence pence: Int) -> String {
        String(format: "%.2f", Double(pence) / 100.0)
    }

    /// "£12.50" from 1250 pence.
    static func display(pence: Int) -> String {
        "\(currencySymbol)\(pounds(fromPence: pence))"
    }

    /// Parse "12.50" (or "12,50") to 1250 pence. Same rules as dimensions.
    static func parsePoundsToPence(_ s: String) -> Int? {
        let trimmed = s
            .replacingOccurrences(of: currencySymbol, with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let pounds = Double(trimmed), pounds.isFinite, pounds >= 0 else { return nil }
        return Int((pounds * 100.0).rounded())
    }
}
