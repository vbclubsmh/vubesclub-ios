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
    case liveCheckout(eventId: String, programVersion: String, holdId: String?)
    case liveConfirmation(bookingId: String)
    case liveBookedDetails(eventId: String, bookingId: String)
}

struct ClubTabs: View {
    @Environment(DemoSession.self) private var session
    @State private var liveCatalog = LiveCatalogState()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selection: ClubTab = .events
    @State private var visitedTabs: Set<ClubTab> = [.events]
    @State private var tabDirection: CGFloat = 1
    @State private var paths: [ClubTab: [ClubRoute]] = [:]

    var body: some View {
        tabContent
            .environment(liveCatalog)
            .id(session.accountScope)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if paths[selection, default: []].isEmpty {
                    tabBar
                }
            }
            .background(Afterglow.background.ignoresSafeArea())
    }

    private var tabContent: some View {
        let reduceMotion = reduceMotion
        let travel = tabDirection * 12

        return ZStack {
            ForEach(ClubTab.allCases.filter { visitedTabs.contains($0) }, id: \.self) { tab in
                let isSelected = selection == tab

                stack(tab)
                    .opacity(isSelected ? 1 : 0)
                    .allowsHitTesting(isSelected)
                    .accessibilityHidden(!isSelected)
            }
        }
        .animation(nil, value: selection)
        .keyframeAnimator(initialValue: 1.0, trigger: selection) { content, progress in
            content
                .offset(x: reduceMotion ? 0 : travel * (1 - progress))
                .overlay {
                    if reduceMotion {
                        Afterglow.background
                            .opacity(0.18 * (1 - progress))
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        } keyframes: { _ in
            MoveKeyframe(0.0)
            CubicKeyframe(1.0, duration: reduceMotion ? 0.10 : 0.17, startVelocity: 10, endVelocity: 0)
        }
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

                        Text(tab.rawValue)
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
        }
        .shadow(color: .black.opacity(0.24), radius: 13, y: 5)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .sensoryFeedback(ClubHaptics.selection, trigger: selection)
    }

    private func select(_ tab: ClubTab) {
        guard tab != selection else { return }

        let order = ClubTab.allCases
        let currentIndex = order.firstIndex(of: selection) ?? 0
        let nextIndex = order.firstIndex(of: tab) ?? 0

        tabDirection = nextIndex > currentIndex ? 1 : -1
        visitedTabs.insert(tab)
        selection = tab
    }

    private func stack(_ tab: ClubTab) -> some View {
        NavigationStack(path: Binding(
            get: { paths[tab, default: []] },
            set: { paths[tab] = $0 }
        )) {
            root(for: tab)
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
        let api = session.api
        switch tab {
        case .events:
            LiveEventsScreen(api: api, openMap: { select(.explore) })
        case .explore:
            LiveExploreScreen(api: api)
        case .myEvents:
            LiveMyEventsScreen(api: api, isSelected: selection == .myEvents)
        case .club:
            LiveClubScreen(api: api)
        case .profile:
            LiveProfileScreen(api: api)
        }
    }

    @ViewBuilder
    private func destination(_ route: ClubRoute, from tab: ClubTab) -> some View {
        let api = session.api
        switch route {
        case .details(let id):
            LiveDetailsScreen(api: api, eventID: id)
        case .liveBookedDetails(let id, let bookingID):
            LiveDetailsScreen(api: api, eventID: id, bookingID: bookingID)
        case .activityMap(let id):
            LiveActivityMapScreen(api: api, eventID: id)
        case .liveCheckout(let id, let version, let holdID):
            LiveCheckoutScreen(api: api, eventID: id, programVersion: version, holdID: holdID) { bookingID in
                paths[tab, default: []].append(.liveConfirmation(bookingId: bookingID))
            }
        case .liveConfirmation(let id):
            RemoteConfirmationScreen(api: api, bookingId: id) {
                paths[tab] = []
                paths[.myEvents] = []
                select(.myEvents)
            }
        case .checkout, .confirmation:
            EmptyView()
        }
    }
}
