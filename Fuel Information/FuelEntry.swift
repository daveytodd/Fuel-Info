import Foundation
import SwiftData

@Model
final class FuelEntry {
    var rego: String
    var date: Date
    var fuelType: String
    var pricePerLitre: Double
    var litres: Double
    var totalCost: Double
    var odometer: Double
    var rangeKm: Double
    var averageSpeed: Double
    var calculatedLPer100Km: Double?

    init(rego: String, date: Date = .now, fuelType: String, pricePerLitre: Double, litres: Double, odometer: Double, rangeKm: Double = 0, averageSpeed: Double = 0, calculatedLPer100Km: Double? = nil) {
        self.rego = rego.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.date = date
        self.fuelType = fuelType
        self.pricePerLitre = pricePerLitre
        self.litres = litres
        self.totalCost = pricePerLitre * litres
        self.odometer = odometer
        self.rangeKm = rangeKm
        self.averageSpeed = averageSpeed
        self.calculatedLPer100Km = calculatedLPer100Km
    }
}
