import Foundation
import UIKit
import CarpetMaticEngine

enum PDFExporter {
    struct Branding {
        let businessName: String
        let phone: String
        let email: String

        var contactLine: String {
            [phone, email]
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "  ·  ")
        }

        var isEmpty: Bool {
            businessName.trimmingCharacters(in: .whitespaces).isEmpty && contactLine.isEmpty
        }
    }

    static func makePDF(
        projectName: String,
        rollWidthMetres: Int,
        result: PackingResult,
        pricePerMetrePence: Int = 0,
        branding: Branding? = nil
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 at 72 dpi
        let margin: CGFloat = 48
        let contentWidth = pageRect.width - margin * 2
        let maxY = pageRect.height - margin
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            var cursorY: CGFloat = margin

            func breakPageIfNeeded(spaceNeeded: CGFloat) {
                if cursorY + spaceNeeded > maxY {
                    context.beginPage()
                    cursorY = margin
                }
            }

            func draw(_ text: String, font: UIFont) {
                breakPageIfNeeded(spaceNeeded: textHeight(text, width: contentWidth, font: font))
                cursorY = drawText(
                    text,
                    at: CGPoint(x: margin, y: cursorY),
                    width: contentWidth,
                    font: font
                )
            }

            if let branding, !branding.isEmpty {
                let name = branding.businessName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    draw(name, font: .boldSystemFont(ofSize: 15))
                }
                if !branding.contactLine.isEmpty {
                    draw(branding.contactLine, font: .systemFont(ofSize: 11))
                }
                cursorY += 14
            }

            draw(
                projectName.isEmpty ? "Untitled project" : projectName,
                font: .boldSystemFont(ofSize: 24)
            )
            cursorY += 12

            let dateString = Date.now.formatted(date: .abbreviated, time: .omitted)
            draw("Roll width: \(rollWidthMetres) m  ·  \(dateString)", font: .systemFont(ofSize: 14))
            cursorY += 4

            draw(
                String(format: "Total carpet: %.2f m", result.totalLengthMetres),
                font: .boldSystemFont(ofSize: 16)
            )
            cursorY += 2

            let rollWidthCM = rollWidthMetres * 100
            draw(
                String(
                    format: "Offcut: %.2f m² (%.0f%%)",
                    result.wasteAreaMetresSquared(rollWidthCM: rollWidthCM),
                    result.wasteFraction(rollWidthCM: rollWidthCM) * 100
                ),
                font: .systemFont(ofSize: 13)
            )

            if pricePerMetrePence > 0 {
                cursorY += 2
                let estimatePence = (pricePerMetrePence * result.totalLengthCM + 50) / 100
                draw(
                    "Estimate: \(MoneyFormat.display(pence: estimatePence))"
                        + "  (\(MoneyFormat.display(pence: pricePerMetrePence))/m)",
                    font: .boldSystemFont(ofSize: 14)
                )
            }
            cursorY += 16

            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let stripFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)

            for breakdown in result.perRoom {
                let header = breakdown.kind == .stairs
                    ? "\(breakdown.roomName) — stairs (\(breakdown.strips.count) strip\(breakdown.strips.count == 1 ? "" : "s"))"
                    : "\(breakdown.roomName) (\(breakdown.strips.count) strip\(breakdown.strips.count == 1 ? "" : "s"))"

                // Keep the room header together with at least its first strip line.
                var headerSpace = textHeight(header, width: contentWidth, font: headerFont) + 2
                if let firstStrip = breakdown.strips.first {
                    headerSpace += textHeight(stripLine(firstStrip), width: contentWidth, font: stripFont)
                }
                breakPageIfNeeded(spaceNeeded: headerSpace)

                draw(header, font: headerFont)
                cursorY += 2

                for strip in breakdown.strips {
                    draw(stripLine(strip), font: stripFont)
                }

                cursorY += 8
            }
        }
    }

    private static func stripLine(_ strip: StripPlacement) -> String {
        String(
            format: "    %.2f × %.2f m   pile: %@",
            Double(strip.widthCM) / 100.0,
            Double(strip.lengthCM) / 100.0,
            strip.pileDirection.rawValue
        )
    }

    private static func textHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let bounded = attributed(text, font: font).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(bounded.height) + 4
    }

    @discardableResult
    private static func drawText(
        _ text: String,
        at origin: CGPoint,
        width: CGFloat,
        font: UIFont
    ) -> CGFloat {
        let attributed = attributed(text, font: font)
        let bounded = attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let drawRect = CGRect(origin: origin, size: CGSize(width: width, height: bounded.height))
        attributed.draw(with: drawRect,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil)
        return origin.y + ceil(bounded.height) + 4
    }

    private static func attributed(_ text: String, font: UIFont) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.black,
        ])
    }
}
