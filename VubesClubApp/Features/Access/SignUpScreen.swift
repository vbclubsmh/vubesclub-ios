import SwiftUI
import UIKit

struct SignUpScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 1
    @State private var destination: VerificationRequest?
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var birthDate: Date?
    @State private var university = ""
    @State private var jobTitle = ""
    @State private var heightCm = ""
    @State private var weightKg = ""
    @State private var instagram = ""
    @State private var linkedIn = ""
    @State private var invitationCode = ""
    @State private var adultDeclared = false
    @FocusState private var focus: Field?
    @State private var focusIsAutomatic = false

    private enum Field: Hashable { case name, university, invitation, other }

    private var typedCharacters: Int {
        [fullName, email, phone, university, jobTitle, heightCm, weightKg, instagram, linkedIn, invitationCode]
            .reduce(0) { $0 + $1.count }
    }

    private let steps = ["About you", "Your profile", "Finish"]

    private var canContinue: Bool {
        switch step {
        case 1:
            !fullName.trimmed.isEmpty && email.contains("@") && phone.count == 10 && birthDate != nil
        case 2:
            !university.trimmed.isEmpty && !jobTitle.trimmed.isEmpty
                && (100...250).contains(Int(heightCm) ?? 0) && (30...300).contains(Int(weightKg) ?? 0)
        default:
            adultDeclared
        }
    }

    var body: some View {
        AccessLayout(
            title: "Join the Club", subtitle: "Three short steps. About a minute.",
            onBack: step > 1 ? { step -= 1 } : nil
        ) {
            VStack(alignment: .leading, spacing: 18) {
                progress

                VStack(alignment: .leading, spacing: 14) {
                    stepFields
                }
                .id(step)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.28), value: step)
        } action: {
            VStack(spacing: 10) {
                if let errorMessage {
                    Text(L(errorMessage))
                        .font(Afterglow.body(12))
                        .foregroundStyle(Afterglow.accent)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(L("Application error: %@", L(errorMessage)))
                }

                PrimaryAction(title: step == steps.count ? "Submit application" : "Continue") {
                    if step == steps.count { Task { await submit() } } else { step += 1 }
                }
                .disabled(!canContinue || isSubmitting)
            }
        }
        .navigationDestination(item: $destination) { request in
            VerificationScreen(request: request)
                .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: phone) { _, value in
            let clean = Self.turkishMobile(value)
            if clean != value { phone = clean }
        }
        .defaultFocus($focus, .name)
        .onChange(of: step) { _, value in
            focusIsAutomatic = true
            focus = [1: .name, 2: .university, 3: .invitation][value]
            Task { @MainActor in focusIsAutomatic = false }
        }
        .sensoryFeedback(ClubHaptics.fieldFocus, trigger: focus) { old, new in
            new != nil && old != new && !focusIsAutomatic
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: typedCharacters) { old, new in
            new > old
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: step)
        .sensoryFeedback(.selection, trigger: adultDeclared)
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        func optional(_ value: String) -> String? { value.trimmed.isEmpty ? nil : value.trimmed }

        let request = ApplicationCodeRequest(
            phone: ClubSession.phone(phone), fullName: fullName.trimmed, email: email.trimmed,
            university: university.trimmed, jobTitle: jobTitle.trimmed,
            heightCm: Int(heightCm) ?? 0, weightKg: Int(weightKg) ?? 0,
            birthDate: BirthDate.iso(birthDate ?? BirthDate.latest),
            workplace: nil, instagram: optional(instagram), linkedIn: optional(linkedIn),
            invitationCode: optional(invitationCode), adultDeclared: adultDeclared)

        do {
            let challenge = try await session.requestApplicationCode(request)
            destination = VerificationRequest(challenge: challenge, digits: phone, kind: .application)
        } catch {
            errorMessage = ClubAPIError.message(for: error)
        }
    }

    /// Keeps only digits, drops a leading 0 and limits to the 10 digits of a Turkish mobile number.
    static func turkishMobile(_ raw: String) -> String {
        var digits = raw.filter { $0.isASCII && $0.isNumber }
        if digits.hasPrefix("0") { digits.removeFirst() }
        return String(digits.prefix(10))
    }

    // MARK: Progress

    private var progress: some View {
        let compact = KeyboardObserver.shared.isVisible
        return VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(String(format: "%02d", step))
                    .font(Afterglow.display(compact ? 20 : 30))
                    .foregroundStyle(Afterglow.ivory)
                Text(" / 03")
                    .font(Afterglow.display(compact ? 13 : 16))
                    .foregroundStyle(Afterglow.muted)

                Spacer()

                Text(AppLanguage.shared.uppercase(L(steps[step - 1])))
                    .font(Afterglow.medium(10))
                    .tracking(1.4)
                    .foregroundStyle(Afterglow.accent)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Afterglow.border).frame(height: 1)
                    Rectangle()
                        .fill(Afterglow.ivory)
                        .frame(width: proxy.size.width * CGFloat(step) / CGFloat(steps.count), height: 2)
                }
            }
            .frame(height: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("Step %d of %d: %@", step, steps.count, L(steps[step - 1])))
    }

    // MARK: Steps

    @ViewBuilder
    private var stepFields: some View {
        switch step {
        case 1:
            field("Full name", placeholder: "Your name", text: $fullName, contentType: .name, focus: .name)
            BirthDateField(label: "Birth date", date: $birthDate)
            field("Email", placeholder: "you@example.com", text: $email, contentType: .emailAddress,
                  keyboard: .emailAddress, capitalization: .never, disableCorrection: true)
            VStack(alignment: .leading, spacing: 6) {
                Overline("Mobile number")
                HStack(spacing: 12) {
                    Text("+90").font(Afterglow.medium(15))
                    Rectangle().fill(Afterglow.border).frame(width: 1, height: 26)
                    TextField("5XX XXX XX XX", text: $phone)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                }
                .padding(14)
                .background(Afterglow.surface, in: .rect(cornerRadius: 8))
            }
        case 2:
            field("University", placeholder: "Where did you study?", text: $university, focus: .university)
            field("Job title", placeholder: "What do you do?", text: $jobTitle)
            HStack(spacing: 12) {
                numberField("Height", unit: "cm", placeholder: "175", text: $heightCm)
                numberField("Weight", unit: "kg", placeholder: "70", text: $weightKg)
            }
            if !KeyboardObserver.shared.isVisible {
                Text(L("We use height and weight to plan activities that suit you."))
                    .font(Afterglow.body(12))
                    .foregroundStyle(Afterglow.muted)
            }
        default:
            field("Invitation code · optional", placeholder: "Have one? Enter it here", text: $invitationCode,
                  capitalization: .characters, disableCorrection: true, focus: .invitation)
            field("Instagram · optional", placeholder: "@yourhandle", text: $instagram,
                  capitalization: .never, disableCorrection: true)
            field("LinkedIn · optional", placeholder: "linkedin.com/in/yourname", text: $linkedIn,
                  capitalization: .never, disableCorrection: true)

            Toggle(isOn: $adultDeclared) {
                Text(L("I confirm that I am 18 years old or older."))
                    .font(Afterglow.body(14))
            }
            .tint(Afterglow.accent)
            .padding(.top, 4)

            if !KeyboardObserver.shared.isVisible {
                Text(L("Every application is reviewed by our team. We’ll email you the decision."))
                    .font(Afterglow.body(12))
                    .foregroundStyle(Afterglow.muted)
            }
        }
    }

    // MARK: Fields

    private func field(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default,
        capitalization: TextInputAutocapitalization = .sentences,
        disableCorrection: Bool = false,
        focus tag: Field = .other
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Overline(label)
            TextField(L(placeholder), text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled(disableCorrection)
                .focused($focus, equals: tag)
                .padding(14)
                .background(Afterglow.surface, in: .rect(cornerRadius: 8))
        }
    }

    private func numberField(_ label: String, unit: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Overline(label)
            HStack(spacing: 8) {
                TextField(L(placeholder), text: Binding(
                    get: { text.wrappedValue },
                    set: { text.wrappedValue = $0 }
                ))
                .onChange(of: text.wrappedValue) { _, value in
                    let clean = String(value.filter { $0.isASCII && $0.isNumber }.prefix(3))
                    if clean != value { text.wrappedValue = clean }
                }
                .keyboardType(.numberPad)

                Text(unit)
                    .font(Afterglow.medium(12))
                    .foregroundStyle(Afterglow.muted)
            }
            .padding(14)
            .background(Afterglow.surface, in: .rect(cornerRadius: 8))
        }
    }

}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
