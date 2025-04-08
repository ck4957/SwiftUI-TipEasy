//
//  CalculationHistory.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 4/7/25.
//
import CoreLocation
import Foundation
import SwiftData

@Model
final class CalculationHistory {
    var billAmount: Double
    var tipPercentage: Double
    var tipAmount: Double
    var totalAmount: Double
    var timestamp: Date
    var photo: Data?
    @Attribute(originalName: "category") private var categoryRawValue: String

    var locationCoordinate: LocationCoordinate?
    // Computed property to maintain the same interface
    var location: CLLocationCoordinate2D? {
        get { locationCoordinate?.coordinate }
        set {
            if let newValue = newValue {
                locationCoordinate = LocationCoordinate(coordinate: newValue)
            } else {
                locationCoordinate = nil
            }
        }
    }

    var category: ExpenseCategory {
        get {
            // Explicit conversion to ExpenseCategory with a fallback value
            if let cat = ExpenseCategory(rawValue: categoryRawValue) {
                return cat
            } else {
                return .restaurant
            }
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    init(billAmount: Double, tipPercentage: Double, tipAmount: Double,
         totalAmount: Double, timestamp: Date, location: CLLocationCoordinate2D? = nil,
         photo: Data? = nil, category: ExpenseCategory = .restaurant)
    {
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.timestamp = timestamp
        self.photo = photo
        self.categoryRawValue = category.rawValue

         if let location = location {
            self.locationCoordinate = LocationCoordinate(coordinate: location)
        } else {
            self.locationCoordinate = nil
        }
    }
}

extension CalculationHistory {
    static var sampleTransactions: [CalculationHistory] {
        let coordinates: [String: CLLocationCoordinate2D] = [
            "San Francisco, CA": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            "New York, NY": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            "Seattle, WA": CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
            "Austin, TX": CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431)
        ]
        let locations = Array(coordinates.values)
        let calendar = Calendar.current
        let today = Date()

        return (0 ..< 10).map { i in
            let daysAgo = i * 3 // Spread over last 30 days
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

            let transaction = CalculationHistory(
                billAmount: Double.random(in: 20...200).rounded(to: 2),
                tipPercentage: [0.15, 0.18, 0.20].randomElement()!, tipAmount: Double.random(in: 5...40).rounded(to: 2),
                totalAmount: Double.random(in: 25...240).rounded(to: 2), timestamp: Date(),
                location: locations.randomElement()!,
                photo: nil
            )
            transaction.timestamp = date
            return transaction
        }
    }
}

extension CLLocationCoordinate2D: Codable {
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lat = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: lat, longitude: lon)
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
