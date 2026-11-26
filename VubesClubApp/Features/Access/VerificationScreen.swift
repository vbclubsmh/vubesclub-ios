import SwiftUI

struct VerificationScreen: View {
    @Environment(DemoSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    private enum Operation: Equatable { case verify, resend }
    @State private var challenge: DemoOTPChallenge
    @State private var operation: Operation?
    @State private var errorMessage: String?

    init(challenge: DemoOTPChallenge) {
        _challenge = State(initialValue: challenge)
    }

    @State private var code = ""
    @State private var failedAttempts = 0

    private var codeLength: Int { challenge.codeLength }

    var body: some View {
        AccessLayout(title: "Enter your code",
                     subtitle: "For this demo, use verification code 1111.") {
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

            switch operation {
            case .verify:
                guard code == "1111" else {
                    errorMessage = "For this demo, enter 1111."
                    failedAttempts += 1
                    return
                }
                session.signIn()
            case .resend:
                challenge = DemoOTPChallenge()
                code = ""
                isFocused = true
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
