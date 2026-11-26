import SwiftUI

struct ActivityMapScreen: View {
    let event: ClubEvent

    @State private var selectedID = "ece"

    var body: some View {
        ZStack {
            MapArtwork(image: "Coast")

            GeometryReader { geometry in
                routeLine(in: geometry.size)
                    .accessibilityHidden(true)

                Overline("Kaş", color: Afterglow.ivory)
                    .position(MapPosition(x: 182, y: 157).point(in: geometry.size))
                    .accessibilityHidden(true)

                Overline("Mediterranean", color: Afterglow.ivory)
                    .position(MapPosition(x: 86, y: 425).point(in: geometry.size))
                    .accessibilityHidden(true)

                ForEach(DemoCatalog.participants) { participant in
                    Button {
                        selectedID = participant.id
                    } label: {
                        Avatar(image: participant.image, size: participant.id == selectedID ? 32 : 27,
                               selected: participant.id == selectedID)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(participant.name)
                    .accessibilityAddTraits(participant.id == selectedID ? .isSelected : [])
                    .overlay(alignment: .trailing) {
                        if participant.id == selectedID {
                            Text(participant.name)
                                .font(Afterglow.medium(11))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Afterglow.background, in: Capsule())
                                .fixedSize()
                                .offset(x: 46)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .position(participant.position.point(in: geometry.size))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    BackControl()
                    ScreenTitle("Activity map", size: 31)
                }

                Pill(title: L("%d participants", DemoCatalog.participants.count), icon: "person.2")

                Spacer(minLength: 0)

                RoundControl(icon: "location", title: "Reset participant selection") {
                    selectedID = "ece"
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 15)

                eventCard
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 19)
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: selectedID)
    }

    private var eventCard: some View {
        HStack(spacing: 14) {
            ClubPhoto(name: event.image, radius: 9)
                .frame(width: 96, height: 97)

            VStack(alignment: .leading, spacing: 7) {
                Overline(event.sport.rawValue, color: Afterglow.green)
                Text(L(event.title)).font(Afterglow.display(24, relativeTo: .title2))
                Text(L("Sample locations")).font(Afterglow.body(11.3)).foregroundStyle(Afterglow.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(9)
        .background(Afterglow.background, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Afterglow.border) }
    }

    private func routeLine(in size: CGSize) -> some View {
        let route = Path { path in
            path.addLines(DemoCatalog.route.map { $0.point(in: size) })
        }

        return route
            .stroke(.black.opacity(0.65), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            .overlay {
                route.stroke(Afterglow.ivory, style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
            }
    }
}
