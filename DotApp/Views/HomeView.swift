import SwiftUI

struct HomeView: View {
    let homeAction: HomeAction
    let profile: Profile
    let medications: [Medication]
    let doseLogs: [DoseLog]
    let onViewStatus: () -> Void

    @State private var showLogDose = false

    private var mostRecentDose: (Medication, DoseLog)? {
        for log in doseLogs.sorted(by: { $0.timestamp > $1.timestamp }) {
            if let medication = medications.first(where: { $0.id == log.medicationID }) {
                return (medication, log)
            }
        }
        return nil
    }

    var body: some View {
        Group {
            switch homeAction {
            case .dot:
                dotAction
            case .direct:
                directAction
            }
        }
        .sheet(isPresented: $showLogDose) {
            LogDoseSheet(
                profile: profile,
                medications: medications,
                onViewStatus: {
                    showLogDose = false
                    onViewStatus()
                }
            )
        }
    }

    private var dotAction: some View {
        VStack(spacing: 0) {
            Spacer()
            Button { showLogDose = true } label: {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 14, height: 14)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log a dose")

            Text("Log a dose")
                .font(.title3.weight(.semibold))
                .padding(.top, 20)
            Text("Dot checks only the limits you entered.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            Spacer()
            Spacer().frame(height: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var directAction: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log a dose")
                .font(.largeTitle.bold())

            if let (medication, log) = mostRecentDose {
                Label {
                    Text("Last logged: \(medication.name), \(log.timestamp.formatted(.relative(presentation: .named)))")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                Text("No doses logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { showLogDose = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 64, height: 64)
                    .background(Color.primary, in: Circle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Log a dose")
        }
        .padding(20)
        .padding(.bottom, 44)
    }
}
