import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Query(sort: \DoseLog.timestamp, order: .reverse) private var doseLogs: [DoseLog]
    @Query(sort: \PlannedDose.plannedAt, order: .reverse) private var plannedDoses: [PlannedDose]

    @AppStorage("appearance") private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("reduceMotionInDot") private var reduceMotionInDot = false
    @AppStorage("selectedProfileID") private var selectedProfileIDRawValue = ""

    @State private var selectedTab: AppTab = ProcessInfo.processInfo.arguments.contains("-dot-open-settings") ? .settings : .home
    @State private var showLaunch = !ProcessInfo.processInfo.arguments.contains("-dot-ui-testing")
    @State private var showAddMedication = false
    @State private var showProfileSwitcher = false

    private var activeProfile: Profile? {
        if let selectedProfileID = UUID(uuidString: selectedProfileIDRawValue),
           let profile = profiles.first(where: { $0.id == selectedProfileID }) {
            return profile
        }
        return profiles.first
    }

    private var activeMedications: [Medication] {
        guard let profileID = activeProfile?.id else { return [] }
        return medications.filter { $0.profileID == profileID }
    }

    private var activeDoseLogs: [DoseLog] {
        let medicationIDs = Set(activeMedications.map(\.id))
        return doseLogs.filter { medicationIDs.contains($0.medicationID) }
    }

    private var activePlannedDose: PlannedDose? {
        guard let profileID = activeProfile?.id else { return nil }
        return plannedDoses.first { $0.profileID == profileID }
    }

    private var appearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRawValue) ?? .system },
            set: { appearanceRawValue = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            if let activeProfile {
                VStack(spacing: 0) {
                    AppHeaderView(
                        profile: activeProfile,
                        colorScheme: colorScheme,
                        onProfileTapped: { showProfileSwitcher = true },
                        onAppearanceTapped: toggleAppearance
                    )

                    TabView(selection: $selectedTab) {
                        HomeView(
                            profile: activeProfile,
                            medications: activeMedications,
                            doseLogs: activeDoseLogs,
                            plannedDose: activePlannedDose,
                            onViewHistory: { selectedTab = .history }
                        )
                        .tag(AppTab.home)
                        .tabItem { Label("Home", systemImage: "house") }

                        StatusView(
                            medications: activeMedications,
                            doseLogs: activeDoseLogs,
                            onAddMedication: { showAddMedication = true }
                        )
                        .tag(AppTab.history)
                        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

                        SettingsView(
                            activeProfile: activeProfile,
                            profiles: profiles,
                            medications: activeMedications,
                            appearance: appearance,
                            reduceMotionInDot: $reduceMotionInDot,
                            onSelectProfile: selectProfile
                        )
                        .tag(AppTab.settings)
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                    }
                }
            } else {
                ProgressView("Preparing dot")
            }

            if showLaunch {
                LaunchView(
                    reduceMotionInDot: reduceMotionInDot,
                    onFinished: { showLaunch = false }
                )
                .zIndex(10)
            }
        }
        .preferredColorScheme(appearance.wrappedValue.preferredColorScheme)
        .task {
            createDefaultProfileIfNeeded()
            backfillLegacyDoseSnapshots()
        }
        .sheet(isPresented: $showAddMedication) {
            if let activeProfile {
                AddMedicationView(profileID: activeProfile.id)
            }
        }
        .sheet(isPresented: $showProfileSwitcher) {
            ProfileSwitcherView(
                activeProfileID: activeProfile?.id,
                onSelectProfile: { profileID in
                    selectProfile(profileID)
                    showProfileSwitcher = false
                }
            )
        }
    }

    private func createDefaultProfileIfNeeded() {
        guard profiles.isEmpty else {
            if activeProfile == nil, let firstProfileID = profiles.first?.id {
                selectProfile(firstProfileID)
            }
            return
        }
        let profile = Profile(name: "Me", avatarInitial: "M")
        modelContext.insert(profile)
        selectProfile(profile.id)
    }

    private func selectProfile(_ profileID: UUID) {
        selectedProfileIDRawValue = profileID.uuidString
    }

    private func toggleAppearance() {
        appearance.wrappedValue = colorScheme == .dark ? .light : .dark
    }

    private func backfillLegacyDoseSnapshots() {
        for log in doseLogs where log.recordedMedicationName == nil
            || log.recordedDoseAmount == nil
            || log.recordedDoseUnit == nil {
            guard let medication = medications.first(where: { $0.id == log.medicationID }) else { continue }
            log.recordedMedicationName = medication.name
            log.recordedDoseAmount = medication.doseAmount
            log.recordedDoseUnit = medication.doseUnit
            if log.confirmationState == nil {
                log.confirmationState = "confirmed"
            }
        }
    }
}
