import SwiftUI

/// Tek bir PT: kart, ekip ve etkinlikleri. Sunucudan yüklenir.
struct TrainerDetailScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(EventCatalog.self) private var catalog

    let trainerID: String

    @State private var content: TrainerContent?
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    BackControl()
                    Spacer()
                }

                if let content {
                    TrainerCard(trainer: content.trainer)

                    if !content.trainer.crew.isEmpty {
                        crew(content.trainer)
                    }

                    if !content.upcoming.isEmpty {
                        events(L("Upcoming with %@", String(content.trainer.name.split(separator: " ").first ?? "")),
                               content.upcoming)
                    }

                    if !content.rated.isEmpty {
                        events(L("Rated experiences"), content.rated)
                    }
                } else if loading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ContentUnavailableView(
                        L("Trainer unavailable"),
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(L("This profile couldn’t be loaded."))
                    )
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .task(id: trainerID) {
            loading = true
            content = await catalog.trainerContent(id: trainerID, session: session)
            loading = false
        }
    }

    private func crew(_ trainer: ClubTrainer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline("Crew", color: Afterglow.accent)
            ScreenTitle(trainer.crewName.isEmpty ? L("Crew") : trainer.crewName, size: 26)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(trainer.crew) { member in
                        VStack(spacing: 6) {
                            Avatar(image: member.image, size: 43, name: member.name)

                            Text(member.name)
                                .font(Afterglow.medium(12, relativeTo: .caption))
                                .foregroundStyle(Afterglow.muted)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func events(_ title: String, _ events: [ClubEvent]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Hairline()
            ScreenTitle(title, size: 26)

            ForEach(events) { event in
                EventListRow(event: event)
            }
        }
    }
}

/// Erişilebilir tüm PT'ler; buradan profile geçilip takip edilir.
struct TrainerDirectoryScreen: View {
    @Environment(EventCatalog.self) private var catalog

    @State private var trainers: [ClubTrainer]?
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    BackControl()
                    Spacer()
                }

                ScreenTitle("All trainers", size: 32)

                if let trainers {
                    ForEach(trainers) { trainer in
                        NavigationLink(value: ClubRoute.trainer(trainer.id)) {
                            HStack(spacing: 12) {
                                Avatar(image: trainer.image, size: 46, name: trainer.name)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(trainer.name).font(Afterglow.medium(15))
                                    Text(L(trainer.specialty))
                                        .font(Afterglow.body(12))
                                        .foregroundStyle(Afterglow.muted)
                                }

                                Spacer(minLength: 4)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Afterglow.accent)
                                    .accessibilityHidden(true)
                            }
                            .padding(11)
                            .background(Afterglow.surface, in: .rect(cornerRadius: 14))
                            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Afterglow.border.opacity(0.7)) }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } else if failed {
                    ContentUnavailableView(L("Trainers couldn’t be loaded"), systemImage: "wifi.slash")
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .task {
            trainers = await catalog.trainerDirectory()
            failed = trainers == nil
        }
    }
}
