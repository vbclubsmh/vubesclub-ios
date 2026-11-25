import MapKit
import SwiftUI

struct LiveExploreScreen: View {
    let api: ClubAPI

    @Environment(LiveCatalogState.self) private var catalog
    @State private var feed = CatalogFeed()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedID: String?
    @State private var showsFilters = false

    private var request: CatalogRequest {
        .init(selection: catalog.selection, savedOnly: false, hasLocation: true, revision: catalog.revision)
    }

    var body: some View {
        Map(position: $position, selection: $selectedID) {
            ForEach(feed.events) { event in
                if let point = event.position {
                    Marker(event.title, systemImage: "mappin",
                           coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                        .tint(Afterglow.accent)
                        .tag(event.id)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ScreenTitle("Explore")
                    Spacer()
                    RoundControl(icon: "location", title: "Show all events") { position = .automatic }
                }
                Button { showsFilters = true } label: {
                    Pill(title: "Sport & level", icon: "slider.horizontal.3", selected: catalog.selection != CatalogSelection())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 6) {
                if !feed.events.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 10) {
                            ForEach(feed.events) { event in
                                CatalogEventRow(event: event)
                                    .containerRelativeFrame(.horizontal)
                                    .id(event.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollPosition(id: $selectedID)
                    .scrollIndicators(.hidden)
                    .fixedSize(horizontal: false, vertical: true)
                } else if !feed.loading && feed.error == nil {
                    Text("No matching events on the map")
                        .padding().frame(maxWidth: .infinity)
                        .background(Afterglow.background, in: .rect(cornerRadius: 13))
                }
                CatalogFeedFooter(feed: feed) { more in await feed.load(api, request: request, more: more) }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 14)
        }
        .task(id: request) {
            await feed.load(api, request: request)
            if !Task.isCancelled { position = .automatic }
        }
        .sheet(isPresented: $showsFilters) { CatalogFilterSheet(api: api) }
    }
}
