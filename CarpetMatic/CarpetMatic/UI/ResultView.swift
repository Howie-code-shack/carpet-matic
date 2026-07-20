import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CarpetMaticEngine

struct ResultView: View {
    let project: ProjectModel

    @Environment(StoreManager.self) private var store
    @Query(sort: \BusinessProfileModel.createdAt)
    private var businessProfiles: [BusinessProfileModel]
    @State private var showingPaywall = false

    @State private var result: PackingResult?
    @State private var errorMessage: String?
    @State private var exportDocument: PDFExportDocument?
    @State private var showingExporter = false
    @State private var exportErrorMessage: String?

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
                        Text("Total carpet")
                            .font(.title3)
                        Spacer()
                        Text("\(DimensionFormat.metres(fromCM: result.totalLengthCM)) m")
                            .font(.title2.bold())
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Offcut")
                        Spacer()
                        Text(String(
                            format: "%.2f m² · %.0f%%",
                            result.wasteAreaMetresSquared(rollWidthCM: rollWidthCM),
                            result.wasteFraction(rollWidthCM: rollWidthCM) * 100
                        ))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                    if project.pricePerMetrePence > 0 {
                        HStack {
                            Text("Estimate")
                            Spacer()
                            Text(MoneyFormat.display(pence: estimatePence(for: result)))
                                .bold()
                                .monospacedDigit()
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Underlay")
                        Spacer()
                        Text(String(format: "%.1f m²", Double(engineProject.totalRoomAreaCM2) / 10_000.0))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Gripper")
                        Spacer()
                        Text(String(format: "%.1f m", Double(engineProject.gripperPerimeterCM) / 100.0))
                            .monospacedDigit()
                    }
                } header: {
                    Text("Materials")
                } footer: {
                    if (project.rooms ?? []).contains(where: { $0.kind == .stairs }) {
                        Text("Gripper excludes stairs — measure per step.")
                    }
                }

                Section {
                    NavigationLink {
                        RollLayoutView(result: result, rollWidthCM: rollWidthCM)
                    } label: {
                        Label("View roll layout", systemImage: "rectangle.split.3x1")
                    }
                }

                ForEach(result.perRoom, id: \.roomID) { breakdown in
                    Section {
                        ForEach(breakdown.strips, id: \.id) { strip in
                            HStack {
                                Text("\(DimensionFormat.metres(fromCM: strip.widthCM)) × \(DimensionFormat.metres(fromCM: strip.lengthCM)) m")
                                    .monospacedDigit()
                                Spacer()
                                PileArrowView(direction: strip.pileDirection)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(
                                "Strip \(DimensionFormat.metres(fromCM: strip.widthCM)) by \(DimensionFormat.metres(fromCM: strip.lengthCM)) metres, pile \(strip.pileDirection.rawValue)"
                            )
                        }
                    } header: {
                        HStack {
                            Text(breakdown.roomName)
                            Spacer()
                            Text("\(breakdown.strips.count) strip\(breakdown.strips.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if breakdown.kind == .stairs {
                                Text("· stairs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        if store.isPro {
                            prepareExport()
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        HStack {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                            if !store.isPro {
                                Spacer()
                                Text("Pro")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                            }
                        }
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
        .task(id: calculationFingerprint) {
            recalculate()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: defaultFilename
        ) { outcome in
            if case .failure(let error) = outcome {
                exportErrorMessage = error.localizedDescription
            }
        }
        .alert(
            "Export failed",
            isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    /// Changes whenever any input to the calculation changes, so `.task(id:)`
    /// recomputes while the view stays on screen (e.g. edits synced from
    /// another device).
    private var calculationFingerprint: Int {
        var hasher = Hasher()
        hasher.combine(project.rollWidthMetres)
        hasher.combine(project.patternRepeatCM)
        let rooms = (project.rooms ?? []).sorted { $0.id.uuidString < $1.id.uuidString }
        for room in rooms {
            hasher.combine(room.id)
            hasher.combine(room.name)
            hasher.combine(room.widthCM)
            hasher.combine(room.lengthCM)
            hasher.combine(room.kindRaw)
            hasher.combine(room.pileDirectionRaw)
        }
        return hasher.finalize()
    }

    private var rollWidthCM: Int {
        project.rollWidthMetres * 100
    }

    private var engineProject: CarpetMaticEngine.Project {
        project.toEngine()
    }

    /// price/m (pence) × length (cm) ÷ 100, rounded to the nearest penny.
    private func estimatePence(for result: PackingResult) -> Int {
        (project.pricePerMetrePence * result.totalLengthCM + 50) / 100
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
        let branding = businessProfiles.first.map {
            PDFExporter.Branding(businessName: $0.businessName, phone: $0.phone, email: $0.email)
        }
        let engineProject = engineProject
        let data = PDFExporter.makePDF(
            projectName: project.name,
            rollWidthMetres: project.rollWidthMetres,
            result: result,
            pricePerMetrePence: project.pricePerMetrePence,
            branding: branding,
            patternRepeatCM: project.patternRepeatCM,
            underlayAreaCM2: engineProject.totalRoomAreaCM2,
            gripperCM: engineProject.gripperPerimeterCM
        )
        exportDocument = PDFExportDocument(data: data)
        showingExporter = true
    }

    private func describe(_ error: PackingError) -> String {
        switch error {
        case .invalidRollWidthMetres(let m):
            return "Invalid roll width: \(m) m. Must be one of 1, 2, 3, 4, 5."
        case .invalidRoomDimensions(let roomID):
            let name = (project.rooms ?? [])
                .first { $0.id == roomID }
                .map { $0.name.isEmpty ? "Untitled" : $0.name }
            if let name {
                return "“\(name)” is missing its dimensions. Enter both width and length."
            }
            return "A room has invalid dimensions. Edit and enter both width and length."
        }
    }
}
