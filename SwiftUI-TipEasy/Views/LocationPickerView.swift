//
//  LocationPickerView.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 4/7/25.
//

import MapKit
import SwiftData
import SwiftUI

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var location: CLLocationCoordinate2D?

    @State private var locationManager = LocationManager()
    @State private var region: MKCoordinateRegion
    @State private var searchText = ""
    @State private var places: [MKMapItem] = []
    @State private var position: MapCameraPosition
    // Add this computed property to convert region to camera position
//    private var cameraPosition: MapCameraPosition {
//        .region(region)
//    }
//
//    // Add this binding to properly update the camera position
//    private var cameraBinding: Binding<MapCameraPosition> {
//        Binding(
//            get: { .region(region) },
//            set: { _ in
//                // We don't need to extract the region here
//                // Map will automatically update the camera position
//                // and we handle selection via onTapGesture
//            }
//        )
//    }

    init(location: Binding<CLLocationCoordinate2D?>) {
        _location = location
        let initialLocation = location.wrappedValue ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default to San Francisco
        let initialRegion = MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _region = State(initialValue: initialRegion)
        _position = State(initialValue: .region(initialRegion))
    }

    var body: some View {
        NavigationStack {
            VStack {
                MapReader { proxy in
                    Map(position: $position) {
                        if let location = location {
                            Marker("Selected Location", coordinate: location)
                        }
                        ForEach(places, id: \.self) { place in
                            Marker(place.name ?? "Place", coordinate: place.placemark.coordinate)
                                .tint(.red)
                        }
                    }
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                    .onTapGesture { screenPoint in
                        if let coordinate = proxy.convert(screenPoint, from: .local) {
                            selectLocation(coordinate)
                        }
                    }
                }
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                    locationManager.authorizationStatus == .authorizedAlways
                {
                    Button("Use Current Location") {
                        if let currentLocation = locationManager.lastLocation?.coordinate {
                            selectLocation(currentLocation)
                        }
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
            }
            .searchable(text: $searchText, prompt: "Search nearby places")
            .onChange(of: searchText) { _, newValue in
                searchNearbyPlaces(query: newValue)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                locationManager.startUpdatingLocation()
            }
        }
    }

    private func selectLocation(_ coordinate: CLLocationCoordinate2D) {
        location = coordinate
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    private func searchNearbyPlaces(query: String) {
        guard !query.isEmpty else {
            places = []
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        MKLocalSearch(request: request).start { response, _ in
            guard let response = response else { return }
            places = response.mapItems
        }
    }
}

// // Extension to convert MKCoordinateRegion to MapCamera (needed for SwiftUI Map)
// extension MKCoordinateRegion {
//     var toMapCamera: MapCameraPosition {
//         .region(self)
//     }
// }

#Preview {
    LocationPickerView(location: .constant(nil))
}
