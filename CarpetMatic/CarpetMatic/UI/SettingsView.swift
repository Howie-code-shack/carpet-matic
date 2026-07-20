import SwiftUI
import SwiftData

/// Business details printed in the PDF header. Stored in SwiftData so they
/// sync across the user's devices like everything else.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BusinessProfileModel.createdAt) private var profiles: [BusinessProfileModel]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Business name", text: binding(\.businessName))
                    TextField("Phone", text: binding(\.phone))
                        .keyboardType(.phonePad)
                    TextField("Email", text: binding(\.email))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Business details")
                } footer: {
                    Text("Shown at the top of exported PDFs. Leave blank to omit.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// The singleton profile row: oldest existing one, created on first write.
    private var profile: BusinessProfileModel {
        if let existing = profiles.first { return existing }
        let created = BusinessProfileModel()
        modelContext.insert(created)
        return created
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<BusinessProfileModel, String>) -> Binding<String> {
        Binding(
            get: { profiles.first?[keyPath: keyPath] ?? "" },
            set: { profile[keyPath: keyPath] = $0 }
        )
    }
}
