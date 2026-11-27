import SwiftUI

struct ConfirmationScreen: View {
    @Environment(BookingCenter.self) private var bookings

    let event: ClubEvent
    let onMyEvents: () -> Void

    @State private var payload: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ClubPhoto(name: event.image)
                    .frame(height: 376)
                    .overlay(alignment: .bottom) {
                        Afterglow.shade().frame(height: 223)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Afterglow.background)
                            .frame(width: 56, height: 56)
                            .background(Afterglow.ivory, in: Circle())
                            .padding(.leading, Afterglow.inset)
                            .padding(.bottom, 5)
                            .accessibilityHidden(true)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    ScreenTitle("You’re in.", size: 54)
                    Text(L("Your registration has been received."))
                        .font(Afterglow.body(14))
                        .foregroundStyle(Afterglow.muted)

                    LargePassQR(payload: payload)
                        .padding(.top, 22)

                    EventPass(event: event, payload: payload)
                        .padding(.top, 18)
                }
                .padding(.horizontal, Afterglow.inset)
                .padding(.top, 9)
                .padding(.bottom, 20)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(.container, edges: .top)
        .background(Afterglow.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryAction(title: "Go to My Events", action: onMyEvents)
                .padding(.horizontal, Afterglow.inset)
                .padding(.bottom, 5)
                .background(Afterglow.background)
        }
        .navigationBarBackButtonHidden()
        .task {
            guard let booking = bookings.booking(forEvent: event.id) else { return }

            payload = await bookings.passPayload(bookingID: booking.bookingID)
        }
    }
}
