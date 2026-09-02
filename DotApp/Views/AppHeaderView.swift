import SwiftUI

struct AppHeaderView: View {
    let profile: Profile
    let colorScheme: ColorScheme
    let onProfileTapped: () -> Void
    let onAppearanceTapped: () -> Void

    var body: some View {
        HStack {
            Button(action: onProfileTapped) {
                Text(profile.displayInitial)
                    .font(.headline.bold())
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 44, height: 44)
                    .background(Color.primary, in: Circle())
                    .accessibilityIdentifier("active-profile-initial")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Switch profile. Active profile \(profile.name)")
            .accessibilityIdentifier("active-profile-menu")

            Spacer()

            Button(action: onAppearanceTapped) {
                Image(systemName: colorScheme == .dark ? "sun.max" : "moon")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(colorScheme == .dark ? "Switch to light appearance" : "Switch to dark appearance")
        }
        .frame(minHeight: 52)
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}
