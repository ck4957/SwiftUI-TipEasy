import CoreLocation
import Foundation
import MapKit

struct TipLocationSnapshot: Equatable {
    let latitude: Double
    let longitude: Double
    let name: String?
    let locality: String?
    let administrativeArea: String?
    let capturedAt: Date

    var displayName: String {
        if let name, !name.isEmpty {
            return name
        }

        let components = [locality, administrativeArea]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
        return components.isEmpty ? "Saved location" : components.joined(separator: ", ")
    }
}

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var latestLocation: TipLocationSnapshot?

    private let manager = CLLocationManager()
    private var reverseGeocodingTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestPermissionOnFirstLaunch() {
        guard !ScreenshotAutomation.isEnabled else { return }

        guard manager.authorizationStatus == .notDetermined else {
            refreshLocationIfAllowed()
            return
        }

        manager.requestWhenInUseAuthorization()
    }

    func refreshLocationIfAllowed() {
        guard !ScreenshotAutomation.isEnabled else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    private func updateSnapshot(from location: CLLocation) {
        latestLocation = TipLocationSnapshot(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: latestLocation?.name,
            locality: latestLocation?.locality,
            administrativeArea: latestLocation?.administrativeArea,
            capturedAt: .now
        )

        reverseGeocodingTask?.cancel()
        reverseGeocodingTask = Task {
            await reverseGeocode(location)
        }
    }

    private func reverseGeocode(_ location: CLLocation) async {
        guard let request = MKReverseGeocodingRequest(location: location) else { return }

        do {
            let mapItems = try await request.mapItems
            guard !Task.isCancelled, let mapItem = mapItems.first else { return }
            let address = mapItem.address
            let addressRepresentations = mapItem.addressRepresentations
            latestLocation = TipLocationSnapshot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: mapItem.name ?? address?.shortAddress ?? addressRepresentations?.fullAddress(includingRegion: false, singleLine: true),
                locality: addressRepresentations?.cityName,
                administrativeArea: addressRepresentations?.cityWithContext,
                capturedAt: .now
            )
        } catch {
            latestLocation = TipLocationSnapshot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: nil,
                locality: nil,
                administrativeArea: nil,
                capturedAt: .now
            )
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            refreshLocationIfAllowed()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            updateSnapshot(from: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
