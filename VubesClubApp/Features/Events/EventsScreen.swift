import SwiftUI

struct EventsScreen: View {
    @Environment(DemoSession.self) private var session

    @Binding var filter: EventFilter

    let openMap: () -> Void

    @State private var savedOnly = false
    @State private var showsFilter = false

    private var visibleEvents: [ClubEvent] {
        DemoCatalog.upcoming.filter {
            filter.matches($0) && (!savedOnly || session.savedEventIDs.contains($0.id))
        }
    }

    var body: some View {
        let events = visibleEvents

        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Overline("The Vubes calendar", color: Afterglow.accent)
                        ScreenTitle("Events")

                        Text("Find your next trail, session or weekend away.")
                            .font(Afterglow.body(13))
                            .foregroundStyle(Afterglow.muted)
                    }

                    Spacer(minLength: 4)

                    RoundControl(icon: "map", title: "Explore map", action: openMap)
                }

                HStack(spacing: 7) {
                    Button { savedOnly = false } label: {
                        Pill(title: "All", selected: !savedOnly)
                    }

                    Button { savedOnly = true } label: {
                        Pill(title: "Saved", icon: "bookmark", selected: savedOnly)
                    }

                    Button { showsFilter = true } label: {
                        Pill(title: "Filter", icon: "slider.horizontal.3", selected: filter != EventFilter())
                    }
                }
                .buttonStyle(.plain)
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
                            Overline("\(events.count) events")
                        }

                        eventList(events)
                    }
                } else {
                    ContentUnavailableView(
                        savedOnly ? "No saved events" : "No matching events",
                        systemImage: savedOnly ? "bookmark" : "slider.horizontal.3"
                    )
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
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
