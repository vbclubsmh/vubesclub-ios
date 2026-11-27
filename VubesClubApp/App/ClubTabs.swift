import SwiftUI

enum ClubTab: String, CaseIterable {
    case events = "Events"
    case explore = "Explore"
    case myEvents = "My Events"
    case club = "Club"
    case profile = "Profile"

    var symbol: String {
        switch self {
        case .events: "rectangle.grid.1x2"
        case .explore: "map"
        case .myEvents: "ticket"
        case .club: "person.2"
        case .profile: "person.crop.circle"
        }
    }
}

enum ClubRoute: Hashable {
    case details(String)
    case checkout(String)
    case confirmation(String)
    case activityMap(String)
    case trainer(String)
    case trainerDirectory
}

/// Detayı sunucudan tamamlar: önce listedeki özet görünür, program ve organizatör yüklenince güncellenir.
struct EventDetailsLoader: View {
    @Environment(EventCatalog.self) private var catalog

    let id: String

    var body: some View {
        if let event = catalog.event(id) {
            EventDetailsScreen(event: event)
                .task(id: id) { await catalog.loadDetail(id: id) }
        }
    }
}

struct ClubTabs: View {
    @Environment(ClubSession.self) private var session

    @State private var selection: ClubTab = .events
    @State private var paths: [ClubTab: [ClubRoute]] = [:]
    @State private var filter = EventFilter()
    @State private var catalog = EventCatalog()
    @State private var bookings = BookingCenter()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(ClubTab.allCases, id: \.self) { tab in
                stack(tab)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(tab)
            }
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: selection)
        .environment(catalog)
        .environment(bookings)
        .task { await catalog.load(session: session) }
        .task { await bookings.load(session: session) }
        .id(session.accountScope)
        .background(Afterglow.background.ignoresSafeArea())
    }

    private var tabBar: some View {
        HStack(spacing: 3) {
            ForEach(ClubTab.allCases, id: \.self) { tab in
                let isSelected = selection == tab

                Button {
                    select(tab)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Afterglow.background : Afterglow.ivory)
                            .frame(width: 37, height: 28)
                            .background(isSelected ? Afterglow.ivory : .clear, in: Capsule())

                        Text(L(tab.rawValue))
                            .font(Afterglow.medium(10, relativeTo: .caption2))
                            .foregroundStyle(isSelected ? Afterglow.ivory : Afterglow.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 49)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Afterglow.surface, in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .strokeBorder(Afterglow.accent.opacity(0.24))
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.24), radius: 13, y: 5)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    private func select(_ tab: ClubTab) {
        guard tab != selection else { return }

        selection = tab
    }

    private func stack(_ tab: ClubTab) -> some View {
        NavigationStack(path: Binding(
            get: { paths[tab, default: []] },
            set: { paths[tab] = $0 }
        )) {
            VStack(spacing: 0) {
                root(for: tab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                tabBar
            }
            .background(Afterglow.background.ignoresSafeArea())
                .navigationDestination(for: ClubRoute.self) { route in
                    destination(route, from: tab)
                        .screenMotion(.navigation)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func root(for tab: ClubTab) -> some View {
        switch tab {
        case .events:
            EventsScreen(filter: $filter, openMap: { select(.explore) })
        case .explore:
            ExploreScreen(filter: $filter)
        case .myEvents:
            MyEventsScreen()
        case .club:
            ClubScreen()
        case .profile:
            ProfileScreen()
        }
    }

    @ViewBuilder
    private func destination(_ route: ClubRoute, from tab: ClubTab) -> some View {
        switch route {
        case .details(let id):
            EventDetailsLoader(id: id)
        case .activityMap(let id):
            if let event = catalog.event(id) ?? DemoCatalog.event(id) { ActivityMapScreen(event: event) }
        case .trainer(let id):
            TrainerDetailScreen(trainerID: id)
        case .trainerDirectory:
            TrainerDirectoryScreen()
        case .checkout(let id):
            if let event = catalog.event(id) ?? DemoCatalog.event(id) {
                CheckoutScreen(event: event) { paths[tab, default: []].append(.confirmation(id)) }
            }
        case .confirmation(let id):
            if let event = catalog.event(id) ?? DemoCatalog.event(id) {
                ConfirmationScreen(event: event) {
                    paths[tab] = []
                    paths[.myEvents] = []
                    select(.myEvents)
                }
            }
        }
    }
}
