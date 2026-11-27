import SwiftUI

struct EventsScreen: View {
    // Hasdal is a promoted catalog event. Its real API ID survives title and content edits.
    private static let hasdalEventID = "18f18e03-476b-443f-a179-6f078f2a69f8"

    @Environment(ClubSession.self) private var session
    @Environment(EventCatalog.self) private var catalog

    @Binding var filter: EventFilter

    let openMap: () -> Void

    @State private var savedOnly = false
    @State private var showsFilter = false
    @State private var category = EventCategory.all

    private var visibleEvents: [ClubEvent] {
        var events = catalog.upcoming.filter {
            filter.matches($0) && category.matches($0) && (!savedOnly || session.savedEventIDs.contains($0.id))
        }
        if let index = events.firstIndex(where: { $0.id == Self.hasdalEventID }), index > 0 {
            let promoted = events.remove(at: index)
            events.insert(promoted, at: 0)
        }
        return events
    }

    var body: some View {
        let events = visibleEvents

        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                LogoRefreshProbe()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Overline("The Vubes calendar", color: Afterglow.accent)
                        ScreenTitle("Events")

                        Text(L("Find your next trail, session or weekend away."))
                            .font(Afterglow.body(13))
                            .foregroundStyle(Afterglow.muted)
                    }

                    Spacer(minLength: 4)

                    RoundControl(icon: "map", title: "Explore map", action: openMap)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 7) {
                        ForEach(EventCategory.allCases, id: \.self) { item in
                            Button {
                                category = item
                                savedOnly = false
                            } label: {
                                Pill(title: item.title, selected: !savedOnly && category == item)
                            }
                        }

                        Button { savedOnly.toggle() } label: {
                            Pill(title: "Saved", icon: "bookmark", selected: savedOnly)
                        }

                        Button { showsFilter = true } label: {
                            Pill(title: "Filter", icon: "slider.horizontal.3", selected: filter != EventFilter())
                        }
                    }
                    .padding(.horizontal, Afterglow.inset)
                }
                .scrollIndicators(.hidden)
                .buttonStyle(.plain)
                .padding(.horizontal, -Afterglow.inset)
                .padding(.bottom, 1)

                if !events.isEmpty {
                    if savedOnly {
                        eventList(events)
                    } else {
                        FeaturedEvents(events: Array(events.prefix(3)))

                        Hairline()
                            .padding(.top, 8)

                        HStack {
                            ScreenTitle("Coming up", size: 29)
                            Spacer()
                            Overline(L("%d events", events.count))
                        }

                        eventList(events)
                    }
                } else if catalog.phase == .loading || catalog.phase == .idle {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                        .accessibilityLabel(L("Loading events"))
                } else if catalog.phase == .failed && catalog.all.isEmpty {
                    ContentUnavailableView {
                        Label(L("Events couldn’t be loaded"), systemImage: "wifi.slash")
                    } description: {
                        Text(L("Check your connection and try again."))
                    } actions: {
                        Button(L("Try again")) { Task { await catalog.load(session: session) } }
                    }
                } else {
                    ContentUnavailableView(
                        L(savedOnly ? "No saved events" : "No matching events"),
                        systemImage: savedOnly ? "bookmark" : "slider.horizontal.3"
                    )
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .logoRefreshable { await catalog.load(session: session) }
        .background(Afterglow.background.ignoresSafeArea())
        .sheet(isPresented: $showsFilter) {
            EventFilterSheet(filter: $filter)
                .screenMotion(.sheet)
        }
    }

    private func eventList(_ events: [ClubEvent]) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(events) { event in
                EventListRow(event: event)
            }
        }
    }
}
