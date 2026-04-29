import Foundation
import SwiftData

@Model
final class ProjectModel {
    var id: UUID = UUID()
    var name: String = ""
    var rollWidthMetres: Int = 4
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \RoomModel.project)
    var rooms: [RoomModel]? = []

    init(name: String = "", rollWidthMetres: Int = 4) {
        self.name = name
        self.rollWidthMetres = rollWidthMetres
    }
}
