import Foundation
import SwiftData

@Model
final class ProjectModel {
    var id: UUID = UUID()
    var name: String = ""
    var rollWidthMetres: Int = 4
    var createdAt: Date = Date()
    /// Price per linear metre in pence (integer, like cm for dimensions —
    /// avoids float drift across CloudKit). 0 = not set; estimate hidden.
    var pricePerMetrePence: Int = 0
    /// Pattern repeat in cm; 0 = plain carpet. Strips' cut lengths round up
    /// to the next repeat multiple when set.
    var patternRepeatCM: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \RoomModel.project)
    var rooms: [RoomModel]? = []

    init(name: String = "", rollWidthMetres: Int = 4) {
        self.name = name
        self.rollWidthMetres = rollWidthMetres
    }
}
