import SwiftUI

struct FeaturedEvents: View {
    let events: [ClubEvent]

    @State private var selectedID: ClubEvent.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Overline("Featured experiences", color: Afterglow.accent)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(events) { event in
                        card(event)
                            .containerRelativeFrame(.horizontal) { width, _ in
                                guard width.isFinite else { return 0 }
                                return max(0, events.count > 1 ? width - 26 : width)
                            }
                            .id(event.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $selectedID)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: events.map(\.id), initial: true) { _, ids in
                if let selectedID, ids.contains(selectedID) { return }

                selectedID = ids.first
            }

            if events.count > 1 {
                HStack(spacing: 5) {
                    ForEach(events) { event in
                        Capsule()
                            .fill(event.id == selectedID ? Afterglow.accent : Afterglow.border)
                            .frame(width: event.id == selectedID ? 21 : 6, height: 4)
                    }

                    Spacer()

                    if let index = events.firstIndex(where: { $0.id == selectedID }) {
                        Text("\(index + 1) / \(events.count)")
                            .font(Afterglow.medium(11, relativeTo: .caption))
                            .monospacedDigit()
                            .foregroundStyle(Afterglow.muted)
                            .accessibilityLabel(L("Featured event %d of %d", index + 1, events.count))
                    }
                }
            }
        }
    }

    private func card(_ event: ClubEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            EventCover(event: event, height: 248)

            NavigationLink(value: ClubRoute.details(event.id)) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        eventMetadata(event)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(Afterglow.accent)
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        MetadataLabel(title: event.displayDate, icon: "calendar")
                        MetadataLabel(title: event.level.rawValue, icon: "mountain.2")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("View %@", L(event.title)))
        }
        .background(Afterglow.surface, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Afterglow.border.opacity(0.8)) }
    }

    private func eventMetadata(_ event: ClubEvent) -> some View {
        Group {
            MetadataLabel(title: event.displayDate, icon: "calendar")
            MetadataLabel(title: event.level.rawValue, icon: "mountain.2")
        }
    }
}
