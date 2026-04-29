import Foundation
import UIKit
import CarpetMaticEngine

enum PDFExporter {
    static func makePDF(
        projectName: String,
        rollWidthMetres: Int,
        result: PackingResult
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 at 72 dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            var cursorY: CGFloat = 48
            let leftMargin: CGFloat = 48
            let rightMargin: CGFloat = pageRect.width - 48

            cursorY = drawText(
                projectName.isEmpty ? "Untitled project" : projectName,
                at: CGPoint(x: leftMargin, y: cursorY),
                width: rightMargin - leftMargin,
                font: .boldSystemFont(ofSize: 24)
            )
            cursorY += 12

            cursorY = drawText(
                "Roll width: \(rollWidthMetres) m",
                at: CGPoint(x: leftMargin, y: cursorY),
                width: rightMargin - leftMargin,
                font: .systemFont(ofSize: 14)
            )
            cursorY += 4

            let totalString = String(format: "Total carpet: %.2f m", result.totalLengthMetres)
            cursorY = drawText(
                totalString,
                at: CGPoint(x: leftMargin, y: cursorY),
                width: rightMargin - leftMargin,
                font: .boldSystemFont(ofSize: 16)
            )
            cursorY += 16

            for breakdown in result.perRoom {
                let header = breakdown.kind == .stairs
                    ? "\(breakdown.roomName) — stairs"
                    : breakdown.roomName
                cursorY = drawText(
                    header,
                    at: CGPoint(x: leftMargin, y: cursorY),
                    width: rightMargin - leftMargin,
                    font: .boldSystemFont(ofSize: 14)
                )
                cursorY += 2

                for placement in breakdown.pieces {
                    let line = String(
                        format: "    %.2f × %.2f m   pile: %@",
                        Double(placement.widthCM) / 100.0,
                        Double(placement.lengthCM) / 100.0,
                        placement.pileDirection.rawValue
                    )
                    cursorY = drawText(
                        line,
                        at: CGPoint(x: leftMargin, y: cursorY),
                        width: rightMargin - leftMargin,
                        font: .monospacedSystemFont(ofSize: 12, weight: .regular)
                    )
                }

                cursorY += 8
            }
        }
    }

    @discardableResult
    private static func drawText(
        _ text: String,
        at origin: CGPoint,
        width: CGFloat,
        font: UIFont
    ) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
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
}
