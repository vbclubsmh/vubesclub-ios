import SwiftUI

struct ClubScreen: View {
    @Environment(DemoSession.self) private var session

    @State private var selectedTrainerID: ClubTrainer.ID? = DemoClub.deniz.id
    @State private var showingFollowing = false

    private var trainers: [ClubTrainer] {
        DemoClub.trainers.filter {
            !showingFollowing || session.connectedTrainerIDs.contains($0.id)
        }
    }

    private var trainer: ClubTrainer? {
        trainers.first { $0.id == selectedTrainerID } ?? trainers.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Overline("The people behind the sessions", color: Afterglow.accent)
                    ScreenTitle("Club")

                    Text("Meet the coaches, get to know their crews and see what members thought of their last sessions.")
                        .font(Afterglow.body(13))
                        .foregroundStyle(Afterglow.muted)
                }

                scopeControls
                    .zIndex(1)

                if let trainer {
                    trainerPicker(selected: trainer.id)
                        .zIndex(1)
                    trainerContent(trainer)
                } else {
                    ContentUnavailableView(
                        "No trainers followed yet",
                        systemImage: "person.2",
                        description: Text("Follow a trainer to find their crew and events here.")
                    )
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .onChange(of: trainers.map(\.id), initial: true) { _, ids in
            if let selectedTrainerID, ids.contains(selectedTrainerID) { return }

            selectedTrainerID = ids.first
        }
    }

    private func trainerContent(_ trainer: ClubTrainer) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            TrainerCard(trainer: trainer)
            crewSection(trainer)
            eventsSection("Upcoming with \(trainer.name.split(separator: " ").first ?? "")",
                          events: DemoClub.events(for: trainer, status: .upcoming))
            eventsSection("Rated experiences", events: DemoClub.events(for: trainer, status: .past))
        }
    }

    private var scopeControls: some View {
        HStack(spacing: 8) {
            Button { showingFollowing = false } label: {
                Pill(title: "All trainers", selected: !showingFollowing)
            }

            Button { showingFollowing = true } label: {
                Pill(title: "Following", icon: "person.crop.circle.badge.checkmark", selected: showingFollowing)
            }
        }
        .buttonStyle(.plain)
    }

    private func trainerPicker(selected: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            ForEach(trainers) { trainer in
                let isSelected = trainer.id == selected

                Button {
                    selectedTrainerID = trainer.id
                } label: {
                    VStack(spacing: 6) {
                        Avatar(image: trainer.image, size: 37, selected: isSelected)

                        Text(trainer.name)
                            .font(Afterglow.medium(11, relativeTo: .caption))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(isSelected ? Afterglow.ivory : Afterglow.muted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 9)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 68)
                    .background(Afterglow.surface, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Afterglow.accent : Afterglow.border)
                            .allowsHitTesting(false)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: selectedTrainerID)
    }

    private func crewSection(_ trainer: ClubTrainer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline("Crew", color: Afterglow.accent)
            ScreenTitle(trainer.crewName, size: 26)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(trainer.crew) { member in
                        VStack(spacing: 6) {
                            Avatar(image: member.image, size: 43)

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

    private func eventsSection(_ title: String, events: [ClubEvent]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Hairline()
            ScreenTitle(title, size: 26)

            ForEach(events) { event in
                EventListRow(event: event)
            }
        }
    }
}
