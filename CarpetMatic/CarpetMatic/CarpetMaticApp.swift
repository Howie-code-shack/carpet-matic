import SwiftUI
import SwiftData

@main
struct CarpetMaticApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([ProjectModel.self, RoomModel.self, BusinessProfileModel.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.howie.one.CarpetMatic")
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ProjectListView()
        }
        .modelContainer(modelContainer)
    }
}
