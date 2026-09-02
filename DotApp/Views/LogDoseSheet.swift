import SwiftData
import SwiftUI

struct LogDoseSheet: View {
    private enum Phase {
        case choose
        case addMedication
        case confirmed
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let profile: Profile
    let medications: [Medication]
    let onViewStatus: () -> Void

    @State private var phase: Phase = .choose
    @State private var selectedMedicationID: UUID?
    @State private var loggedAt: Date?

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .choose:
                    chooser
                case .addMedication:
                    AddMedicationView(profileID: profile.id) { medication in
                        selectedMedicationID = medication.id
                        phase = .choose
                    }
                case .confirmed:
                    confirmation
                }
            }
            .toolbar {
                if phase != .addMedication {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var chooser: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a medicine")
                .font(.title.bold())
            Text("For \(profile.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if medications.isEmpty {
                ContentUnavailableView(
                    "No medicines yet",
                    systemImage: "pills",
                    description: Text("Add the medicine using its pharmacist label or packet.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(medications) { medication in
                            Button {
                                selectedMedicationID = medication.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(medication.name).font(.headline)
                                        Text(medication.displayDose)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedMedicationID == medication.id ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selectedMedicationID == medication.id ? Color.primary : Color.clear, lineWidth: 2)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selectedMedicationID == medication.id ? .isSelected : [])
                        }
                    }
                }
            }

            Button {
                phase = .addMedication
            } label: {
                Label("Add medication", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("add-medication-from-log")

            Button(action: logDose) {
                Label("Log dose now", systemImage: "checkmark")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .disabled(selectedMedicationID == nil)
            .accessibilityIdentifier("log-dose-now")
        }
        .padding(20)
    }

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dose logged")
                .font(.title.bold())
            if let loggedAt {
                Label("Recorded at \(DotFormatters.time(loggedAt))", systemImage: "checkmark.circle")
                    .font(.title3.weight(.semibold))
            }
            Text("The status is based only on the limits you entered.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("View status", action: onViewStatus)
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("view-status")
        }
        .padding(20)
    }

    private func logDose() {
        guard let selectedMedicationID else { return }
        let timestamp = Date.now
        modelContext.insert(DoseLog(medicationID: selectedMedicationID, timestamp: timestamp))
        loggedAt = timestamp
        phase = .confirmed
    }
}
