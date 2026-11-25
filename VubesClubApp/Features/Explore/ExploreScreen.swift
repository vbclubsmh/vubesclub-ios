import SwiftUI

struct ExploreScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var filter: EventFilter

    @State private var selectedID: ClubEvent.ID? = DemoCatalog.forest.id
    @State private var showsFilter = false

    private var matchingEvents: [ClubEvent] {
        DemoCatalog.upcoming.filter { $0.mapPosition != nil && filter.matches($0) }
    }

    var body: some View {
        let events = matchingEvents
        let selectedEventID = events.first { $0.id == selectedID }?.id ?? events.first?.id

        ZStack {
            MapArtwork(image: "DiscoverTerrain")

            mapPins(events, selectedEventID: selectedEventID)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ScreenTitle("Explore")
                    Spacer()
                    resetControl(events)
                }

                HStack(spacing: 7) {
                    Pill(title: "Istanbul", icon: "mappin")

                    Button { showsFilter = true } label: {
                        Pill(title: "Sport & level", icon: "slider.horizontal.3", selected: filter != EventFilter())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                if !events.isEmpty {
                    eventCarousel(events, selectedEventID: selectedEventID)
                } else {
                    Text("No matching events in Istanbul")
                        .font(Afterglow.body(13))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Afterglow.background, in: .rect(cornerRadius: 13))
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        .onChange(of: events.map(\.id), initial: true) { _, ids in
            if let selectedID, ids.contains(selectedID) { return }

            selectedID = ids.first
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: selectedID)
        .sheet(isPresented: $showsFilter) {
            EventFilterSheet(filter: $filter)
                .screenMotion(.sheet)
        }
    }

    private func resetControl(_ events: [ClubEvent]) -> some View {
        RoundControl(icon: "location", title: "Reset map selection") {
            guard let event = events.first(where: { $0.id == DemoCatalog.forest.id }) ?? events.first else {
                return
            }

            select(event.id)
        }
    }

    private func select(_ eventID: ClubEvent.ID) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            selectedID = eventID
        }
    }

    private func mapPins(_ events: [ClubEvent], selectedEventID: ClubEvent.ID?) -> some View {
        GeometryReader { geometry in
            mapLabel("Belgrad Forest", x: 99, y: 226, in: geometry.size)
            mapLabel("Bosphorus", x: 260, y: 333, in: geometry.size)
            mapLabel("Sea of Marmara", x: 112, y: 477, in: geometry.size)

            ForEach(events) { event in
                let isSelected = selectedEventID == event.id

                if let position = event.mapPosition {
                    Button {
                        select(event.id)
                    } label: {
                        MapPin(symbol: event.sport.symbol, selected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(event.title)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .overlay(alignment: .bottom) {
                        if isSelected {
                            Text(event.title)
                                .font(Afterglow.medium(10.4, relativeTo: .caption2))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Afterglow.background, in: Capsule())
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .offset(y: 31)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .position(position.point(in: geometry.size))
                    .zIndex(isSelected ? 1 : 0)
                }
            }
        }
    }

    private func eventCarousel(_ events: [ClubEvent], selectedEventID: ClubEvent.ID?) -> some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(events) { event in
                        eventCard(event)
                            .containerRelativeFrame(.horizontal)
                            .id(event.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedID, anchor: .center)
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)

            if events.count > 1 {
                HStack(spacing: 3) {
                    ForEach(events) { event in
                        let isSelected = selectedEventID == event.id

                        Button {
                            select(event.id)
                        } label: {
                            Capsule()
                                .fill(isSelected ? Afterglow.accent : Afterglow.muted.opacity(0.45))
                                .frame(width: isSelected ? 20 : 6, height: 4)
                                .frame(width: 44, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Show \(event.title)")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
        }
    }

    private func mapLabel(_ title: String, x: Double, y: Double, in size: CGSize) -> some View {
        Overline(title, color: Afterglow.ivory)
            .shadow(color: .black, radius: 3)
            .position(MapPosition(x: x, y: y).point(in: size))
            .accessibilityHidden(true)
    }

    private func eventCard(_ event: ClubEvent) -> some View {
        NavigationLink(value: ClubRoute.details(event.id)) {
            HStack(spacing: 14) {
                ClubPhoto(name: event.image, radius: 8)
                    .frame(width: 103, height: 138)

                VStack(alignment: .leading, spacing: 8) {
                    Label(event.sport.rawValue, systemImage: event.sport.symbol)
                        .font(Afterglow.medium(10, relativeTo: .caption))
                        .foregroundStyle(Afterglow.accent)

                    Overline("\(event.date) / \(event.location)")

                    Text(event.title)
                        .font(Afterglow.display(21, relativeTo: .title2))
                        .tracking(-0.4)
                        .fixedSize(horizontal: false, vertical: true)

                    MetadataLabel(
                        title: [event.level.rawValue, event.distance].compactMap { $0 }.joined(separator: " · "),
                        icon: "mountain.2"
                    )

                    Hairline().padding(.top, 3)

                    HStack {
                        Text("View event").font(Afterglow.medium(12))
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 13))
                    }
                }
                .padding(.trailing, 9)
            }
            .padding(8)
            .background(Afterglow.background, in: .rect(cornerRadius: 13))
            .overlay { RoundedRectangle(cornerRadius: 13).strokeBorder(Afterglow.border) }
        }
        .buttonStyle(.plain)
    }
}
