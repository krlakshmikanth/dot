import SwiftData
import SwiftUI

struct LogDoseSheet: View {
    private enum Phase {
        case choose
        case addMedication
        case review
        case planned
        case confirmed
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let profile: Profile
    let medications: [Medication]
    let doseLogs: [DoseLog]
    let plannedDose: PlannedDose?
    let onViewHistory: () -> Void

    @State private var phase: Phase
    @State private var selectedMedicationID: UUID?
    @State private var createdPlan: PlannedDose?
    @State private var loggedAt: Date?

    init(
        profile: Profile,
        medications: [Medication],
        doseLogs: [DoseLog],
        plannedDose: PlannedDose?,
        onViewHistory: @escaping () -> Void
    ) {
        self.profile = profile
        self.medications = medications
        self.doseLogs = doseLogs
        self.plannedDose = plannedDose
        self.onViewHistory = onViewHistory
        _phase = State(initialValue: plannedDose == nil ? .choose : .planned)
        _selectedMedicationID = State(initialValue: plannedDose?.medicationID)
        _createdPlan = State(initialValue: plannedDose)
    }

    private var selectedMedication: Medication? {
        guard let selectedMedicationID else { return nil }
        return medications.first { $0.id == selectedMedicationID }
    }

    private var assessment: DoseLimitAssessment? {
        guard let selectedMedication else { return nil }
        return DoseLimitEvaluator.assess(
            timestamps: doseLogs
                .filter { $0.medicationID == selectedMedication.id && !$0.isUncertain }
                .map(\.timestamp),
            configuration: DoseConfiguration(
                maximumDosesPerRolling24Hours: selectedMedication.maximumDosesPerRolling24Hours,
                minimumGapHours: selectedMedication.minimumGapHours
            ),
            now: .now
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .choose:
                    chooser
                case .addMedication:
                    AddMedicationView(profileID: profile.id) { medication in
                        selectedMedicationID = medication.id
                        phase = .review
                    }
                case .review:
                    review
                case .planned:
                    plannedConfirmation
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
            Text("For \(profile.name). Planning does not mean the dose was taken.")
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
                                phase = .review
                            } label: {
                                HStack(spacing: 12) {
                                    HealthIcon(name: medication.doseUnit == "ml" ? "MedicineBottleIcon" : "MedicinesIcon", size: 30)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(medication.name).font(.headline)
                                        Text(medication.displayDose)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
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
        }
        .padding(20)
    }

    @ViewBuilder
    private var review: some View {
        if let medication = selectedMedication, let assessment {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Review before taking")
                        .font(.title.bold())
                    Text("Check the person, medicine and recent record. Planning does not mean taken.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 14) {
                        HealthIcon(name: medication.doseUnit == "ml" ? "MedicineBottleIcon" : "MedicinesIcon", size: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("FOR \(profile.name.uppercased())")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(medication.name)
                                .font(.title3.weight(.semibold))
                            Text(medication.displayDose)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))

                    LabeledContent("Last 24 hours", value: "\(assessment.dosesInRolling24Hours) confirmed")
                    LabeledContent("Entered maximum", value: "\(medication.maximumDosesPerRolling24Hours)")
                    LabeledContent("Entered minimum gap", value: medication.minimumGapHours.formatted() + " hours")

                    if assessment.maximumReached {
                        warning(
                            title: "Entered maximum reached",
                            detail: "Review History before making another plan. dot cannot tell you whether a medicine is safe to take.",
                            danger: true
                        )
                    } else if let remainingGap = assessment.remainingGap, remainingGap > 0 {
                        warning(
                            title: DotFormatters.shortGap(seconds: remainingGap) + " remains in your entered gap",
                            detail: "This reflects only the limits and records on this device. It is not dosing advice.",
                            danger: false
                        )
                    }

                    if assessment.maximumReached {
                        Button("Review history", action: onViewHistory)
                            .buttonStyle(.borderedProminent)
                            .tint(.primary)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Plan this dose", action: createPlan)
                            .buttonStyle(.borderedProminent)
                            .tint(.primary)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("create-dose-plan")
                        Text("Next, take the medicine. Then confirm what actually happened.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Not sure whether a dose happened?", action: saveUncertainDose)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("save-uncertain-dose")

                    Text("dot uses only the limits you entered and the records stored on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(20)
            }
        } else {
            ContentUnavailableView("Medicine unavailable", systemImage: "exclamationmark.triangle")
        }
    }

    @ViewBuilder
    private var plannedConfirmation: some View {
        if let plan = createdPlan ?? plannedDose {
            VStack(alignment: .leading, spacing: 18) {
                Text("Is this dose taken?")
                    .font(.title.bold())
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(plan.medicationName) · \(plan.displayDose)")
                            .font(.headline)
                        Text("For \(profile.name) · planned at \(DotFormatters.time(plan.plannedAt))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("NOT YET IN DOSE HISTORY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("Confirm what actually happened.")
                        .font(.title3.weight(.semibold))
                    Text("If you do not take it, cancel this plan. It will not count as a dose.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))

                Spacer()

                Button("Yes, I took it") { confirm(plan) }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("confirm-dose-taken")

                Button("I’ll confirm later") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button("Cancel plan", role: .destructive) {
                    modelContext.delete(plan)
                    dismiss()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(20)
        }
    }

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dose recorded")
                .font(.title.bold())
            if let loggedAt {
                Label("Recorded at \(DotFormatters.time(loggedAt))", systemImage: "checkmark.circle")
                    .font(.title3.weight(.semibold))
            }
            Text("The rolling 24-hour record is based only on the limits and doses entered on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("dose-recorded-done")
            Button("View history", action: onViewHistory)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(20)
    }

    private func warning(title: String, detail: String, danger: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if danger {
                HealthIcon(name: "AlertTriangleIcon", size: 26)
            } else {
                Image(systemName: "clock")
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(danger ? Color.dotDanger : Color.primary)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(danger ? Color.dotDanger : Color(.separator), lineWidth: danger ? 2 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(danger ? "Danger. \(title). \(detail)" : "\(title). \(detail)")
    }

    private func createPlan() {
        guard let medication = selectedMedication else { return }
        let plan = PlannedDose(
            profileID: profile.id,
            medicationID: medication.id,
            medicationName: medication.name,
            doseAmount: medication.doseAmount,
            doseUnit: medication.doseUnit
        )
        modelContext.insert(plan)
        createdPlan = plan
        phase = .planned
    }

    private func confirm(_ plan: PlannedDose) {
        let timestamp = Date.now
        modelContext.insert(DoseLog(
            medicationID: plan.medicationID,
            timestamp: timestamp,
            medicationName: plan.medicationName,
            doseAmount: plan.doseAmount,
            doseUnit: plan.doseUnit
        ))
        modelContext.delete(plan)
        loggedAt = timestamp
        phase = .confirmed
    }

    private func saveUncertainDose() {
        guard let medication = selectedMedication else { return }
        modelContext.insert(DoseLog(
            medicationID: medication.id,
            medicationName: medication.name,
            doseAmount: medication.doseAmount,
            doseUnit: medication.doseUnit,
            isUncertain: true
        ))
        onViewHistory()
    }
}
