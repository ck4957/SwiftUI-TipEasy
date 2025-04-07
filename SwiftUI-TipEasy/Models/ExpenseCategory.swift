//
//  ExpenseCategory.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 4/7/25.
//
import Foundation

enum ExpenseCategory: String, Codable, CaseIterable {
    case restaurant = "Restaurant"
    case bar = "Bar"
    case cafe = "Café"
    case fastFood = "Fast Food"
    case delivery = "Delivery"
    case hotel = "Hotel"
    case personalCare = "Personal Care"
    case transportation = "Transportation"
    case travel = "Travel & Tourism"
    case service = "Service & Maintenance"
    case other = "Other"

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .bar: return "wineglass"
        case .cafe: return "cup.and.saucer"
        case .fastFood: return "hamburger"
        case .delivery: return "box.truck"
        case .hotel: return "bed.double"
        case .personalCare: return "scissors"
        case .transportation: return "car"
        case .travel: return "airplane"
        case .service: return "wrench.and.screwdriver"
        case .other: return "square.grid.2x2"
        }
    }
}
