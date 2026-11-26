import PhotosUI
import SwiftUI

struct ProfileScreen: View {
    @Environment(ClubSession.self) private var session

    private enum Panel: String, Identifiable {
        case account = "Account settings"
        case privacy = "Privacy"

        var id: String { rawValue }
    }

    @State private var selectedPanel: Panel?
    @State private var showPhotoMenu = false
    @State private var showPicker = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var isUpdatingPhoto = false
    @State private var photoError: String?

    private var memberName: String { session.profile?.fullName ?? "" }

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
                        photoButton.offset(x: 17, y: 26)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    ScreenTitle(memberName, size: 36)

                    Text(isUpdatingPhoto ? L("Updating photo…") : L("Club member"))
                        .font(Afterglow.body(13))
                        .foregroundStyle(Afterglow.muted)

                    if let photoError {
                        Text(photoError)
                            .font(Afterglow.body(12))
                            .foregroundStyle(Afterglow.muted)
                    }
                }
                .padding(.top, 22)

                VStack(spacing: 0) {
                    Hairline()

                    row("Account settings", icon: "person.crop.circle") { selectedPanel = .account }
                    row("Privacy", icon: "lock") { selectedPanel = .privacy }
                    languageRow
                    row("Sign out", icon: "rectangle.portrait.and.arrow.right") { session.signOut() }
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .task { await session.refreshProfile() }
        .confirmationDialog(L("Profile photo"), isPresented: $showPhotoMenu) {
            Button(L("Choose from library")) { showPicker = true }
            if session.profile?.avatar != nil {
                Button(L("Remove photo"), role: .destructive) { removePhoto() }
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $pickedItem, matching: .images)
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await upload(item) }
        }
        .sheet(item: $selectedPanel) { panel in
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(panel.rawValue, size: 32)

                Text(panel == .account
                     ? "\(memberName) · \(L("Club member"))"
                     : L("Your profile is private. Activity maps use sample locations."))
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

    private var photoButton: some View {
        Button { showPhotoMenu = true } label: {
            ProfileAvatar(url: session.profile?.avatar?.url, name: memberName, size: 72)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: isUpdatingPhoto ? "hourglass" : "camera.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Afterglow.background)
                        .frame(width: 24, height: 24)
                        .background(Afterglow.ivory, in: Circle())
                        .overlay { Circle().strokeBorder(Afterglow.background, lineWidth: 2) }
                        .offset(x: 3, y: 3)
                }
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingPhoto)
        .accessibilityLabel(L("Change photo"))
    }

    private func upload(_ item: PhotosPickerItem) async {
        isUpdatingPhoto = true
        photoError = nil
        defer {
            isUpdatingPhoto = false
            pickedItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let jpeg = ProfilePhoto.jpeg(from: data) else {
                photoError = L("We couldn’t use that photo. Try another one.")
                return
            }
            try await session.updateAvatar(jpeg)
        } catch {
            photoError = L(ClubAPIError.message(for: error))
        }
    }

    private func removePhoto() {
        Task {
            isUpdatingPhoto = true
            photoError = nil
            defer { isUpdatingPhoto = false }
            do { try await session.removeAvatar() } catch { photoError = L(ClubAPIError.message(for: error)) }
        }
    }

    private var languageRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "globe")
                    .font(.system(size: 17))
                    .foregroundStyle(Afterglow.ivory)

                Text(L("Language")).font(Afterglow.medium(14))

                Spacer()

                LanguageSwitch()
            }
            .padding(.horizontal, 4)
            .frame(minHeight: 66)

            Hairline()
        }
    }

    private func row(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 13) {
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundStyle(Afterglow.ivory)

                    Text(L(title)).font(Afterglow.medium(14))

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
