import SwiftUI

struct ProfileScreen: View {
    @Environment(DemoSession.self) private var session

    private enum Panel: String, Identifiable {
        case account = "Account settings"
        case privacy = "Privacy"

        var id: String { rawValue }
    }

    @State private var selectedPanel: Panel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("Profile")

                ClubPhoto(name: "Terrace", radius: 13)
                    .frame(height: 178)
                    .overlay(alignment: .bottom) {
                        Afterglow.shade().frame(height: 97)
                    }
                    .clipShape(.rect(cornerRadius: 13))
                    .overlay(alignment: .topTrailing) {
                        Wordmark(width: 46).padding(16)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Avatar(image: "Portrait3", size: 65, selected: true)
                            .offset(x: 17, y: 18)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    ScreenTitle("Ada Kaya", size: 36)

                    Text("Club member")
                        .font(Afterglow.body(13))
                        .foregroundStyle(Afterglow.muted)
                }
                .padding(.top, 15)

                VStack(spacing: 0) {
                    Hairline()

                    row("Account settings", icon: "person.crop.circle") { selectedPanel = .account }
                    row("Privacy", icon: "lock") { selectedPanel = .privacy }
                    row("Sign out", icon: "rectangle.portrait.and.arrow.right") { session.signOut() }
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .sheet(item: $selectedPanel) { panel in
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(panel.rawValue, size: 32)

                Text(panel == .account
                     ? "Ada Kaya · Club member"
                     : "Your profile is private. Activity maps use sample locations.")
                    .font(Afterglow.body(14))
                    .foregroundStyle(Afterglow.muted)

                PrimaryAction(title: "Done", icon: "checkmark") { selectedPanel = nil }
            }
            .padding(24)
            .screenMotion(.sheet)
            .presentationDetents([.medium])
            .presentationBackground(Afterglow.background)
        }
    }

    private func row(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 13) {
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundStyle(Afterglow.ivory)

                    Text(title).font(Afterglow.medium(14))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Afterglow.muted)
                }
                .padding(.horizontal, 4)
                .frame(minHeight: 66)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Hairline()
        }
    }
}
