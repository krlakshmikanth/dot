import SwiftUI

struct SettingsView: View {
    let activeProfile: Profile
    let profiles: [Profile]
    let medications: [Medication]
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

                Section("Medicines") {
                    NavigationLink {
                        MedicineManagementView(profileID: activeProfile.id, medications: medications)
                    } label: {
                        HStack(spacing: 12) {
                            HealthIcon(name: "MedicinesIcon", size: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Manage medicines")
                                Text("Add, edit, archive or restore")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("manage-medicines")
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
                    Text("dot also follows the system Reduce Motion, text size, and VoiceOver settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("What dot can check") {
                    HStack(alignment: .top, spacing: 12) {
                        HealthIcon(name: "AlertTriangleIcon", size: 24)
                        Text("Only recent records and limits entered on this device. dot cannot tell you that a medicine is safe to take, check interactions, or replace urgent medical advice.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text("Danger is identified by a warning symbol, description and red border, never by colour alone.")
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
            Text("Each profile keeps its own medicines, plans and dose history on this device.")
        }
    }
}

private struct MedicineManagementView: View {
    let profileID: UUID
    let medications: [Medication]

    @State private var selectedMedication: Medication?
    @State private var showAddMedication = false
    @State private var medicationToArchive: Medication?

    private var sortedMedications: [Medication] {
        medications.sorted {
            if ($0.archivedAt == nil) != ($1.archivedAt == nil) {
                return $0.archivedAt == nil
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(sortedMedications) { medication in
                    VStack(spacing: 0) {
                        Button { selectedMedication = medication } label: {
                            HStack(spacing: 12) {
                                HealthIcon(name: medication.doseUnit == "ml" ? "MedicineBottleIcon" : "MedicinesIcon", size: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(medication.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(medication.displayDose) · maximum \(medication.maximumDosesPerRolling24Hours) in 24 hours")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if medication.archivedAt != nil {
                                        Text("Archived")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(minHeight: 54)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("edit-medicine-\(medication.id.uuidString)")

                        Button(medication.archivedAt == nil ? "Archive" : "Restore") {
                            if medication.archivedAt == nil {
                                medicationToArchive = medication
                            } else {
                                medication.archivedAt = nil
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
            } footer: {
                Text("Editing changes future plans only. Existing dose history keeps the name, amount and unit recorded at the time.")
            }

            Section {
                Button {
                    showAddMedication = true
                } label: {
                    Label("Add medicine", systemImage: "plus")
                        .frame(minHeight: 44)
                }
            }
        }
        .navigationTitle("Medicines")
        .sheet(item: $selectedMedication) { medication in
            AddMedicationView(profileID: profileID, medication: medication)
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationView(profileID: profileID)
        }
        .confirmationDialog(
            "Archive this medicine?",
            isPresented: Binding(
                get: { medicationToArchive != nil },
                set: { if !$0 { medicationToArchive = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Archive medicine", role: .destructive) {
                medicationToArchive?.archivedAt = .now
                medicationToArchive = nil
            }
            Button("Keep active", role: .cancel) { medicationToArchive = nil }
        } message: {
            Text("It will disappear from planning choices, but its history will remain.")
        }
    }
}
