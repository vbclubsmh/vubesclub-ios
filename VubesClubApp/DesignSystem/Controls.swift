import SwiftUI

struct PrimaryAction: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    var icon = "arrow.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .trailing) {
                Text(title)
                    .font(Afterglow.medium(14))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
                    .frame(maxWidth: .infinity, minHeight: 48)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .padding(.trailing, 17)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Afterglow.background)
            .background(Afterglow.ivory.opacity(isEnabled ? 1 : 0.55), in: .rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct RoundControl: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 38, height: 38)
                .background(Afterglow.background.opacity(0.82), in: Circle())
                .overlay { Circle().strokeBorder(Afterglow.border) }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct BackControl: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RoundControl(icon: "chevron.left", title: "Back") { dismiss() }
    }
}

struct Pill: View {
    let title: String
    var icon: String? = nil
    var selected = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
            }

            Text(title)
                .font(Afterglow.medium(11, relativeTo: .caption))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(selected ? Afterglow.background : Afterglow.text)
        .background(selected ? Afterglow.ivory : Afterglow.surface, in: Capsule())
        .overlay {
            if !selected {
                Capsule().strokeBorder(Afterglow.border)
            }
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct MetadataLabel: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(Afterglow.medium(11.3, relativeTo: .caption))
            .foregroundStyle(Afterglow.muted)
    }
}

struct SaveControl: View {
    @Environment(DemoSession.self) private var session

    let eventID: String

    var body: some View {
        let saved = session.savedEventIDs.contains(eventID)

        RoundControl(
            icon: saved ? "bookmark.fill" : "bookmark",
            title: saved ? "Remove from saved events" : "Save event"
        ) {
            session.toggleSaved(eventID: eventID)
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: saved)
    }
}
