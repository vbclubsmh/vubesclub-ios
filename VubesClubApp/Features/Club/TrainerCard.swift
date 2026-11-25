import SwiftUI

struct TrainerCard: View {
    @Environment(DemoSession.self) private var session

    let trainer: ClubTrainer

    @State private var showsIntroduction = false

    var body: some View {
        let connected = session.connectedTrainerIDs.contains(trainer.id)
        let hasIntroduction = session.trainerIntroductionIDs.contains(trainer.id)

        VStack(alignment: .leading, spacing: 14) {
            ClubPhoto(name: trainer.cover, radius: 13)
                .frame(height: 132)
                .overlay(alignment: .bottomLeading) {
                    Avatar(image: trainer.image, size: 63, selected: true)
                        .padding(12)
                }
                // A fill-scaled portrait can extend past the clipped cover’s bounds.
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 9) {
                Overline("Personal trainer", color: Afterglow.accent)
                ScreenTitle(trainer.name, size: 28)

                Text(trainer.specialty)
                    .font(Afterglow.medium(13))
                    .foregroundStyle(Afterglow.ivory)

                Text(trainer.bio)
                    .font(Afterglow.body(12.5))
                    .foregroundStyle(Afterglow.muted)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        trainerFacts
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        trainerFacts
                    }
                }
                .padding(.top, 3)

                Button {
                    session.toggleTrainerConnection(trainer)
                } label: {
                    Label(connected ? "Following" : "Follow trainer",
                          systemImage: connected ? "checkmark" : "person.badge.plus")
                        .font(Afterglow.medium(13))
                        .foregroundStyle(connected ? Afterglow.ivory : Afterglow.background)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(connected ? Afterglow.background : Afterglow.ivory, in: .rect(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(connected ? .isSelected : [])
                .padding(.top, 6)
                .sensoryFeedback(ClubHaptics.selection, trigger: connected)

                Button {
                    showsIntroduction = true
                } label: {
                    Label(hasIntroduction ? "Introduction requested" : "Request an introduction",
                          systemImage: hasIntroduction ? "checkmark.circle" : "bubble.left")
                        .font(Afterglow.medium(12))
                        .foregroundStyle(Afterglow.ivory)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .disabled(hasIntroduction)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .padding(9)
        .background(Afterglow.surface, in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Afterglow.border) }
        .onChange(of: trainer.id) { _, _ in
            showsIntroduction = false
        }
        .alert("Meet \(trainer.name)", isPresented: $showsIntroduction) {
            Button("Cancel", role: .cancel) {}
            Button("Request introduction") { session.requestTrainerIntroduction(trainer) }
        } message: {
            Text("Save a demo request to connect with this trainer.")
        }
    }

    private var trainerFacts: some View {
        Group {
            MetadataLabel(title: trainer.experience, icon: "clock")
            MetadataLabel(title: trainer.location, icon: "mappin")
        }
    }
}
