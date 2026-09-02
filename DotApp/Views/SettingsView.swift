import SwiftUI

struct SettingsView: View {
    let activeProfile: Profile
    let profiles: [Profile]
    @Binding var homeAction: HomeAction
    @Binding var appearance: AppAppearance
    @Binding var reduceMotionInDot: Bool
    let onSelectProfile: (UUID) -> Void

    @State private var showEditProfile = false
    @State private var showAddProfile = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                profilesSection

                Section("Home action") {
                    Picker("Home action", selection: $homeAction) {
                        ForEach(HomeAction.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Accessibility") {
                    Toggle("Reduce motion in dot", isOn: $reduceMotionInDot)
                    Text("Dot also follows the system Reduce Motion, text size, and VoiceOver settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Danger is identified by a warning symbol, description, and red border—never by colour alone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showEditProfile) {
            ProfileEditorView(profile: activeProfile)
        }
        .sheet(isPresented: $showAddProfile) {
            ProfileEditorView { profile in
                onSelectProfile(profile.id)
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            VStack(alignment: .leading, spacing: 2) {
                Text(activeProfile.name).font(.headline)
                Text("Active profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            LabeledContent("Nickname", value: activeProfile.name)
            LabeledContent("Age", value: activeProfile.age.map(String.init) ?? "Not added")
            LabeledContent("Medical ID", value: activeProfile.medicalID == nil ? "Not added" : "Added")

            Button("Edit account details") {
                showEditProfile = true
            }
            .accessibilityIdentifier("edit-profile")
        }
    }

    private var profilesSection: some View {
        Section {
            ForEach(profiles) { profile in
                Button {
                    onSelectProfile(profile.id)
                } label: {
                    HStack(spacing: 12) {
                        Text(profile.displayInitial)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(.systemBackground))
                            .frame(width: 36, height: 36)
                            .background(Color.primary, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name).foregroundStyle(.primary)
                            if let age = profile.age {
                                Text("Age \(age)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if profile.id == activeProfile.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel(profile.id == activeProfile.id ? "\(profile.name), active profile" : "Switch to \(profile.name)")
            }

            Button {
                showAddProfile = true
            } label: {
                Label("Add another profile", systemImage: "person.badge.plus")
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("add-profile")
        } header: {
            Text("Profiles")
        } footer: {
            Text("Each profile keeps its own medicines and dose history on this device.")
        }
    }
}
