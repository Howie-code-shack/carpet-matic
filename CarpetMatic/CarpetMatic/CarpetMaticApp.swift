import SwiftUI
import SwiftData

@main
struct CarpetMaticApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectListView()
        }
        .modelContainer(for: [
            ProjectModel.self,
            RoomModel.self,
        ])
    }
}
