import SwiftUI

/// Hesap ayarları: e-posta, telefon, boy, kilo, beden ve doğum tarihi.
/// E-posta ve telefon yalnızca e-postaya gelen kodla doğrulanarak değişir.
struct AccountSettingsScreen: View {
    static let sizes = ["XS", "S", "M", "L", "XL", "XXL"]

    @Environment(ClubSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var heightText = ""
    @State private var weightText = ""
    @State private var size = ""
    @State private var birthDate: Date?
    @State private var isSaving = false
    @State private var feedback: Feedback?
    @State private var contactChange: ContactKind?
    @FocusState private var focused: Bool

    private struct Feedback: Equatable {
        let text: String
        let isError: Bool
    }

    private var profile: MemberProfile? { session.profile }

    private var height: Int? { Int(heightText) }
    private var weight: Int? { Int(weightText) }

    private var heightIsValid: Bool { heightText.isEmpty || (100...250).contains(height ?? 0) }
    private var weightIsValid: Bool { weightText.isEmpty || (30...300).contains(weight ?? 0) }

    private var update: ProfileUpdate {
        var change = ProfileUpdate()
        if let height, height != profile?.heightCm { change.heightCm = height }
        if let weight, weight != profile?.weightKg { change.weightKg = weight }
        if !size.isEmpty, size != profile?.clothingSize { change.clothingSize = size }
        if profile?.birthDate == nil, let birthDate { change.birthDate = BirthDate.iso(birthDate) }
        return change
    }

    private var hasChanges: Bool {
        let change = update
        return change.heightCm != nil || change.weightKg != nil || change.clothingSize != nil || change.birthDate != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    contactSection
                    bodySection
                    birthSection

                    if let feedback {
                        Text(feedback.text)
                            .font(Afterglow.body(13))
                            .foregroundStyle(feedback.isError ? Afterglow.accent : Afterglow.green)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)

            PrimaryAction(title: isSaving ? "Saving…" : "Save changes", icon: "checkmark") {
                Task { await save() }
            }
            .disabled(!hasChanges || !heightIsValid || !weightIsValid || isSaving)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .padding(.top, 8)
        }
        .background(Afterglow.background.ignoresSafeArea())
        .presentationBackground(Afterglow.background)
        .onAppear(perform: load)
        .sheet(item: $contactChange) { kind in
            ContactChangeSheet(kind: kind) {
                feedback = Feedback(
                    text: L(kind == .email ? "Email updated." : "Phone number updated."), isError: false)
            }
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack {
            ScreenTitle("Account settings", size: 30)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Afterglow.ivory)
                    .frame(width: 36, height: 36)
                    .background(Afterglow.surface, in: Circle())
            }
            .accessibilityLabel(L("Close"))
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Overline("Contact details")

            contactRow("Email", value: profile?.email, empty: "Not added") { contactChange = .email }
            contactRow("Mobile number", value: profile?.phone.map(Self.formatPhone), empty: "Not added") {
                contactChange = .phone
            }

            Text(L("We email a code to confirm every change."))
                .font(Afterglow.body(12))
                .foregroundStyle(Afterglow.muted)
        }
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Overline("Body details")

            HStack(spacing: 12) {
                numberField("Height", unit: "cm", placeholder: "175", text: $heightText, valid: heightIsValid)
                numberField("Weight", unit: "kg", placeholder: "70", text: $weightText, valid: weightIsValid)
            }

            VStack(alignment: .leading, spacing: 6) {
                Overline("Clothing size")

                HStack(spacing: 8) {
                    ForEach(Self.sizes, id: \.self) { option in
                        let selected = size == option

                        Button { size = selected ? "" : option } label: {
                            Text(option)
                                .font(Afterglow.medium(13))
                                .foregroundStyle(selected ? Afterglow.background : Afterglow.text)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selected ? Afterglow.ivory : Afterglow.surface, in: .rect(cornerRadius: 8))
                                .overlay {
                                    if !selected { RoundedRectangle(cornerRadius: 8).strokeBorder(Afterglow.border) }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }

            if !heightIsValid || !weightIsValid {
                Text(L("Height must be 100–250 cm and weight 30–300 kg."))
                    .font(Afterglow.body(12))
                    .foregroundStyle(Afterglow.accent)
            }
        }
    }

    private var birthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            BirthDateField(label: "Birth date", date: $birthDate, locked: profile?.birthDate != nil)

            Text(L(profile?.birthDate != nil
                   ? "Your birth date can’t be changed. Contact support to correct it."
                   : "You can add your birth date once."))
                .font(Afterglow.body(12))
                .foregroundStyle(Afterglow.muted)
        }
    }

    private func contactRow(_ label: String, value: String?, empty: String, change: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Overline(label)
                Text(value ?? L(empty))
                    .font(Afterglow.body(15))
                    .foregroundStyle(value == nil ? Afterglow.muted.opacity(0.6) : Afterglow.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Button(L("Change"), action: change)
                .font(Afterglow.medium(13))
                .foregroundStyle(Afterglow.ivory)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(Afterglow.background, in: Capsule())
                .overlay { Capsule().strokeBorder(Afterglow.border) }
        }
        .padding(14)
        .background(Afterglow.surface, in: .rect(cornerRadius: 8))
    }

    private func numberField(
        _ label: String, unit: String, placeholder: String, text: Binding<String>, valid: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Overline(label)
            HStack(spacing: 8) {
                TextField(placeholder, text: text)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .onChange(of: text.wrappedValue) { _, value in
                        let clean = String(value.filter { $0.isASCII && $0.isNumber }.prefix(3))
                        if clean != value { text.wrappedValue = clean }
                    }
                Text(unit)
                    .font(Afterglow.medium(12))
                    .foregroundStyle(Afterglow.muted)
            }
            .padding(14)
            .background(Afterglow.surface, in: .rect(cornerRadius: 8))
            .overlay {
                if !valid { RoundedRectangle(cornerRadius: 8).strokeBorder(Afterglow.accent) }
            }
        }
    }

    // MARK: Actions

    private func load() {
        guard let profile else { return }
        heightText = profile.heightCm.map(String.init) ?? ""
        weightText = profile.weightKg.map(String.init) ?? ""
        size = profile.clothingSize ?? ""
        birthDate = BirthDate.date(fromISO: profile.birthDate)
    }

    private func save() async {
        focused = false
        feedback = nil
        isSaving = true
        defer { isSaving = false }

        do {
            try await session.updateProfile(update)
            load()
            feedback = Feedback(text: L("Saved."), isError: false)
        } catch {
            feedback = Feedback(text: L(ClubAPIError.message(for: error)), isError: true)
        }
    }

    /// `+905536277010` → `+90 553 627 70 10`
    static func formatPhone(_ phone: String) -> String {
        guard phone.hasPrefix("+90"), phone.count == 13 else { return phone }
        let digits = Array(phone.dropFirst(3))
        return "+90 \(String(digits[0..<3])) \(String(digits[3..<6])) \(String(digits[6..<8])) \(String(digits[8..<10]))"
    }
}

enum ContactKind: String, Identifiable {
    case email, phone

    var id: String { rawValue }
}

/// E-posta ya da telefon değişikliği: önce yeni değer, sonra e-postaya gelen kod.
struct ContactChangeSheet: View {
    let kind: ContactKind
    var onChanged: () -> Void

    @Environment(ClubSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var value = ""
    @State private var challenge: SMSChallenge?
    @State private var code = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private var title: String { kind == .email ? "Change email" : "Change phone number" }

    private var isValid: Bool {
        kind == .email
            ? value.trimmingCharacters(in: .whitespaces).contains("@") && value.contains(".")
            : value.count == 10
    }

    private var requestBody: ContactChangeBody {
        kind == .email
            ? ContactChangeBody(email: value.trimmingCharacters(in: .whitespaces))
            : ContactChangeBody(phone: ClubSession.phone(value))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScreenTitle(title, size: 32)

            if let challenge {
                codeStep(challenge)
            } else {
                valueStep
            }

            if let errorMessage {
                Text(L(errorMessage))
                    .font(Afterglow.body(13))
                    .foregroundStyle(Afterglow.accent)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .presentationDetents([.large])
        .presentationBackground(Afterglow.background)
        .onAppear { focused = true }
        .onChange(of: value) { _, newValue in
            if kind == .phone {
                let clean = SignUpScreen.turkishMobile(newValue)
                if clean != newValue { value = clean }
            }
            errorMessage = nil
        }
        .onChange(of: code) { _, newValue in
            let length = challenge?.codeLength ?? 6
            let clean = String(newValue.filter { $0.isASCII && $0.isNumber }.prefix(length))
            if clean != newValue { code = clean }
            errorMessage = nil
        }
    }

    // MARK: Steps

    private var valueStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L(kind == .email
                   ? "We’ll send a code to the new address to confirm it."
                   : "We’ll send a code to the email address on your account to confirm the change."))
                .font(Afterglow.body(14))
                .foregroundStyle(Afterglow.muted)

            VStack(alignment: .leading, spacing: 6) {
                Overline(kind == .email ? "New email address" : "New mobile number")

                if kind == .email {
                    TextField("you@example.com", text: $value)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .padding(14)
                        .background(Afterglow.surface, in: .rect(cornerRadius: 8))
                } else {
                    HStack(spacing: 12) {
                        Text("+90").font(Afterglow.medium(15))
                        Rectangle().fill(Afterglow.border).frame(width: 1, height: 26)
                        TextField("5XX XXX XX XX", text: $value)
                            .keyboardType(.numberPad)
                            .focused($focused)
                    }
                    .padding(14)
                    .background(Afterglow.surface, in: .rect(cornerRadius: 8))
                }
            }

            PrimaryAction(title: isBusy ? "Sending…" : "Send code", icon: "paperplane") {
                Task { await send() }
            }
            .disabled(!isValid || isBusy)
        }
    }

    private func codeStep(_ challenge: SMSChallenge) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(kind == .email
                 ? L("We sent a code to %@.", value.trimmingCharacters(in: .whitespaces))
                 : L("We sent a code to the email address on your account."))
                .font(Afterglow.body(14))
                .foregroundStyle(Afterglow.muted)

            CodeBoxes(code: $code, length: challenge.codeLength)

            HStack {
                TimelineView(.periodic(from: .now, by: 1)) { tick in
                    Button(L("Resend code")) { Task { await resend(challenge) } }
                        .disabled(isBusy || tick.date < challenge.resendAt)
                }

                Spacer()

                Button(L("Back")) {
                    self.challenge = nil
                    code = ""
                }
                .foregroundStyle(Afterglow.muted)
            }
            .font(Afterglow.medium(12.5))
            .buttonStyle(.plain)
            .frame(minHeight: 44)

            PrimaryAction(title: isBusy ? "Verifying…" : "Verify", icon: "checkmark") {
                Task { await verify(challenge) }
            }
            .disabled(code.count != challenge.codeLength || isBusy)
        }
    }

    // MARK: Actions

    private func send() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            challenge = try await session.requestContactChange(requestBody)
            code = ""
        } catch {
            errorMessage = ClubAPIError.message(for: error)
        }
    }

    private func resend(_ current: SMSChallenge) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            challenge = try await session.resendContactChange(current)
            code = ""
        } catch {
            errorMessage = ClubAPIError.message(for: error)
        }
    }

    private func verify(_ current: SMSChallenge) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            try await session.confirmContactChange(current, code: code)
            onChanged()
            dismiss()
        } catch {
            errorMessage = ClubAPIError.message(for: error)
        }
    }
}

/// Altı (ya da dört) kutulu kod girişi; görünmez bir alanla yazılır.
struct CodeBoxes: View {
    @Binding var code: String
    let length: Int

    @FocusState private var focused: Bool

    private var count: Int { min(max(length, 4), 8) }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
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
                .focused($focused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accessibilityLabel(L("Verification code"))
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear { focused = true }
    }
}
