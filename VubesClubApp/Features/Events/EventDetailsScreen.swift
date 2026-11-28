import SwiftUI

struct EventDetailsScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(EventCatalog.self) private var catalog

    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight = 283.0

    let event: ClubEvent

    @State private var showsPreparation = false
    @State private var photoIndex = 0
    @State private var viewerIndex: Int?

    private var photos: [String] {
        var seen = Set<String>()
        return ([event.image] + event.gallery).filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero

                if photos.count > 1 {
                    thumbnails
                }

                VStack(alignment: .leading, spacing: 19) {
                    eventFacts

                    if let seats = event.seats, event.status != .past {
                        SeatsMeter(seats: seats)
                    }

                    Hairline()

                    if event.status == .inProgress {
                        activityPreview
                    }

                    ItineraryView(days: event.program)

                    if let trainer = catalog.trainer(event.trainerID) {
                        TrainerCard(trainer: trainer)
                    }

                    EventRatingSection(event: event)
                    Hairline()

                    DisclosureGroup(L(event.accommodation == nil ? "What to bring & meeting point" : "What to bring & stay details"), isExpanded: $showsPreparation) {
                        VStack(alignment: .leading, spacing: 9) {
                            Text(L(event.preparation))
                            Text(L("Meeting point: %@", L(event.meetingPoint)))

                            if let accommodation = event.accommodation {
                                Text(L(accommodation))
                            }
                        }
                        .font(Afterglow.body(12))
                        .foregroundStyle(Afterglow.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    }
                    .font(Afterglow.medium(12.5))
                }
                .padding(.horizontal, Afterglow.inset)
                .padding(.top, 12)
                .padding(.bottom, 15)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(.container, edges: .top)
        .background(Afterglow.background.ignoresSafeArea())
        .fullScreenCover(item: Binding(get: { viewerIndex.map(PhotoSelection.init) }, set: { viewerIndex = $0?.index })) { selection in
            PhotoViewer(photos: photos, index: selection.index) { photoIndex = $0 }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if event.status == .upcoming {
                bookingBar
            }
        }
    }

    private var hero: some View {
        Group {
            if photos.count > 1 {
                TabView(selection: $photoIndex) {
                    ForEach(photos.indices, id: \.self) { index in
                        ClubPhoto(name: photos[index])
                            .contentShape(Rectangle())
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                ClubPhoto(name: photos.first ?? event.image)
            }
        }
        .frame(height: heroHeight)
        .onChange(of: photos) { _, updatedPhotos in
            if !updatedPhotos.indices.contains(photoIndex) { photoIndex = 0 }
        }
        .overlay(alignment: .bottom) {
            Afterglow.shade(Color.black.opacity(0.88)).frame(height: heroHeight * 0.63)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Overline("\(L(event.sport.rawValue))  /  \(L(event.location))", color: Afterglow.ivory)

                ScreenTitle(event.title, size: 36)
                    .lineSpacing(-2)
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 8)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            HStack {
                BackControl()
                Spacer()
                SaveControl(eventID: event.id)
            }
            .padding(.horizontal, 19)
            .padding(.top, 46)
        }
    }

    private var thumbnails: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(photos.indices, id: \.self) { index in
                    Button {
                        photoIndex = index
                        viewerIndex = index
                    } label: {
                        ClubPhoto(name: photos[index], radius: 8)
                            .frame(width: 74, height: 54)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Afterglow.ivory, lineWidth: index == photoIndex ? 1.5 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(index + 1) / \(photos.count)")
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var eventFacts: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 15) {
                MetadataLabel(title: event.displayDate, icon: "calendar")
                MetadataLabel(title: event.level.rawValue, icon: "mountain.2")

                Spacer(minLength: 0)

                if let trainer = catalog.trainer(event.trainerID) {
                    organizer(trainer)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                MetadataLabel(title: event.displayDate, icon: "calendar")
                MetadataLabel(title: event.level.rawValue, icon: "mountain.2")
                if let trainer = catalog.trainer(event.trainerID) {
                    organizer(trainer)
                }
            }
        }
    }

    private func organizer(_ trainer: ClubTrainer) -> some View {
        HStack(spacing: 7) {
            Avatar(image: trainer.image, size: 22)
            Text(trainer.name).font(Afterglow.body(11, relativeTo: .caption))
        }
        .foregroundStyle(Afterglow.muted)
        .accessibilityLabel(L("Organizer: %@", trainer.name))
    }

    private var activityPreview: some View {
        NavigationLink(value: ClubRoute.activityMap(event.id)) {
            VStack(alignment: .leading, spacing: 11) {
                Overline("In progress", color: Afterglow.green)

                ClubPhoto(name: "Coast", radius: 13)
                    .frame(height: 134)
                    .overlay(alignment: .center) {
                        Avatar(image: "Portrait1", size: 24, selected: true).offset(x: 14, y: -17)
                        Avatar(image: "Portrait4", size: 21).offset(x: 64, y: 2)
                    }
                    .overlay(alignment: .bottom) {
                        HStack {
                            Label(L("Open activity map"), systemImage: "map")
                            Spacer()
                            Image(systemName: "arrow.up.right").accessibilityHidden(true)
                        }
                        .font(Afterglow.medium(13))
                        .padding(12)
                        .background(Afterglow.background.opacity(0.84))
                    }
                    .clipShape(.rect(cornerRadius: 13))
            }
        }
        .buttonStyle(.plain)
    }

    private var bookingBar: some View {
        let booked = session.bookingIDs.contains(event.id)

        return NavigationLink(value: booked ? ClubRoute.confirmation(event.id) : ClubRoute.checkout(event.id)) {
            Text(L(booked ? "View event pass" : "Join event"))
                .font(Afterglow.medium(14))
                .foregroundStyle(Afterglow.background)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Afterglow.ivory, in: .rect(cornerRadius: 8))
                .overlay(alignment: .trailing) {
                    Image(systemName: "arrow.right")
                        .padding(.trailing, 17)
                        .foregroundStyle(Afterglow.background)
                        .accessibilityHidden(true)
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Afterglow.inset)
        .padding(.bottom, 5)
        .background(Afterglow.background)
    }
}

private struct PhotoSelection: Identifiable {
    let index: Int
    var id: Int { index }
}

/// Tam ekran, sağa sola kaydırmalı görsel gezgini.
private struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss

    let photos: [String]
    @State var index: Int
    let onChange: (Int) -> Void

    init(photos: [String], index: Int, onChange: @escaping (Int) -> Void) {
        self.photos = photos
        self._index = State(initialValue: index)
        self.onChange = onChange
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(photos.indices, id: \.self) { position in
                    ClubMediaImage(source: photos[position], fit: true)
                        .padding(.vertical, 60)
                        .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .ignoresSafeArea()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Afterglow.ivory)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.14), in: .circle)
            }
            .padding(16)
            .accessibilityLabel(L("Close"))
        }
        .onChange(of: index) { _, value in onChange(value) }
    }
}
