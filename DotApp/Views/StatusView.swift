import SwiftData
import SwiftUI

struct StatusView: View {
    let medications: [Medication]
    let doseLogs: [DoseLog]
    let onAddMedication: () -> Void

    @State private var selectedLog: DoseLog?
    @State private var showRecordEarlierDose = false

    private var groupedLogs: [(day: Date, logs: [DoseLog])] {
        let grouped = Dictionary(grouping: doseLogs) {
            Calendar.autoupdatingCurrent.startOfDay(for: $0.timestamp)
        }
        return grouped.keys.sorted(by: >).map { day in
            (day, (grouped[day] ?? []).sorted { $0.timestamp > $1.timestamp })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("History")
                    .font(.largeTitle.bold())
                Text("Open any entry to correct its amount or time, confirm uncertainty, or remove a mistake.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showRecordEarlierDose = true
                } label: {
                    Label("Record an earlier dose", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .disabled(medications.filter { $0.archivedAt == nil }.isEmpty)
                .accessibilityIdentifier("record-earlier-dose")

                if groupedLogs.isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Confirmed and uncertain records will appear here.")
                    )
                    .frame(maxWidth: .infinity)

                    Button("Add a medicine", action: onAddMedication)
                        .foregroundStyle(Color(.systemBackground))
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(groupedLogs, id: \.day) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(DotFormatters.historyDay(group.day))
                                .font(.headline)
                            ForEach(group.logs) { log in
                                Button { selectedLog = log } label: {
                                    historyRow(log)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("history-dose-\(log.id.uuidString)")
                            }
                        }
                    }
                }

                Text("Removing or correcting a record recalculates the Day map. Only change an entry to match what actually happened.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            .padding(20)
        }
        .sheet(item: $selectedLog) { log in
            DoseRecordEditorView(
                log: log,
                medication: medications.first { $0.id == log.medicationID }
            )
        }
        .sheet(isPresented: $showRecordEarlierDose) {
            RecordEarlierDoseView(medications: medications.filter { $0.archivedAt == nil })
        }
    }

    private func historyRow(_ log: DoseLog) -> some View {
        let medication = medications.first { $0.id == log.medicationID }
        return HStack(spacing: 12) {
            HealthIcon(name: log.isUncertain ? "QuestionCircleIcon" : "MedicinesIcon", size: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(log.displayName(fallback: medication))
                    .font(.headline)
                Text(log.isUncertain ? "Uncertain · not counted as confirmed" : "\(log.displayDose(fallback: medication)) · confirmed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if log.correctedAt != nil {
                    Text("Corrected entry")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(DotFormatters.time(log.timestamp))
                    .font(.subheadline.monospacedDigit())
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct DoseRecordEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let log: DoseLog
    let medication: Medication?

    @State private var amount: String
    @State private var unit: DoseUnit
    @State private var timestamp: Date
    @State private var confirmUncertain = false
    @State private var showDeleteConfirmation = false

    init(log: DoseLog, medication: Medication?) {
        self.log = log
        self.medication = medication
        let storedUnit = log.recordedDoseUnit ?? medication?.doseUnit ?? DoseUnit.milligrams.rawValue
        _amount = State(initialValue: (log.recordedDoseAmount ?? medication?.doseAmount).map {
            $0.formatted(.number.precision(.fractionLength(0...2)))
        } ?? "")
        _unit = State(initialValue: DoseUnit(rawValue: storedUnit) ?? .milligrams)
        _timestamp = State(initialValue: log.timestamp)
    }

    private var validAmount: Double? {
        guard let value = Double(amount), value.isFinite, value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        HealthIcon(name: log.isUncertain ? "QuestionCircleIcon" : "MedicinesIcon", size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.displayName(fallback: medication))
                                .font(.headline)
                            Text(log.isUncertain ? "Not counted as confirmed" : "Confirmed record")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    TextField("Actual amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("record-dose-amount")
                    Picker("Unit", selection: $unit) {
                        ForEach(DoseUnit.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    DatePicker(
                        "Taken at",
                        selection: $timestamp,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("record-dose-time")

                    if log.isUncertain {
                        Toggle("I can now confirm this dose was taken", isOn: $confirmUncertain)
                    }
                } header: {
                    Text("What actually happened")
                } footer: {
                    Text("Saving updates the existing record and recalculates the rolling 24-hour view.")
                }

                Section {
                    Button("Save correction", action: save)
                        .disabled(validAmount == nil)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("save-dose-correction")

                    Button("Remove mistaken entry", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                } footer: {
                    Text("Only remove an entry if the dose did not happen or was entered twice.")
                }
            }
            .navigationTitle(log.isUncertain ? "Uncertain dose" : "Recorded dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Remove this dose record?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove record", role: .destructive) {
                    modelContext.delete(log)
                    dismiss()
                }
                Button("Keep record", role: .cancel) {}
            } message: {
                Text("This changes the Day map and cannot be undone.")
            }
        }
    }

    private func save() {
        guard let validAmount else { return }
        log.recordedMedicationName = log.displayName(fallback: medication)
        log.recordedDoseAmount = validAmount
        log.recordedDoseUnit = unit.rawValue
        log.timestamp = timestamp
        log.correctedAt = .now
        if confirmUncertain {
            log.confirmationState = "confirmed"
        }
        dismiss()
    }
}

private struct RecordEarlierDoseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let medications: [Medication]

    @State private var selectedMedicationID: UUID?
    @State private var timestamp = Date.now
    @State private var confirmed = false

    private var selectedMedication: Medication? {
        guard let selectedMedicationID else { return nil }
        return medications.first { $0.id == selectedMedicationID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Use this only when the dose has already been taken. Recording it is not permission to take another.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Medicine") {
                    Picker("Medicine", selection: $selectedMedicationID) {
                        Text("Choose a medicine").tag(UUID?.none)
                        ForEach(medications) { medication in
                            Text("\(medication.name) · \(medication.displayDose)").tag(UUID?.some(medication.id))
                        }
                    }
                    DatePicker(
                        "Taken at",
                        selection: $timestamp,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    Toggle("I confirm this dose was actually taken", isOn: $confirmed)
                    Button("Record actual dose", action: save)
                        .disabled(selectedMedication == nil || !confirmed)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("save-earlier-dose")
                }
            }
            .navigationTitle("Record earlier dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard let medication = selectedMedication, confirmed else { return }
        modelContext.insert(DoseLog(
            medicationID: medication.id,
            timestamp: timestamp,
            medicationName: medication.name,
            doseAmount: medication.doseAmount,
            doseUnit: medication.doseUnit
        ))
        dismiss()
    }
}

extension Color {
    static var dotDanger: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 105 / 255, blue: 97 / 255, alpha: 1)
                : UIColor(red: 180 / 255, green: 35 / 255, blue: 24 / 255, alpha: 1)
        })
    }
}
