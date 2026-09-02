import SwiftData
import SwiftUI

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let profileID: UUID
    var onSave: ((Medication) -> Void)?

    @State private var draft = MedicationDraft()
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, amount, maximum, gap
    }

    init(profileID: UUID, onSave: ((Medication) -> Void)? = nil) {
        self.profileID = profileID
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Use the pharmacist label or packet. Dot checks only the limits you enter here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Medicine") {
                    TextField("Name", text: $draft.name)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .accessibilityIdentifier("medication-name")

                    TextField("Dose amount", text: $draft.doseAmount)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .accessibilityIdentifier("medication-dose")

                    Picker("Unit", selection: $draft.unit) {
                        ForEach(DoseUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                }

                Section("Limits from the label") {
                    TextField("Maximum doses in rolling 24 hours", text: $draft.maximumDoses)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .maximum)
                        .accessibilityIdentifier("medication-maximum")
                    TextField("Minimum gap in hours", text: $draft.minimumGapHours)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .gap)
                        .accessibilityIdentifier("medication-gap")
                }

                Section {
                    Button("Save medication", action: save)
                        .disabled(draft.validatedValues == nil)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("save-medication")
                } footer: {
                    Text("All fields must contain positive values. Dot does not add or verify clinical recommendations.")
                }
            }
            .navigationTitle("Add medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focusedField = .name }
        }
    }

    private func save() {
        guard let values = draft.validatedValues else { return }
        let medication = Medication(
            profileID: profileID,
            name: values.name,
            doseAmount: values.doseAmount,
            doseUnit: values.unit,
            maximumDosesPerRolling24Hours: values.maximumDoses,
            minimumGapHours: values.minimumGapHours
        )
        modelContext.insert(medication)
        if let onSave {
            onSave(medication)
        } else {
            dismiss()
        }
    }
}
