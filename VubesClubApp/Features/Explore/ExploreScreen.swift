import MapKit
import SwiftUI

struct ExploreScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var filter: EventFilter

    @State private var selectedID: ClubEvent.ID? = DemoCatalog.forest.id
    @State private var camera: MapCameraPosition = .automatic
    @State private var showsFilter = false

    private var matchingEvents: [ClubEvent] {
        DemoCatalog.upcoming.filter { $0.meetingCoordinate != nil && filter.matches($0) }
    }

    var body: some View {
        let events = matchingEvents
        let selectedEventID = events.first { $0.id == selectedID }?.id ?? events.first?.id

        Map(position: $camera, interactionModes: [.pan, .zoom]) {
            ForEach(events) { event in
                if let coordinate = event.meetingCoordinate {
                    Annotation(event.title, coordinate: coordinate, anchor: .bottom) {
                        Button {
                            if selectedID == event.id { focus(event) } else { select(event.id) }
                        } label: {
                            MapPin(symbol: event.sport.symbol, selected: selectedEventID == event.id)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(event.title)
                        .accessibilityAddTraits(selectedEventID == event.id ? .isSelected : [])
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .environment(\.colorScheme, .dark)
        .safeAreaInset(edge: .top, spacing: 0) {
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

            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 8)
            .background(Afterglow.background)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if !events.isEmpty {
                    eventCarousel(events, selectedEventID: selectedEventID)
                } else {
                    Text("No matching events in Istanbul")
                        .font(Afterglow.body(13))
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 8)
            .background(Afterglow.background)
        }
        .onChange(of: selectedID) { _, id in
            if let event = events.first(where: { $0.id == id }) { focus(event) }
        }
        .onChange(of: events.map(\.id), initial: true) { _, ids in
            if !ids.contains(selectedID ?? "") { selectedID = ids.first }
            showAll(events)
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: selectedID)
        .sheet(isPresented: $showsFilter) {
            EventFilterSheet(filter: $filter)
                .screenMotion(.sheet)
        }
    }

    private func resetControl(_ events: [ClubEvent]) -> some View {
        RoundControl(icon: "scope", title: "Show all matching events") {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { showAll(events) }
        }
    }

    private func showAll(_ events: [ClubEvent]) {
        let coordinates = events.compactMap(\.meetingCoordinate)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let south = latitudes.min() ?? 41.02
        let north = latitudes.max() ?? 41.12
        let west = longitudes.min() ?? 28.90
        let east = longitudes.max() ?? 29.10
        camera = .region(MKCoordinateRegion(
            center: .init(latitude: (south + north) / 2, longitude: (west + east) / 2),
            span: .init(latitudeDelta: max(0.045, (north - south) * 1.5),
                        longitudeDelta: max(0.045, (east - west) * 1.4))
        ))
    }

    private func focus(_ event: ClubEvent) {
        guard let coordinate = event.meetingCoordinate else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            camera = .region(MKCoordinateRegion(center: coordinate,
                                                latitudinalMeters: 4500, longitudinalMeters: 4500))
        }
    }

    private func select(_ eventID: ClubEvent.ID) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            selectedID = eventID
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
