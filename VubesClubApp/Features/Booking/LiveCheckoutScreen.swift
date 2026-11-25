import SwiftUI

@MainActor
@Observable
private final class CheckoutState {
    private(set) var hold: BookingAPI.Hold?
    private(set) var busy = false
    private(set) var message: String?
    private(set) var redirect: URL?
    private let holdKey = UUID().uuidString

    func load(_ api: ClubAPI, eventID: String, version: String, existingID: String?) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            if let id = hold?.id ?? existingID {
                hold = try await api.get("booking-holds/\(id)", as: BookingAPI.Hold.self)
            } else {
                hold = try await api.send("POST", "booking-holds",
                    body: BookingAPI.CreateHold(eventId: eventID, programVersion: version),
                    as: BookingAPI.Hold.self, headers: ["Idempotency-Key": holdKey])
            }
            message = nil
        } catch {
            if !Task.isCancelled { message = error.localizedDescription }
        }
    }

    func pay(_ api: ClubAPI) async -> URL? {
        guard !busy, let hold, hold.expiresAt > .now,
              hold.state == .reserved || hold.state == .paymentPending else { return nil }

        busy = true
        defer { busy = false }
        do {
            let initiation = try await api.send("POST", "booking-holds/\(hold.id)/payments",
                body: BookingAPI.StartPayment(acceptedTermsVersion: hold.checkout.terms.version, termsAccepted: true),
                as: BookingAPI.Payment.self,
                headers: ["Idempotency-Key": "event-payment-\(hold.id)"])
            // The session is server-hosted. Returning from it never confirms the booking locally.
            if let action = initiation.nextAction, action.type == "redirect", action.url.scheme?.lowercased() == "https" {
                redirect = action.url
                message = nil
                return action.url
            }
            self.hold = try await api.get("booking-holds/\(hold.id)", as: BookingAPI.Hold.self)
            message = nil
        } catch {
            if !Task.isCancelled { message = error.localizedDescription }
        }
        return nil
    }

    func linkFailure() {
        message = "Ödeme sayfası açılamadı. Yeniden deneyebilirsiniz."
    }
}

struct LiveCheckoutScreen: View {
    let api: ClubAPI
    let eventID: String
    let programVersion: String
    let holdID: String?
    let onConfirmation: (String) -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var state = CheckoutState()
    @State private var acceptsTerms = false
    @State private var didNavigate = false
    @State private var returnedFromProvider = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackControl()
                ScreenTitle("Ödeme", size: 46)

                if let hold = state.hold {
                    summary(hold.checkout)
                    status(hold)
                } else if state.busy {
                    ProgressView("Kontenjan kontrol ediliyor…")
                }

                if let message = state.message {
                    Text(message)
                        .font(Afterglow.body(14))
                        .accessibilityLabel("İşlem sonucu. \(message)")
                    Button("Tekrar kontrol et") { Task { await refresh() } }
                        .disabled(state.busy)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Afterglow.inset)
        }
        .background(Afterglow.background.ignoresSafeArea())
        .task {
            await refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
        .task(id: pollKey) {
            guard scenePhase == .active,
                  state.hold?.state.awaitsPayment == true || returnedFromProvider else { return }
            // Foreground reconciliation only. Stop at a terminal state or when leaving the view.
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard scenePhase == .active else { return }
                await refresh()
                guard state.message == nil,
                      let hold = state.hold,
                      hold.state.awaitsPayment || returnedFromProvider && hold.state == .reserved else { return }
            }
        }
    }

    private var pollKey: String {
        "\(scenePhase == .active)-\(state.hold?.state.rawValue ?? "")-\(returnedFromProvider)"
    }

    private func summary(_ item: BookingAPI.Summary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = item.cover {
                BookingCover(url: image.url)
            }
            Overline(item.placeLabel)
            ScreenTitle(item.title, size: 32)
            MetadataLabel(title: BookingAPI.date(item.startsAt, in: item.timeZone), icon: "calendar")
            MetadataLabel(title: "\(item.participantCount) katılımcı · \(item.programDays) gün", icon: "person")
            if item.accommodationIncluded {
                MetadataLabel(title: "Konaklama dahil", icon: "bed.double")
            }
            Hairline()
            HStack {
                Text("Toplam")
                Spacer()
                Text(item.total.display).font(Afterglow.display(32))
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func status(_ hold: BookingAPI.Hold) -> some View {
        switch hold.state {
        case .reserved, .paymentPending:
            TimelineView(.periodic(from: .now, by: 1)) { tick in
                if tick.date < hold.expiresAt {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Ödeme için kalan süre")
                            Spacer()
                            Text(timerInterval: tick.date...hold.expiresAt, countsDown: true)
                                .monospacedDigit()
                                .fixedSize()
                        }
                        if let termsURL = api.resourceURL(hold.checkout.terms.url) {
                            Link("Katılım koşullarını oku", destination: termsURL)
                            Toggle("Katılım koşullarını kabul ediyorum", isOn: $acceptsTerms)
                            PrimaryAction(title: hold.state == .reserved ? "Ödemeye geç" : "Ödeme sayfasına dön", icon: "lock") {
                                Task { await pay() }
                            }
                            .disabled(!acceptsTerms || state.busy)
                        } else {
                            Text("Katılım koşullarına erişilemiyor.")
                        }
                    }
                } else {
                    Text(hold.state == .reserved ? "Kontenjan ayırma süresi doldu." : "Ödeme sonucu doğrulanıyor.")
                }
            }
            Button("Ödeme durumunu kontrol et") { Task { await refresh() } }
                .disabled(state.busy)
        case .confirmed:
            Text("Katılımınız onaylandı.")
        case .verificationPending:
            Text("Ödeme sonucunuz doğrulanıyor.")
        case .expired:
            Text("Kontenjan ayırma süresi doldu. Yeni bir deneme için etkinliğe dönebilirsiniz.")
        case .paymentFailed:
            Text("Ödeme tamamlanamadı. Etkinliğe dönerek yeniden deneyebilirsiniz.")
        case .refundPending:
            Text("Ödemeniz için tam iade başlatıldı.")
            Button("İade durumunu kontrol et") { Task { await refresh() } }
        case .refunded:
            Text("Ödemeniz iade edildi.")
        }
    }

    private func refresh() async {
        await state.load(api, eventID: eventID, version: programVersion, existingID: holdID)
        showConfirmationIfReady()
    }

    private func pay() async {
        if let url = await state.pay(api) {
            returnedFromProvider = true
            openURL(url) { accepted in
                if !accepted { state.linkFailure() }
            }
        } else {
            showConfirmationIfReady()
        }
    }

    private func showConfirmationIfReady() {
        guard !Task.isCancelled, !didNavigate, let hold = state.hold,
              hold.state == .confirmed, let bookingID = hold.bookingId else { return }
        didNavigate = true
        onConfirmation(bookingID)
    }
}

struct BookingCover: View {
    let url: URL

    var body: some View {
        ClubPhoto(name: url.absoluteString, radius: 12)
            .frame(height: 160)
    }
}
