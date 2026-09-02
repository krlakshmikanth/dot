import SwiftUI

struct StatusView: View {
    private enum Period: String, CaseIterable, Identifiable {
        case today = "Today"
        case past = "Past"
        var id: String { rawValue }
    }

    let medications: [Medication]
    let doseLogs: [DoseLog]
    let onAddMedication: () -> Void

    @State private var period: Period = .today

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Status")
                    .font(.largeTitle.bold())

                Picker("Status period", selection: $period) {
                    ForEach(Period.allCases) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                .pickerStyle(.segmented)

                if period == .today {
                    todayContent
                } else {
                    pastContent
                }
            }
            .padding(20)
        }
    }

    private var todayContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doses in the rolling 24 hours")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if medications.isEmpty {
                ContentUnavailableView(
                    "No medicines yet",
                    systemImage: "pills",
                    description: Text("Add a medicine using its pharmacist label or packet.")
                )
            } else {
                ForEach(medications) { medication in
                    MedicationStatusRow(
                        medication: medication,
                        logs: doseLogs.filter { $0.medicationID == medication.id },
                        now: .now
                    )
                }
            }

            Button(action: onAddMedication) {
                Label("Add medication", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)

            Text("Dot checks only the limits you entered. It does not provide dosing advice.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    private var pastContent: some View {
        let lowerBound = Date.now.addingTimeInterval(-DoseLimitEvaluator.rollingWindow)
        let oldLogs = doseLogs.filter { $0.timestamp < lowerBound }
        let grouped = Dictionary(grouping: oldLogs) {
            Calendar.autoupdatingCurrent.startOfDay(for: $0.timestamp)
        }
        let days = grouped.keys.sorted(by: >)

        return VStack(alignment: .leading, spacing: 18) {
            Text("Earlier doses")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if days.isEmpty {
                ContentUnavailableView("No earlier doses", systemImage: "clock.arrow.circlepath")
            } else {
                ForEach(days, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(DotFormatters.historyDay(day))
                            .font(.headline)
                        ForEach((grouped[day] ?? []).sorted(by: { $0.timestamp > $1.timestamp })) { log in
                            if let medication = medications.first(where: { $0.id == log.medicationID }) {
                                HStack(spacing: 12) {
                                    Text(DotFormatters.time(log.timestamp))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 62, alignment: .leading)
                                    Text(medication.name).font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(medication.displayDose)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct MedicationStatusRow: View {
    let medication: Medication
    let logs: [DoseLog]
    let now: Date

    private var assessment: DoseLimitAssessment {
        DoseLimitEvaluator.assess(
            timestamps: logs.map(\.timestamp),
            configuration: DoseConfiguration(
                maximumDosesPerRolling24Hours: medication.maximumDosesPerRolling24Hours,
                minimumGapHours: medication.minimumGapHours
            ),
            now: now
        )
    }

    private var detail: String {
        guard assessment.configurationIsValid else {
            return "Check the saved limits before relying on this status"
        }
        if let remaining = assessment.remainingGap, remaining > 0 {
            return DotFormatters.gapDetail(seconds: remaining)
        }
        let noun = assessment.dosesInRolling24Hours == 1 ? "dose" : "doses"
        return "\(assessment.dosesInRolling24Hours) \(noun) logged in the rolling 24 hours"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: assessment.maximumReached ? "exclamationmark.triangle" : "pills")
                .font(.title3)
                .foregroundStyle(assessment.maximumReached ? Color.dotDanger : Color.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(medication.name).font(.headline)
                Text(medication.displayDose).font(.subheadline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(assessment.maximumReached ? Color.dotDanger : Color(.separator), lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let danger = assessment.maximumReached ? "Danger. Configured maximum reached. " : ""
        return "\(danger)\(medication.name), \(medication.displayDose). \(detail)."
    }
}

private extension Color {
    static var dotDanger: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 105 / 255, blue: 97 / 255, alpha: 1)
                : UIColor(red: 180 / 255, green: 35 / 255, blue: 24 / 255, alpha: 1)
        })
    }
}
