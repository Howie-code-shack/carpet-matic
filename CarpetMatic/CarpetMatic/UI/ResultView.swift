import SwiftUI
import UniformTypeIdentifiers
import CarpetMaticEngine

struct ResultView: View {
    let project: ProjectModel

    @State private var result: PackingResult?
    @State private var errorMessage: String?
    @State private var exportDocument: PDFExportDocument?
    @State private var showingExporter = false

    var body: some View {
        Form {
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            } else if let result {
                Section {
                    HStack {
                        Text("Total")
                            .font(.title3)
                        Spacer()
                        Text("\(DimensionFormat.metres(fromCM: result.totalLengthCM)) m")
                            .font(.title2.bold())
                            .monospacedDigit()
                    }
                }

                ForEach(result.perRoom, id: \.roomID) { breakdown in
                    Section {
                        ForEach(breakdown.pieces, id: \.pieceID) { placement in
                            HStack {
                                Text("\(DimensionFormat.metres(fromCM: placement.widthCM)) × \(DimensionFormat.metres(fromCM: placement.lengthCM)) m")
                                    .monospacedDigit()
                                Spacer()
                                PileArrowView(direction: placement.pileDirection)
                            }
                        }
                    } header: {
                        HStack {
                            Text(breakdown.roomName)
                            if breakdown.kind == .stairs {
                                Text("· stairs")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                }
            } else {
                Section {
                    ProgressView("Calculating…")
                }
            }
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: project.id) {
            recalculate()
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: defaultFilename
        ) { _ in }
    }

    private var defaultFilename: String {
        let trimmed = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Project" : trimmed
    }

    private func recalculate() {
        do {
            let engineProject = project.toEngine()
            result = try PackingEngine.pack(engineProject)
            errorMessage = nil
        } catch let error as PackingError {
            errorMessage = describe(error)
            result = nil
        } catch {
            errorMessage = "\(error)"
            result = nil
        }
    }

    private func prepareExport() {
        guard let result else { return }
        let data = PDFExporter.makePDF(projectName: project.name,
                                       rollWidthMetres: project.rollWidthMetres,
                                       result: result)
        exportDocument = PDFExportDocument(data: data)
        showingExporter = true
    }

    private func describe(_ error: PackingError) -> String {
        switch error {
        case .invalidRollWidthMetres(let m):
            return "Invalid roll width: \(m) m. Must be one of 1, 2, 3, 4, 5."
        case .pieceWiderThanRoll(_, let pieceWidthCM, let rollWidthCM):
            return "A piece is \(DimensionFormat.metres(fromCM: pieceWidthCM)) m wide; the roll is only \(DimensionFormat.metres(fromCM: rollWidthCM)) m. Edit or rotate the piece."
        case .nonPositiveDimension:
            return "A piece has a zero or negative dimension. Edit it before calculating."
        }
    }
}
