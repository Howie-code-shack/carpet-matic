import Foundation
import SwiftData

/// The fitter's business details, printed on exported PDFs.
/// Intended as a singleton row; `createdAt` lets callers pick the oldest
/// deterministically if CloudKit sync ever races two devices into creating one each.
@Model
final class BusinessProfileModel {
    var businessName: String = ""
    var phone: String = ""
    var email: String = ""
    var createdAt: Date = Date()

    init() {}

    var isEmpty: Bool {
        businessName.trimmingCharacters(in: .whitespaces).isEmpty
            && phone.trimmingCharacters(in: .whitespaces).isEmpty
            && email.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
