import SwiftUI

struct SignInScreen: View {
    @State private var phone = ""
    @State private var destination: DemoOTPChallenge?
    @State private var errorMessage: String?
    @FocusState private var phoneFocused: Bool

    private var canContinue: Bool {
        phone.count == 10
    }

    var body: some View {
        AccessLayout(
            title: "Sign in",
            subtitle: "Use your mobile number to continue."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Overline("Mobile number")

                HStack(spacing: 16) {
                    Text("+90").font(Afterglow.medium(15))

                    Rectangle()
                        .fill(Afterglow.border)
                        .frame(width: 1, height: 28)

                    TextField("5XX XXX XX XX", text: $phone)
                        .font(Afterglow.body(15))
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .focused($phoneFocused)
                        .accessibilityLabel(L("Mobile number"))
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 57)
                .background(Afterglow.surface, in: .rect(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Afterglow.border) }
            }
        } action: {
            VStack(spacing: 10) {
                if let errorMessage {
                    Text(L(errorMessage))
                        .font(Afterglow.body(12))
                        .accessibilityLabel(L("Sign-in error: %@", L(errorMessage)))
                }

                PrimaryAction(title: "Continue") {
                    errorMessage = nil
                    destination = DemoOTPChallenge()
                }
                .disabled(!canContinue)
            }
        }
        .onChange(of: phone) { _, value in
            let clean = SignUpScreen.turkishMobile(value)
            if clean != value { phone = clean }
        }
        .defaultFocus($phoneFocused, true)
        .onAppear {
            phoneFocused = true
        }
        .sensoryFeedback(ClubHaptics.fieldFocus, trigger: phoneFocused) { _, focused in
            focused
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: phone.count) { previous, current in
            current > previous
        }
        .navigationDestination(item: $destination) { challenge in
            VerificationScreen(challenge: challenge)
                .toolbar(.hidden, for: .navigationBar)
        }
    }

}
