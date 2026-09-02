import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Query(sort: \DoseLog.timestamp, order: .reverse) private var doseLogs: [DoseLog]

    @AppStorage("homeAction") private var homeActionRawValue = HomeAction.dot.rawValue
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

    private var homeAction: Binding<HomeAction> {
        Binding(
            get: { HomeAction(rawValue: homeActionRawValue) ?? .dot },
            set: { homeActionRawValue = $0.rawValue }
        )
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
                            homeAction: homeAction.wrappedValue,
                            profile: activeProfile,
                            medications: activeMedications,
                            doseLogs: doseLogs,
                            onViewStatus: { selectedTab = .status }
                        )
                        .tag(AppTab.home)
                        .tabItem { Label("Home", systemImage: "house") }

                        StatusView(
                            medications: activeMedications,
                            doseLogs: doseLogs,
                            onAddMedication: { showAddMedication = true }
                        )
                        .tag(AppTab.status)
                        .tabItem { Label("Status", systemImage: "list.bullet.rectangle") }

                        SettingsView(
                            activeProfile: activeProfile,
                            profiles: profiles,
                            homeAction: homeAction,
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
        .task { createDefaultProfileIfNeeded() }
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
}
