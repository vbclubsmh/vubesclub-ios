import SwiftUI

private struct ClubProfile: Decodable {
    let fullName: String
    let avatar: CommunityMedia?
    let cover: CommunityMedia?
    let phoneMasked: String
    let membershipState: String
    let tier: String
    let trainerRole: Bool
}

private struct ProfilePrivacy: Decodable {
    let profileVisibility: String
}

struct LiveProfileScreen: View {
    let api: ClubAPI
    @Environment(DemoSession.self) private var session

    @State private var profile: ClubProfile?
    @State private var errorMessage: String?
    @State private var panel: Panel?

    private enum Panel: String, Identifiable {
        case account = "Account settings"
        case privacy = "Privacy"
        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("Profile")
                if let profile {
                    ClubPhoto(name: profile.cover?.url ?? "", radius: 13)
                        .frame(height: 178)
                        .overlay(alignment: .topTrailing) { Wordmark(width: 46).padding(16) }
                        .overlay(alignment: .bottomLeading) {
                            Avatar(image: profile.avatar?.url ?? "", size: 65, selected: true)
                                .offset(x: 17, y: 18)
                        }
                    VStack(alignment: .leading, spacing: 5) {
                        ScreenTitle(profile.fullName, size: 36)
                        Text(profile.trainerRole ? "Personal trainer" : "Club member")
                            .font(Afterglow.body(13)).foregroundStyle(Afterglow.muted)
                    }
                    .padding(.top, 15)

                    row("Account settings", icon: "person.crop.circle") { panel = .account }
                    row("Privacy", icon: "lock") { panel = .privacy }
                } else if errorMessage == nil {
                    ProgressView()
                }

                if let errorMessage {
                    Text(errorMessage)
                    Button("Try again") { Task { await load() } }
                }
                row("Sign out", icon: "rectangle.portrait.and.arrow.right") { session.signOut() }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 10)
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $panel) { item in
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(item.rawValue, size: 32)
                if item == .privacy {
                    VisibilityPanel(api: api)
                } else if let profile {
                    Text(profile.fullName)
                    LabeledContent("Phone", value: profile.phoneMasked)
                    LabeledContent("Membership", value: profile.tier.capitalized)
                    LabeledContent("Status", value: profile.membershipState.capitalized)
                }
                PrimaryAction(title: "Done", icon: "checkmark") { panel = nil }
            }
            .padding(24)
            .presentationDetents([.medium])
            .presentationBackground(Afterglow.background)
        }
    }

    private func row(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Hairline()
            Button(action: action) {
                HStack {
                    Label(title, systemImage: icon)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Afterglow.muted)
                }
                .font(Afterglow.medium(14))
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func load() async {
        errorMessage = nil
        do {
            profile = try await api.get("me", as: ClubProfile.self)
        } catch {
            if !Task.isCancelled { errorMessage = error.localizedDescription }
        }
    }
}

private struct VisibilityPanel: View {
    let api: ClubAPI
    @State private var visibility: String?
    @State private var message: String?

    var body: some View {
        Group {
            if let visibility {
                LabeledContent("Profile visibility", value: visibility.capitalized)
            } else if let message {
                Text(message)
                Button("Try again") { Task { await load() } }
            } else {
                ProgressView()
            }
        }
        .task { await load() }
    }

    private func load() async {
        message = nil
        do {
            visibility = try await api.get("me/privacy", as: ProfilePrivacy.self).profileVisibility
        } catch {
            if !Task.isCancelled { message = error.localizedDescription }
        }
    }
}
