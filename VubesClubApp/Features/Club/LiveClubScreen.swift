import SwiftUI

struct CommunityMedia: Decodable {
    let url: String
}

struct LiveTrainer: Identifiable, Decodable {
    let id: String
    let displayName: String
    let specialty: String
    let experienceText: String
    let locationLabel: String
    let bio: String
    let avatar: CommunityMedia?
    let cover: CommunityMedia?
    var isFollowed: Bool
    var introductionState: String
}

private struct TrainerDirectory: Decodable {
    let items: [LiveTrainer]
    let nextCursor: String?
}

private struct TrainerDetailResponse: Decodable {
    struct Crew: Decodable {
        struct Person: Decodable {
            let displayName: String
            let avatar: CommunityMedia?
        }

        let name: String
        let members: [Person]
    }

    var trainer: LiveTrainer
    let crew: Crew?
    let upcoming: [CatalogCard]
    let ratedExperiences: [CatalogCard]
}

struct LiveClubScreen: View {
    let api: ClubAPI

    @State private var directory: [LiveTrainer] = []
    @State private var selectedID: String?
    @State private var detail: TrainerDetailResponse?
    @State private var followingOnly = false
    @State private var directoryLoaded = false
    @State private var directoryError: String?
    @State private var detailError: String?

    private var trainers: [LiveTrainer] {
        directory.filter { !followingOnly || $0.isFollowed }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Overline("The people behind the sessions", color: Afterglow.accent)
                ScreenTitle("Club")
                HStack {
                    Button { followingOnly = false } label: { Pill(title: "All trainers", selected: !followingOnly) }
                    Button { followingOnly = true } label: { Pill(title: "Following", selected: followingOnly) }
                }
                .buttonStyle(.plain)

                if let directoryError {
                    retry(directoryError) { await loadDirectory() }
                } else if !directoryLoaded {
                    ProgressView()
                } else if trainers.isEmpty {
                    ContentUnavailableView(followingOnly ? "No trainers followed yet" : "No trainers available",
                                           systemImage: "person.2")
                } else {
                    trainerPicker
                    if let detail, detail.trainer.id == selectedID {
                        LiveTrainerCard(api: api, trainer: detail.trainer, onChange: updateTrainer)
                            .id(detail.trainer.id)
                        if let crew = detail.crew { crewSection(crew) }
                        events("Upcoming experiences", detail.upcoming)
                        events("Rated experiences", detail.ratedExperiences)
                    } else if let detailError {
                        retry(detailError) { await loadDetail() }
                    } else {
                        ProgressView()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 12)
        }
        .task { await loadDirectory() }
        .refreshable { await loadDirectory(); await loadDetail() }
        .onChange(of: trainers.map(\.id), initial: true) { _, ids in
            if !ids.contains(selectedID ?? "") { selectedID = ids.first }
        }
        .task(id: selectedID) { await loadDetail() }
    }

    private var trainerPicker: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(trainers) { trainer in
                    Button { selectedID = trainer.id } label: {
                        VStack {
                            Avatar(image: trainer.avatar?.url ?? "", size: 41, selected: selectedID == trainer.id)
                            Text(trainer.displayName).font(Afterglow.medium(12))
                        }
                        .padding(8)
                        .background(Afterglow.surface, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedID == trainer.id ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func crewSection(_ crew: TrainerDetailResponse.Crew) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline("Crew", color: Afterglow.accent)
            ScreenTitle(crew.name, size: 26)
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(Array(crew.members.enumerated()), id: \.offset) { _, member in
                        VStack {
                            Avatar(image: member.avatar?.url ?? "", size: 43)
                            Text(member.displayName).font(Afterglow.medium(12))
                        }
                    }
                }
            }
        }
    }

    private func events(_ title: String, _ items: [CatalogCard]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Hairline()
            ScreenTitle(title, size: 26)
            if items.isEmpty { Text("No events").foregroundStyle(Afterglow.muted) }
            ForEach(items) { event in CatalogEventRow(event: event) }
        }
    }

    private func retry(_ message: String, action: @escaping () async -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message).font(Afterglow.body(14))
            Button("Try again") { Task { await action() } }
        }
    }

    private func updateTrainer(_ trainer: LiveTrainer) {
        if let index = directory.firstIndex(where: { $0.id == trainer.id }) { directory[index] = trainer }
        if detail?.trainer.id == trainer.id { detail?.trainer = trainer }
    }

    private func loadDirectory() async {
        directoryError = nil
        do {
            var rows: [LiveTrainer] = []
            var cursor: String?
            repeat {
                var route = URLComponents()
                route.path = "club/trainers"
                if let cursor { route.queryItems = [URLQueryItem(name: "cursor", value: cursor)] }
                let page = try await api.get(route.string ?? "club/trainers", as: TrainerDirectory.self)
                rows.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            try Task.checkCancellation()
            directory = rows
            directoryLoaded = true
        } catch {
            if !Task.isCancelled { directoryError = error.localizedDescription }
        }
    }

    private func loadDetail() async {
        detailError = nil
        guard let id = selectedID else { detail = nil; return }
        do {
            let value = try await api.get("club/trainers/\(id)", as: TrainerDetailResponse.self)
            try Task.checkCancellation()
            if selectedID == id { detail = value; updateTrainer(value.trainer) }
        } catch {
            if !Task.isCancelled, selectedID == id { detail = nil; detailError = error.localizedDescription }
        }
    }
}

struct LiveTrainerCard: View {
    let api: ClubAPI
    let trainer: LiveTrainer
    var onChange: (LiveTrainer) -> Void = { _ in }

    @State private var current: LiveTrainer?
    @State private var saving = false
    @State private var requestIntroduction = false
    @State private var errorMessage: String?

    var body: some View {
        let value = current ?? trainer
        VStack(alignment: .leading, spacing: 12) {
            ClubPhoto(name: value.cover?.url ?? "", radius: 13)
                .frame(height: 132)
                .overlay(alignment: .bottomLeading) {
                    Avatar(image: value.avatar?.url ?? "", size: 63, selected: true).padding(12)
                }
            Overline("Personal trainer", color: Afterglow.accent)
            ScreenTitle(value.displayName, size: 28)
            Text(value.specialty).font(Afterglow.medium(13))
            Text(value.bio).font(Afterglow.body(13)).foregroundStyle(Afterglow.muted)
            ViewThatFits {
                HStack { facts(value) }
                VStack(alignment: .leading) { facts(value) }
            }

            PrimaryAction(title: value.isFollowed ? "Following" : "Follow trainer",
                          icon: value.isFollowed ? "checkmark" : "person.badge.plus") {
                Task { await saveIntroduction(false) }
            }
            Button(value.introductionState == "none" ? "Request an introduction" : "Introduction requested") {
                requestIntroduction = true
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(value.introductionState != "none")
            if let errorMessage { Text(errorMessage).font(Afterglow.body(13)) }
        }
        .disabled(saving)
        .padding(12)
        .background(Afterglow.surface, in: .rect(cornerRadius: 18))
        .alert("Meet \(value.displayName)", isPresented: $requestIntroduction) {
            Button("Cancel", role: .cancel) {}
            Button("Request introduction") { Task { await saveIntroduction(true) } }
        }
        .onChange(of: trainer.id) { current = nil; errorMessage = nil }
        .onChange(of: trainer.isFollowed) { current = nil }
        .onChange(of: trainer.introductionState) { current = nil }
    }

    @ViewBuilder
    private func facts(_ value: LiveTrainer) -> some View {
        MetadataLabel(title: value.experienceText, icon: "clock")
        MetadataLabel(title: value.locationLabel, icon: "mappin")
    }

    private func saveIntroduction(_ introduce: Bool) async {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        errorMessage = nil
        var value = current ?? trainer
        do {
            if introduce {
                struct Introduction: Decodable { let state: String }
                let response = try await api.send("PUT", "me/trainer-introductions/\(value.id)",
                                                  body: [String: String](), as: Introduction.self)
                value.introductionState = response.state
            } else {
                try await api.empty(value.isFollowed ? "DELETE" : "PUT", "me/followed-trainers/\(value.id)")
                value.isFollowed.toggle()
            }
            current = value
            onChange(value)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
