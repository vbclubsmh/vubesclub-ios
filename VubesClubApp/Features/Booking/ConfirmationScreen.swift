import SwiftUI

struct ConfirmationScreen: View {
    let event: ClubEvent
    let onMyEvents: () -> Void

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
                    Text("Your booking is confirmed.")
                        .font(Afterglow.body(14))
                        .foregroundStyle(Afterglow.muted)

                    EventPass(event: event)
                        .padding(.top, 28)
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
    }
}
