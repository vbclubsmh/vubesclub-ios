import SwiftUI

enum VerificationKind: Hashable { case signIn, application }

struct VerificationRequest: Hashable, Identifiable {
    let challenge: SMSChallenge
    let digits: String
    let kind: VerificationKind

    var id: UUID { challenge.challengeId }
}

struct VerificationScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    private enum Operation: Equatable { case verify, resend }
    @State private var challenge: SMSChallenge
    @State private var operation: Operation?
    @State private var errorMessage: String?

    private let request: VerificationRequest

    init(request: VerificationRequest) {
        self.request = request
        _challenge = State(initialValue: request.challenge)
    }

    private var showsTestCodeHint: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "VubesOTPHint") as? String) == "YES"
    }

    private var subtitle: String {
        switch challenge.channel {
        case "email":
            return L("We sent a %d-digit code to the email address on your membership. It stays valid for 15 minutes. Check your spam folder too.", codeLength)
        case "test":
            let sent = L("We sent a %d-digit code to +90 %@.", codeLength, request.digits)
            return showsTestCodeHint ? sent + " " + L("Test build: use code 1111.") : sent
        default:
            return L("We sent a %d-digit code to +90 %@.", codeLength, request.digits)
        }
    }

    @State private var code = ""
    @State private var failedAttempts = 0

    /// Sunucu 4 ya da 6 gönderir; beklenmedik bir değer arayüzü bozmasın.
    private var codeLength: Int { min(max(challenge.codeLength, 4), 8) }

    var body: some View {
        AccessLayout(title: "Enter your code",
                     subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 12) {
                Overline("Verification code")

                codeInput

                HStack {
                    TimelineView(.periodic(from: .now, by: 1)) { tick in
                        Button(L("Resend code")) { operation = .resend }
                            .disabled(operation != nil || tick.date < challenge.resendAt)
                    }

                    Spacer()

                    Button(L("Change number")) { dismiss() }
                        .foregroundStyle(Afterglow.muted)
                }
                .font(Afterglow.medium(12.5))
                .buttonStyle(.plain)
                .frame(minHeight: 44)

                if let errorMessage {
                    Text(L(errorMessage))
                        .font(Afterglow.body(11, relativeTo: .caption))
                        .foregroundStyle(Afterglow.muted)
                }
            }
        } action: {
            PrimaryAction(title: "Verify & continue") { operation = .verify }
                .disabled(code.count != codeLength || operation != nil)
        }
        .task(id: operation) {
            guard let operation else { return }
            defer { self.operation = nil }
            errorMessage = nil

            do {
                switch operation {
                case .verify:
                    switch try await session.verify(challenge, code: code) {
                    case .signedIn, .applicationReceived:
                        break
                    case .unknownNumber:
                        errorMessage = "No membership found for this number. Apply with Sign up."
                        failedAttempts += 1
                    case .underReview:
                        errorMessage = "Your membership is still under review. We’ll share the decision soon."
                    }
                case .resend:
                    challenge = try await session.resendCode(challenge)
                    code = ""
                    isFocused = true
                }
            } catch {
                errorMessage = ClubAPIError.message(for: error)
                failedAttempts += 1
            }
        }
        .onChange(of: code) { _, value in
            let clean = String(value.filter { $0.isASCII && $0.isNumber }.prefix(codeLength))
            if clean != value { code = clean }
            errorMessage = nil
        }
        .defaultFocus($isFocused, true)
        .onAppear { isFocused = true }
        .sensoryFeedback(ClubHaptics.fieldFocus, trigger: isFocused) { _, focused in
            focused
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: code.count) { previous, current in
            current > previous
        }
        .sensoryFeedback(.error, trigger: failedAttempts)
    }

    private var codeInput: some View {
        HStack(spacing: 6) {
            ForEach(0..<codeLength, id: \.self) { index in
                let digit = code.dropFirst(index).first
                let current = index == code.count

                Text(digit.map(String.init) ?? (current ? "|" : " "))
                    .font(Afterglow.medium(19))
                    .frame(maxWidth: .infinity, minHeight: 57)
                    .background(Afterglow.surface, in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(current ? Afterglow.ivory : Afterglow.border)
                    }
            }
        }
        .accessibilityHidden(true)
        .overlay {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accessibilityLabel(L("Verification code"))
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

}
