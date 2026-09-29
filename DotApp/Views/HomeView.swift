import SwiftUI

struct HomeView: View {
    let profile: Profile
    let medications: [Medication]
    let doseLogs: [DoseLog]
    let plannedDose: PlannedDose?
    let onViewHistory: () -> Void

    @State private var showPlanDose = false
    @State private var selectedLog: DoseLog?

    private var activeMedications: [Medication] {
        medications.filter { $0.archivedAt == nil }
    }

    private var recentLogs: [DoseLog] {
        let lowerBound = Date.now.addingTimeInterval(-DoseLimitEvaluator.rollingWindow)
        return doseLogs
            .filter { $0.timestamp >= lowerBound && $0.timestamp <= .now }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var confirmedCount: Int {
        recentLogs.filter { !$0.isUncertain }.count
    }

    private var uncertainCount: Int {
        recentLogs.filter(\.isUncertain).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("FOR \(profile.name.uppercased()) · ROLLING 24 HOURS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text("Your day,\nat a glance.")
                    .font(.largeTitle.bold())

                summaryCard

                if let plannedDose {
                    pendingPlanCard(plannedDose)
                }

                if uncertainCount > 0 {
                    Button(action: onViewHistory) {
                        HStack(spacing: 12) {
                            HealthIcon(name: "QuestionCircleIcon", size: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(uncertainCount) uncertain \(uncertainCount == 1 ? "record needs" : "records need") review")
                                    .font(.subheadline.weight(.semibold))
                                Text("Not counted as confirmed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("uncertain-summary")
                }

                Button {
                    showPlanDose = true
                } label: {
                    Label(plannedDose == nil ? "Plan a dose" : "Finish planned dose", systemImage: plannedDose == nil ? "plus" : "clock")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .accessibilityIdentifier("plan-dose")

                HStack {
                    Text("Recent record")
                        .font(.headline)
                    Spacer()
                    Text("Newest first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                if recentLogs.isEmpty {
                    ContentUnavailableView(
                        "No doses recorded",
                        systemImage: "clock",
                        description: Text("Confirmed and uncertain doses from the last 24 hours will appear here.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(recentLogs) { log in
                            Button { selectedLog = log } label: {
                                timelineRow(log)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("dose-record-\(log.id.uuidString)")
                        }
                    }
                }

                Text("Only doses recorded on this device are shown. dot checks only the limits you entered and does not provide dosing advice.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            .padding(20)
        }
        .sheet(isPresented: $showPlanDose) {
            LogDoseSheet(
                profile: profile,
                medications: activeMedications,
                doseLogs: doseLogs,
                plannedDose: plannedDose,
                onViewHistory: {
                    showPlanDose = false
                    onViewHistory()
                }
            )
        }
        .sheet(item: $selectedLog) { log in
            DoseRecordEditorView(
                log: log,
                medication: medications.first { $0.id == log.medicationID }
            )
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            HealthIcon(name: "CalendarIcon", size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(confirmedCount) confirmed \(confirmedCount == 1 ? "dose" : "doses")")
                    .font(.title3.weight(.semibold))
                Text("Only what this device has recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("confirmed-dose-summary")
    }

    private func pendingPlanCard(_ plan: PlannedDose) -> some View {
        Button { showPlanDose = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("PLANNED · NOT RECORDED AS TAKEN")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(plan.medicationName) · \(plan.displayDose)")
                        .font(.headline)
                    Text("Planned \(plan.plannedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Continue")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pending-dose-plan")
    }

    private func timelineRow(_ log: DoseLog) -> some View {
        let medication = medications.first { $0.id == log.medicationID }
        return HStack(spacing: 12) {
            HealthIcon(name: log.isUncertain ? "QuestionCircleIcon" : "MedicinesIcon", size: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(log.displayName(fallback: medication))
                    .font(.headline)
                Text(log.isUncertain ? "Uncertain · tap to review" : "\(log.displayDose(fallback: medication)) · confirmed\(log.correctedAt == nil ? "" : " · corrected")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(DotFormatters.time(log.timestamp))
                .font(.subheadline.monospacedDigit())
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
