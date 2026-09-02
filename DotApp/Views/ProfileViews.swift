import SwiftData
import SwiftUI

struct ProfileSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    let activeProfileID: UUID?
    let onSelectProfile: (UUID) -> Void

    @State private var showAddProfile = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(profiles) { profile in
                        Button {
                            onSelectProfile(profile.id)
                        } label: {
                            HStack(spacing: 12) {
                                Text(profile.displayInitial)
                                    .font(.headline.bold())
                                    .foregroundStyle(Color(.systemBackground))
                                    .frame(width: 44, height: 44)
                                    .background(Color.primary, in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(profile.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let age = profile.age {
                                        Text("Age \(age)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if profile.id == activeProfileID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.primary)
                                }
                            }
                            .frame(minHeight: 52)
                        }
                        .accessibilityLabel(profile.id == activeProfileID ? "\(profile.name), active profile" : "Switch to \(profile.name)")
                        .accessibilityIdentifier("switch-profile-\(profile.name)")
                    }
                } footer: {
                    Text("Switching profiles changes the medicines and history shown throughout dot.")
                }

                Section {
                    Button {
                        showAddProfile = true
                    } label: {
                        Label("Add another profile", systemImage: "person.badge.plus")
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("add-profile-from-switcher")
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showAddProfile) {
            ProfileEditorView { profile in
                onSelectProfile(profile.id)
            }
        }
    }
}

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    let profile: Profile?
    let onSave: ((Profile) -> Void)?

    @State private var draft: ProfileDraft
    @FocusState private var focusedField: Field?

    private enum Field {
        case nickname, age, medicalID
    }

    private var nicknameAlreadyExists: Bool {
        guard let values = draft.validatedValues else { return false }
        return profiles.contains { candidate in
            candidate.id != profile?.id
                && candidate.name.compare(values.nickname, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var canSave: Bool {
        draft.validatedValues != nil && !nicknameAlreadyExists
    }

    init(profile: Profile? = nil, onSave: ((Profile) -> Void)? = nil) {
        self.profile = profile
        self.onSave = onSave
        _draft = State(initialValue: profile.map(ProfileDraft.init(profile:)) ?? ProfileDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Use a short name that is easy to recognise when switching profiles.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextField("Nickname", text: $draft.nickname)
                        .textContentType(.nickname)
                        .focused($focusedField, equals: .nickname)
                        .accessibilityIdentifier("profile-nickname")

                    TextField("Age", text: $draft.age)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .age)
                        .accessibilityIdentifier("profile-age")

                    TextField("Medical ID (optional)", text: $draft.medicalID)
                        .textContentType(.none)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .medicalID)
                        .accessibilityIdentifier("profile-medical-id")
                } header: {
                    Text("Basic details")
                } footer: {
                    if nicknameAlreadyExists {
                        Text("Choose a different nickname so each profile is easy to identify.")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Text("These details stay in dot's local app data. The Medical ID is not connected to Apple Health or verified by dot.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(profile == nil ? "Add profile" : "Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .accessibilityIdentifier("save-profile")
                }
            }
            .onAppear { focusedField = .nickname }
        }
    }

    private func save() {
        guard canSave, let values = draft.validatedValues else { return }
        let savedProfile: Profile
        if let profile {
            profile.name = values.nickname
            profile.avatarInitial = values.nickname.first.map { String($0).uppercased() } ?? "?"
            profile.age = values.age
            profile.medicalID = values.medicalID
            savedProfile = profile
        } else {
            let newProfile = Profile(
                name: values.nickname,
                avatarInitial: values.nickname.first.map { String($0).uppercased() } ?? "?",
                age: values.age,
                medicalID: values.medicalID
            )
            modelContext.insert(newProfile)
            savedProfile = newProfile
        }
        onSave?(savedProfile)
        dismiss()
    }
}
