import CoreImage.CIFilterBuiltins
import SwiftUI

struct RemoteConfirmationScreen: View {
    let api: ClubAPI
    let bookingId: String
    let onMyEvents: () -> Void

    var body: some View {
        ScrollView {
            LivePassContent(api: api, bookingID: bookingId, confirmation: true)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(.container, edges: .top)
        .background(Afterglow.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryAction(title: "Go to My Events", action: onMyEvents)
                .padding(.horizontal, Afterglow.inset)
                .padding(.bottom, 5)
                .background(Afterglow.background)
        }
        .navigationBarBackButtonHidden()
    }
}

struct LivePassContent: View {
    let api: ClubAPI
    let bookingID: String
    var confirmation = false

    @Environment(\.scenePhase) private var scenePhase
    @State private var pass: BookingAPI.Pass?
    @State private var cover: URL?
    @State private var failure: String?
    @State private var retry = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if confirmation, let pass {
                ClubPhoto(name: cover?.absoluteString ?? "")
                    .frame(height: 310)
                    .overlay(alignment: .bottom) { Afterglow.shade().frame(height: 170) }
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .padding(.horizontal, Afterglow.inset)
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel(pass.title)
            }

            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(confirmation ? "You’re in." : "Event pass", size: confirmation ? 54 : 35)
                if let pass {
                    if confirmation {
                        Text("Your booking is confirmed.")
                            .foregroundStyle(Afterglow.muted)
                    }
                    TimelineView(.periodic(from: .now, by: 1)) { tick in
                        if tick.date < pass.validUntil {
                            HStack(spacing: 16) {
                                TicketCode(payload: pass.qrPayload)
                                VStack(alignment: .leading, spacing: 8) {
                                    Overline("Event pass")
                                    Text(pass.title).font(Afterglow.medium(16))
                                    Text(BookingAPI.date(pass.startsAt, in: pass.timeZone))
                                    Text(pass.meetingPoint.label)
                                }
                                .font(Afterglow.body(13))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Afterglow.surface, in: .rect(cornerRadius: 18))
                        } else {
                            Text("Katılım kartının süresi doldu.")
                        }
                    }
                } else if let failure {
                    Text(failure)
                    Button("Yeniden dene") { retry += 1 }
                } else {
                    ProgressView("Katılım kartı yükleniyor…")
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: "\(bookingID)-\(retry)-\(scenePhase == .active)") {
            pass = nil
            cover = nil
            failure = nil
            guard scenePhase == .active else { return }
            do {
                let ticket = try await api.get("me/bookings/\(bookingID)/pass", as: BookingAPI.Pass.self)
                try Task.checkCancellation()
                pass = ticket
                if confirmation {
                    let detail = try? await api.get("events/\(ticket.eventId)?bookingId=\(bookingID)", as: BookingAPI.Detail.self)
                    if !Task.isCancelled { cover = detail?.event.cover?.url }
                }
            } catch {
                if !Task.isCancelled { failure = error.localizedDescription }
            }
        }
    }
}

private struct TicketCode: View {
    let payload: String
    @State private var image: CGImage?

    private static let context = CIContext()

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(12)
                    .background(.white)
            } else {
                Text("QR kodu oluşturulamadı.").font(.caption)
            }
        }
        .frame(width: 112, height: 112)
        .accessibilityLabel("Etkinlik giriş QR kodu")
        .onChange(of: payload, initial: true) { _, value in
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(value.utf8)
            filter.correctionLevel = "M"
            image = filter.outputImage.flatMap { Self.context.createCGImage($0, from: $0.extent) }
        }
    }
}
