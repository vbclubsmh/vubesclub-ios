import AVFoundation
import SwiftUI

/// Stand ekranı: üyenin QR kodunu okutur, sunucuda üyeyle eşleştirir ve girişi kaydeder.
struct FieldScannerScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var result: APICheckInResult?
    @State private var failure: String?
    @State private var isChecking = false
    @State private var scanning = true
    @State private var denied = false

    var body: some View {
        ZStack {
            Afterglow.background.ignoresSafeArea()

            if denied {
                ContentUnavailableView(
                    L("Camera access is needed to scan passes."), systemImage: "camera",
                    description: Text(L("Allow camera access in Settings.")))
            } else {
                ScannerView(active: scanning && !isChecking) { code in
                    Task { await check(code) }
                } onDenied: { denied = true }
                .ignoresSafeArea()
                .overlay { frame }
            }

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Afterglow.ivory)
                            .frame(width: 40, height: 40)
                            .background(Afterglow.surface.opacity(0.9), in: .circle)
                    }
                    .accessibilityLabel(L("Close"))
                    Spacer()
                }
                .padding(16)

                Spacer()

                if result == nil {
                    VStack(spacing: 8) {
                        if isChecking { ProgressView().tint(Afterglow.ivory) }
                        Text(failure ?? L("Point the camera at the member’s QR code."))
                            .font(Afterglow.medium(14))
                            .foregroundStyle(failure == nil ? Afterglow.ivory : Afterglow.accent)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Afterglow.background.opacity(0.85), in: .rect(cornerRadius: 14))
                    .padding(.horizontal, Afterglow.inset)
                    .padding(.bottom, 30)
                }
            }

            if let result { resultCard(result) }
        }
        .sensoryFeedback(.success, trigger: result?.bookingId)
    }

    private var frame: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(Afterglow.ivory.opacity(0.85), lineWidth: 2)
            .frame(width: 240, height: 240)
            .accessibilityHidden(true)
    }

    private func resultCard(_ result: APICheckInResult) -> some View {
        let fresh = result.outcome == "checkedIn"

        return VStack(spacing: 18) {
            Group {
                if let avatar = result.memberAvatar?.url {
                    ClubMediaImage(source: avatar)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } else {
                    ProfileAvatar(url: nil, name: result.memberName, size: 150)
                }
            }

            VStack(spacing: 6) {
                Label(L(fresh ? "Checked in" : "Already checked in"),
                      systemImage: fresh ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(Afterglow.medium(14))
                    .foregroundStyle(fresh ? Afterglow.green : Afterglow.accent)

                ScreenTitle(result.memberName, size: 34)
                    .multilineTextAlignment(.center)

                Text(result.eventTitle)
                    .font(Afterglow.body(13))
                    .foregroundStyle(Afterglow.muted)
            }

            PrimaryAction(title: "Scan next", icon: "qrcode.viewfinder") {
                self.result = nil
                failure = nil
                scanning = true
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Afterglow.background.ignoresSafeArea())
    }

    private func check(_ code: String) async {
        guard !isChecking, result == nil else { return }

        isChecking = true
        failure = nil
        defer { isChecking = false }

        do {
            result = try await session.api.send(
                "POST", "field/check-ins", body: APICheckInRequest(payload: code), as: APICheckInResult.self)
            scanning = false
        } catch let error as ClubAPIError {
            if case .server(let status, _, let message) = error, status == 404 || status == 422 {
                failure = L("This code isn’t valid for this event.")
            } else if case .server(_, _, let message) = error {
                failure = message
            } else {
                failure = L(ClubAPIError.message(for: error))
            }
            try? await Task.sleep(for: .seconds(2))
        } catch {
            failure = L(ClubAPIError.message(for: error))
            try? await Task.sleep(for: .seconds(2))
        }
    }
}

private struct ScannerView: UIViewRepresentable {
    let active: Bool
    let onCode: (String) -> Void
    let onDenied: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let coordinator = context.coordinator

        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { onDenied(); return }

            let session = AVCaptureSession()
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { onDenied(); return }

            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }

            session.addOutput(output)
            output.setMetadataObjectsDelegate(coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
            view.previewLayer.session = session
            view.previewLayer.videoGravity = .resizeAspectFill
            coordinator.session = session
            Task.detached { session.startRunning() }
        }
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        context.coordinator.active = active
    }

    static func dismantleUIView(_ view: PreviewView, coordinator: Coordinator) {
        let session = coordinator.session
        Task.detached { session?.stopRunning() }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var session: AVCaptureSession?
        var active = true
        private let onCode: (String) -> Void
        private var lastCode: String?
        private var lastTime = Date.distantPast

        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard active,
                  let code = (objects.first as? AVMetadataMachineReadableCodeObject)?.stringValue else { return }
            // Aynı kod arka arkaya okunursa 3 saniye beklenir.
            if code == lastCode, Date().timeIntervalSince(lastTime) < 3 { return }

            lastCode = code
            lastTime = Date()
            onCode(code)
        }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
