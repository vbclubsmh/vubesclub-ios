import SwiftUI

struct CheckoutScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(EventCatalog.self) private var catalog
    @Environment(BookingCenter.self) private var bookings

    let event: ClubEvent
    let onConfirmation: () -> Void

    @State private var acceptsTerms = false
    @State private var confirmed = false
    @State private var isPaying = false
    @State private var failure: String?

    // Kart alanları yalnızca arayüzdür: ödeme sağlayıcısı bağlanana kadar doğrulanmaz, saklanmaz, gönderilmez.
    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""

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
                    summaryRow(days == 1 ? "Full day program" : L("Full %d-day program", days), icon: "calendar")

                    if event.accommodation != nil {
                        summaryRow("Accommodation included", icon: "bed.double")
                    }
                }
                .padding(.top, 7)

                HStack {
                    Text(L("Total")).font(Afterglow.medium(15))
                    Spacer()

                    Text(event.priceLabel)
                        .font(Afterglow.display(40, relativeTo: .title))
                        .foregroundStyle(Afterglow.ivory)
                }

                paymentSection

                Button {
                    acceptsTerms.toggle()
                } label: {
                    Label(L("I agree to the participation terms."),
                          systemImage: acceptsTerms ? "checkmark.square.fill" : "square")
                        .font(Afterglow.body(12))
                        .foregroundStyle(Afterglow.muted)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(acceptsTerms ? .isSelected : [])

                if let failure {
                    Text(failure)
                        .font(Afterglow.body(12.5))
                        .foregroundStyle(Afterglow.accent)
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryAction(title: isPaying ? "Processing…" : "Pay now", icon: "lock") {
                Task { await pay() }
            }
            .disabled(!acceptsTerms || confirmed || isPaying)
            .sensoryFeedback(.success, trigger: confirmed)
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 5)
            .background(Afterglow.background)
        }
    }

    private func pay() async {
        guard !confirmed, !isPaying else { return }

        isPaying = true
        failure = nil
        defer { isPaying = false }

        do {
            _ = try await bookings.join(event, catalog: catalog, session: session)
            confirmed = true
            onConfirmation()
        } catch let error as ClubAPIError {
            if case .server(_, "ALREADY_BOOKED", _) = error {
                await bookings.load(session: session)
                confirmed = true
                onConfirmation()
            } else {
                failure = L(ClubAPIError.message(for: error))
            }
        } catch {
            failure = L("We couldn’t complete your booking. Try again.")
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScreenTitle("Payment", size: 29)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "creditcard")
                    Spacer()
                    Image(systemName: "wave.3.right")
                }
                .font(.system(size: 20))
                .foregroundStyle(Afterglow.ivory)

                Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                    .font(Afterglow.medium(19))
                    .tracking(1.5)

                HStack {
                    Text(cardHolder.isEmpty ? L("Name on card") : cardHolder.uppercased(with: Locale(identifier: "tr_TR")))
                        .lineLimit(1)
                    Spacer()
                    Text(cardExpiry.isEmpty ? "AA/YY" : cardExpiry)
                }
                .font(Afterglow.body(12))
                .foregroundStyle(Afterglow.muted)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Afterglow.surface, in: .rect(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Afterglow.border) }
            .accessibilityHidden(true)

            cardField(L("Card number"), text: $cardNumber, keyboard: .numberPad, contentType: .creditCardNumber)
                .onChange(of: cardNumber) { _, value in
                    let digits = value.filter(\.isNumber).prefix(16)
                    let grouped = stride(from: 0, to: digits.count, by: 4).map { start -> String in
                        let from = digits.index(digits.startIndex, offsetBy: start)
                        let to = digits.index(from, offsetBy: min(4, digits.count - start))
                        return String(digits[from..<to])
                    }.joined(separator: " ")
                    if grouped != value { cardNumber = grouped }
                }

            cardField(L("Name on card"), text: $cardHolder, keyboard: .default, contentType: .name)

            HStack(spacing: 12) {
                cardField(L("Expiry"), text: $cardExpiry, keyboard: .numberPad, contentType: nil)
                    .onChange(of: cardExpiry) { _, value in
                        let digits = value.filter(\.isNumber).prefix(4)
                        let text = digits.count > 2 ? digits.prefix(2) + "/" + digits.dropFirst(2) : String(digits)
                        if text != value { cardExpiry = text }
                    }
                cardField("CVV", text: $cardCVV, keyboard: .numberPad, contentType: nil)
                    .onChange(of: cardCVV) { _, value in
                        let digits = String(value.filter(\.isNumber).prefix(4))
                        if digits != value { cardCVV = digits }
                    }
            }

            Text(L("Payments are coming soon. For now no card details are collected and nothing is charged."))
                .font(Afterglow.body(11.5))
                .foregroundStyle(Afterglow.muted)
        }
    }

    private func cardField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType,
                           contentType: UITextContentType?) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .font(Afterglow.body(15))
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Afterglow.surface, in: .rect(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Afterglow.border.opacity(0.8)) }
    }

    private var eventCard: some View {
        HStack(spacing: 13) {
            ClubPhoto(name: event.image, radius: 8)
                .frame(width: 112, height: 102)

            VStack(alignment: .leading, spacing: 9) {
                Overline("\(L(event.displayDate))  /  \(L(event.location))")
                Text(L(event.title))
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
