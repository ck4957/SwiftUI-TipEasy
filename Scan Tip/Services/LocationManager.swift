import CoreLocation
import Foundation

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
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestPermissionOnFirstLaunch() {
        guard manager.authorizationStatus == .notDetermined else {
            refreshLocationIfAllowed()
            return
        }

        manager.requestWhenInUseAuthorization()
    }

    func refreshLocationIfAllowed() {
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

        Task {
            await reverseGeocode(location)
        }
    }

    private func reverseGeocode(_ location: CLLocation) async {
        guard !geocoder.isGeocoding else { return }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return }
            latestLocation = TipLocationSnapshot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: placemark.name,
                locality: placemark.locality,
                administrativeArea: placemark.administrativeArea,
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
