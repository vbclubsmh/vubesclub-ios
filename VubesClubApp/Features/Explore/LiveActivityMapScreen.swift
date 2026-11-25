import CoreLocation
import MapKit
import SwiftUI

private struct FieldPoint: Codable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

private struct FieldSharing: Decodable {
    let enabled: Bool
    let sharingId: UUID?
}

private struct FieldMap: Decodable {
    struct Participant: Decodable, Identifiable {
        let eventAliasId: UUID
        let displayName: String
        let avatar: CommunityMedia?
        let position: FieldPoint

        var id: UUID { eventAliasId }
    }

    let route: [FieldPoint]
    let participants: [Participant]
    let mySharing: FieldSharing
}

private struct FieldEvent: Decodable {
    struct Card: Decodable {
        struct Sport: Decodable { let label: String }
        let title: String
        let primarySport: Sport
        let cover: CommunityMedia?
        let position: FieldPoint?
    }

    let event: Card
}

struct LiveActivityMapScreen: View {
    let api: ClubAPI
    let eventID: String
    @Environment(\.scenePhase) private var scenePhase

    @State private var field: FieldMap?
    @State private var event: FieldEvent.Card?
    @State private var sharing: FieldSharing?
    @State private var selectedID: UUID?
    @State private var camera: MapCameraPosition = .automatic
    @State private var changingSharing = false
    @State private var confirmSharing = false
    @State private var readError: String?
    @State private var sharingError: String?

    var body: some View {
        ZStack {
            Map(position: $camera) {
                if let field {
                    if !field.route.isEmpty {
                        MapPolyline(coordinates: field.route.map(\.coordinate))
                            .stroke(Afterglow.accent, lineWidth: 4)
                    } else if let position = event?.position {
                        Marker(event?.title ?? "", coordinate: position.coordinate)
                    }
                    ForEach(field.participants) { person in
                        Annotation(person.displayName, coordinate: person.position.coordinate) {
                            Button { selectedID = person.id } label: {
                                Avatar(image: person.avatar?.url ?? "", size: person.id == selectedID ? 38 : 30,
                                       selected: person.id == selectedID)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(person.displayName)
                        }
                        .annotationTitles(person.id == selectedID ? .visible : .hidden)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                HStack { BackControl(); ScreenTitle("Activity map", size: 30) }
                    .padding(7)
                    .background(Afterglow.background.opacity(0.9), in: .capsule)
                if let field {
                    Pill(title: "\(field.participants.count) sharing", icon: "person.2")
                }
                Spacer()
                VStack(alignment: .leading, spacing: 9) {
                    if let event {
                        HStack {
                            ClubPhoto(name: event.cover?.url ?? "", radius: 8)
                                .frame(width: 66, height: 60)
                            VStack(alignment: .leading) {
                                Overline(event.primarySport.label)
                                ScreenTitle(event.title, size: 22)
                            }
                        }
                    }
                    if let readError {
                        Text(readError)
                        Button("Try again") { Task { await refresh() } }
                    } else if field == nil {
                        ProgressView()
                    }
                    if let sharingError { Text(sharingError).font(Afterglow.body(12)) }
                    if let sharing {
                        Button {
                            if sharing.enabled { Task { await setSharing(false) } } else { confirmSharing = true }
                        } label: {
                            Label(sharing.enabled ? "Stop sharing my location" : "Share my location",
                                  systemImage: sharing.enabled ? "location.slash" : "location")
                                .frame(minHeight: 44)
                        }
                        .disabled(changingSharing)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Afterglow.background, in: .rect(cornerRadius: 16))
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 12)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            repeat {
                await refresh()
                do { try await Task.sleep(for: .seconds(15)) } catch { return }
            } while !Task.isCancelled
        }
        .task(id: scenePhase == .active ? sharing?.sharingId : nil) {
            guard scenePhase == .active, let id = sharing?.sharingId else { return }
            await publishLocation(id)
        }
        .alert("Share your location?", isPresented: $confirmSharing) {
            Button("Cancel", role: .cancel) {}
            Button("Share") { Task { await setSharing(true) } }
        } message: {
            Text("Eligible participants can see your recent position while this map is open. You can stop sharing at any time.")
        }
    }

    private var resource: String { "events/\(eventID)" }

    private func refresh() async {
        do {
            let snapshot = try await api.get(resource + "/activity-map", as: FieldMap.self)
            try Task.checkCancellation()
            field = snapshot
            // Ignore a read begun before a consent change. Consent writes update their own state.
            if !changingSharing, sharing == nil || sharing?.sharingId == snapshot.mySharing.sharingId {
                sharing = snapshot.mySharing
            }
            if event == nil {
                event = try await api.get(resource, as: FieldEvent.self).event
            }
            readError = nil
        } catch {
            if !Task.isCancelled {
                field = nil
                sharing = nil
                readError = error.localizedDescription
            }
        }
    }

    private func setSharing(_ enabled: Bool) async {
        guard !changingSharing else { return }
        changingSharing = true
        defer { changingSharing = false }
        sharingError = nil
        do {
            sharing = try await api.send("PUT", resource + "/me/location-sharing",
                                         body: ["enabled": enabled], as: FieldSharing.self)
            await refresh()
        } catch {
            if !Task.isCancelled { sharingError = error.localizedDescription }
        }
    }

    private func publishLocation(_ id: UUID) async {
        struct Measurement: Encodable {
            let sharingId: UUID
            let position: FieldPoint
            let recordedAt: Date
            let sequence: Int
        }

        let source = FieldLocationSource()
        defer { source.stop() }
        var lastSent = Date.distantPast
        do {
            for try await location in source.updates() {
                try Task.checkCancellation()
                let time = location.timestamp
                guard location.horizontalAccuracy >= 0, abs(time.timeIntervalSinceNow) < 90,
                      time.timeIntervalSince(lastSent) >= 3 else { continue }
                let point = FieldPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let update = Measurement(sharingId: id, position: point, recordedAt: time,
                                         sequence: Int(time.timeIntervalSinceReferenceDate))
                try await api.sendEmpty("PUT", resource + "/me/location", body: update)
                lastSent = time
            }
        } catch {
            if !Task.isCancelled, sharing?.sharingId == id {
                let message = error.localizedDescription
                await setSharing(false)
                sharingError = message
            }
        }
    }
}

@MainActor
private final class FieldLocationSource: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: AsyncThrowingStream<CLLocation, Error>.Continuation?

    func updates() -> AsyncThrowingStream<CLLocation, Error> {
        let pair = AsyncThrowingStream<CLLocation, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation = pair.continuation
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 5
        locationManagerDidChangeAuthorization(manager)
        return pair.stream
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.startUpdatingLocation()
        default: continuation?.finish(throwing: CLError(.denied))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newest = locations.last { continuation?.yield(newest) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code != .locationUnknown { continuation?.finish(throwing: error) }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.delegate = nil
        continuation?.finish()
        continuation = nil
    }
}
