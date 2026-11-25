import SwiftUI

struct LiveEventsScreen: View {
    let api: ClubAPI
    let openMap: () -> Void

    @Environment(LiveCatalogState.self) private var catalog
    @State private var feed = CatalogFeed()
    @State private var savedOnly = false
    @State private var showsFilters = false
    @State private var featuredID: String?

    private var request: CatalogRequest {
        .init(selection: catalog.selection, savedOnly: savedOnly, hasLocation: false, revision: catalog.revision)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Overline("The Vubes calendar", color: Afterglow.accent)
                        ScreenTitle("Events")
                        Text("Find your next trail, session or weekend away.")
                            .font(Afterglow.body(13)).foregroundStyle(Afterglow.muted)
                    }
                    Spacer()
                    RoundControl(icon: "map", title: "Explore map", action: openMap)
                }

                HStack(spacing: 7) {
                    Button { savedOnly = false } label: { Pill(title: "All", selected: !savedOnly) }
                    Button { savedOnly = true } label: { Pill(title: "Saved", icon: "bookmark", selected: savedOnly) }
                    Button { showsFilters = true } label: {
                        Pill(title: "Filter", icon: "slider.horizontal.3", selected: catalog.selection != CatalogSelection())
                    }
                }
                .buttonStyle(.plain)

                if !savedOnly && !feed.events.isEmpty {
                    Overline("Featured experiences", color: Afterglow.accent)
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 12) {
                            ForEach(feed.events.prefix(3)) { event in
                                feature(event)
                                    .containerRelativeFrame(.horizontal) { width, _ in
                                        feed.events.count > 1 ? width - 26 : width
                                    }
                                    .id(event.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $featuredID)
                    Hairline()
                    HStack {
                        ScreenTitle("Coming up", size: 29)
                        Spacer()
                        Overline("\(feed.total) events")
                    }
                }

                ForEach(feed.events) { CatalogEventRow(event: $0) }
                if !feed.loading && feed.events.isEmpty && feed.error == nil {
                    ContentUnavailableView(savedOnly ? "No saved events" : "No matching events",
                                           systemImage: savedOnly ? "bookmark" : "slider.horizontal.3")
                }
                CatalogFeedFooter(feed: feed) { more in
                    await feed.load(api, request: request, more: more)
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 8)
        }
        .refreshable { await feed.load(api, request: request) }
        .task(id: request) { await feed.load(api, request: request) }
        .sheet(isPresented: $showsFilters) { CatalogFilterSheet(api: api) }
        .scrollIndicators(.hidden)
    }

    private func feature(_ event: CatalogCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: ClubRoute.details(event.id)) {
                ClubPhoto(name: event.image)
                    .frame(height: 248)
                    .overlay(alignment: .bottom) { Afterglow.shade().frame(height: 160) }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 10) {
                            Overline("\(event.primarySport.label) / \(event.placeLabel)", color: Afterglow.ivory)
                            Text(event.title).font(Afterglow.display(31))
                        }
                        .padding(16)
                    }
                    .clipShape(.rect(cornerRadius: 13))
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) { CatalogSaveControl(api: api, event: event).padding(6) }

            HStack {
                MetadataLabel(title: event.dateLabel, icon: "calendar")
                Spacer()
                MetadataLabel(title: catalog.levelLabel(event.level), icon: "mountain.2")
            }
            .padding(13)
        }
        .background(Afterglow.surface, in: .rect(cornerRadius: 16))
    }
}

struct CatalogEventRow: View {
    @Environment(LiveCatalogState.self) private var catalog
    let event: CatalogCard

    var body: some View {
        NavigationLink(value: ClubRoute.details(event.id)) {
            HStack(spacing: 15) {
                ClubPhoto(name: event.image, radius: 9)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 6) {
                    Overline(event.primarySport.label, color: Afterglow.accent)
                    Text(event.title).font(Afterglow.medium(16))
                    Text("\(event.dateLabel) · \(event.placeLabel)")
                        .font(Afterglow.body(11.3, relativeTo: .caption))
                        .foregroundStyle(Afterglow.muted)
                    let facts = [catalog.levelLabel(event.level), event.distanceLabel,
                                 event.phase == "upcoming" ? event.price.display : nil]
                    Text(facts.compactMap { $0 }.joined(separator: " · "))
                        .font(Afterglow.medium(11, relativeTo: .caption))
                    if let rating = event.rating, let average = rating.average {
                        Label("\(average.formatted(.number.precision(.fractionLength(1)))) · \(rating.count)", systemImage: "star.fill")
                            .font(Afterglow.medium(11)).foregroundStyle(Afterglow.accent)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Afterglow.accent)
            }
            .padding(10)
            .background(Afterglow.surface, in: .rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Afterglow.border.opacity(0.7)) }
        }
        .buttonStyle(.plain)
    }
}

struct CatalogFeedFooter: View {
    let feed: CatalogFeed
    let load: (Bool) async -> Void

    var body: some View {
        if feed.loading {
            ProgressView().frame(maxWidth: .infinity)
        } else if let error = feed.error {
            VStack {
                Text(error).font(.footnote)
                Button("Retry") { Task { await load(feed.cursor != nil) } }
            }
            .frame(maxWidth: .infinity)
        } else if feed.cursor != nil {
            Button("Load more") { Task { await load(true) } }
                .frame(maxWidth: .infinity)
        }
    }
}

struct CatalogSaveControl: View {
    @Environment(LiveCatalogState.self) private var catalog
    let api: ClubAPI
    let event: CatalogCard
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        RoundControl(icon: event.isSaved ? "bookmark.fill" : "bookmark",
                     title: event.isSaved ? "Remove from saved events" : "Save event") {
            guard !saving else { return }
            saving = true
            Task {
                defer { saving = false }
                do { try await catalog.setSaved(!event.isSaved, eventID: event.id, api: api) }
                catch { self.error = error.localizedDescription }
            }
        }
        .disabled(saving)
        .alert("Saved events", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }
}

struct CatalogFilterSheet: View {
    @Environment(LiveCatalogState.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    let api: ClubAPI

    var body: some View {
        @Bindable var catalog = catalog
        NavigationStack {
            Form {
                if let filters = catalog.filters {
                    Picker("Sport", selection: $catalog.selection.sport) {
                        Text("All sports").tag(nil as String?)
                        ForEach(filters.sports) { Text($0.label).tag(Optional($0.code)) }
                    }
                    Picker("Level", selection: $catalog.selection.level) {
                        Text("All levels").tag(nil as String?)
                        ForEach(filters.levels) { Text($0.label).tag(Optional($0.code)) }
                    }
                    Button("Clear filters") { catalog.selection = CatalogSelection() }
                } else if let error {
                    Text(error)
                    Button("Retry") { Task { await load() } }
                } else {
                    ProgressView()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Afterglow.background)
            .navigationTitle("Sport & level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
        .task { await load() }
        .presentationDetents([.medium, .large])
    }

    private func load() async {
        error = nil
        do { try await catalog.loadFilters(api) }
        catch { if !Task.isCancelled { self.error = error.localizedDescription } }
    }
}
