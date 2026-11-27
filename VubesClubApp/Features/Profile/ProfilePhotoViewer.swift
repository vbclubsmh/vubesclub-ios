import SwiftUI

/// Profil fotoğrafının büyük hali ve değiştirme/kaldırma eylemleri.
struct ProfilePhotoViewer: View {
    @Environment(\.dismiss) private var dismiss

    let url: String?
    let name: String
    let onChange: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Afterglow.ivory)
                        .frame(width: 40, height: 40)
                        .background(Afterglow.surface, in: .circle)
                }
                .accessibilityLabel(L("Close"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer(minLength: 12)

            Group {
                if let url {
                    ClubMediaImage(source: url)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 28))
                        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(Afterglow.border.opacity(0.7)) }
                } else {
                    ProfileAvatar(url: nil, name: name, size: 220)
                }
            }
            .padding(.horizontal, 24)
            .accessibilityLabel(name)

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                PrimaryAction(title: url == nil ? "Add photo" : "Change photo", icon: "camera") {
                    onChange()
                    dismiss()
                }

                if url != nil {
                    Button(role: .destructive) {
                        onRemove()
                        dismiss()
                    } label: {
                        Text(L("Remove photo"))
                            .font(Afterglow.medium(14))
                            .foregroundStyle(Afterglow.muted)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 20)
        }
        .background(Afterglow.background.ignoresSafeArea())
    }
}
