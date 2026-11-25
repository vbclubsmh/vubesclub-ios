import SwiftUI

struct CheckoutScreen: View {
    @Environment(DemoSession.self) private var session

    let event: ClubEvent
    let onConfirmation: () -> Void

    @State private var acceptsTerms = false
    @State private var confirmed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackControl().offset(x: -3)
                ScreenTitle("Checkout", size: 46)
                eventCard

                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle("Your booking", size: 29)
                        .padding(.bottom, 12)

                    summaryRow("1 participant", icon: "person")

                    let days = event.program.count
                    summaryRow(days == 1 ? "Full day program" : "Full \(days)-day program", icon: "calendar")

                    if event.accommodation != nil {
                        summaryRow("Accommodation included", icon: "bed.double")
                    }
                }
                .padding(.top, 7)

                HStack {
                    Text("Total").font(Afterglow.medium(15))
                    Spacer()

                    Text(event.priceLabel)
                        .font(Afterglow.display(40, relativeTo: .title))
                        .foregroundStyle(Afterglow.ivory)
                }

                Button {
                    acceptsTerms.toggle()
                } label: {
                    Label("I agree to the participation terms.",
                          systemImage: acceptsTerms ? "checkmark.square.fill" : "square")
                        .font(Afterglow.body(12))
                        .foregroundStyle(Afterglow.muted)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(acceptsTerms ? .isSelected : [])
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryAction(title: "Pay now", icon: "lock") {
                guard !confirmed, session.confirmBooking(for: event) else { return }

                confirmed = true
                onConfirmation()
            }
            .disabled(!acceptsTerms || confirmed)
            .sensoryFeedback(.success, trigger: confirmed)
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 5)
            .background(Afterglow.background)
        }
    }

    private var eventCard: some View {
        HStack(spacing: 13) {
            ClubPhoto(name: event.image, radius: 8)
                .frame(width: 112, height: 102)

            VStack(alignment: .leading, spacing: 9) {
                Overline("\(event.date)  /  \(event.location)")
                Text(event.title)
                    .font(Afterglow.display(25, relativeTo: .title2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Afterglow.surface, in: .rect(cornerRadius: 12))
    }

    private func summaryRow(_ title: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MetadataLabel(title: title, icon: icon)
                .frame(minHeight: 41)

            Hairline()
        }
    }
}
