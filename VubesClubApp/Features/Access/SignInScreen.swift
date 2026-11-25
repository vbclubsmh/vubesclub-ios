import SwiftUI

struct SignInScreen: View {
    let invited: Bool
    @State private var invitation = ""
    @State private var phone = ""
    @State private var fullName = ""
    @State private var confirmsAge = false
    @State private var destination: DemoOTPChallenge?
    @State private var errorMessage: String?
    @FocusState private var phoneFocused: Bool

    private var canContinue: Bool {
        phone.count == 10 && (!invited || (
            !invitation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !fullName.trimmingCharacters(in: .whitespaces).isEmpty
                && confirmsAge
        ))
    }

    var body: some View {
        AccessLayout(
            title: invited ? "Your invitation" : "Sign in",
            subtitle: invited ? "Enter your invitation and member details." : "Use your mobile number to continue."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if invited {
                    Overline("Invitation code")
                    TextField("Invitation code", text: $invitation)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Afterglow.surface, in: .rect(cornerRadius: 8))

                    Overline("Full name")
                    TextField("Full name", text: $fullName)
                        .textContentType(.name)
                        .padding(12)
                        .background(Afterglow.surface, in: .rect(cornerRadius: 8))

                    Toggle("I am 18 or older", isOn: $confirmsAge)
                }

                Overline("Mobile number")

                HStack(spacing: 16) {
                    Text("+90").font(Afterglow.medium(15))

                    Rectangle()
                        .fill(Afterglow.border)
                        .frame(width: 1, height: 28)

                    TextField("5XX XXX XX XX", text: phoneInput)
                        .font(Afterglow.body(15))
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .focused($phoneFocused)
                        .accessibilityLabel("Mobile number")
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 57)
                .background(Afterglow.surface, in: .rect(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Afterglow.border) }
            }
        } action: {
            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(Afterglow.body(12))
                        .accessibilityLabel("Sign-in error: \(errorMessage)")
                }

                PrimaryAction(title: "Continue") {
                    errorMessage = nil
                    destination = DemoOTPChallenge()
                }
                .disabled(!canContinue)
            }
        }
        .onAppear {
            if !invited { phoneFocused = true }
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

    private var phoneInput: Binding<String> {
        Binding(
            get: { phone },
            set: { phone = String($0.filter { $0.isASCII && $0.isNumber }.prefix(10)) }
        )
    }
}
