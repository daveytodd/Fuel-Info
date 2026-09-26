import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        EntryView()
            .preferredColorScheme(.dark)
    }
}

private struct EntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FuelEntry.date, order: .reverse) private var entries: [FuelEntry]

    @State private var rego = ""
    @State private var date = Date()
    @State private var fuelType = "E10"
    @State private var pricePerLitre = ""
    @State private var litres = ""
    @State private var odometer = ""
    @State private var range = ""
    @State private var efficiency = ""
    @State private var averageSpeed = ""
    @State private var saved = false

    private let fuelTypes = ["E10", "98", "95", "Diesel"]
    private var price: Double { Double(pricePerLitre.replacingOccurrences(of: "$", with: "")) ?? 0 }
    private var volume: Double { Double(litres.replacingOccurrences(of: "L", with: "")) ?? 0 }
    private var totalCost: Double { price * volume }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Car Rego") {
                        TextField("Registration Number", text: $rego)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    LabeledContent("Fuel Type") {
                        Picker("Fuel Type", selection: $fuelType) {
                            ForEach(fuelTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    decimalField("Price/Litre", placeholder: "$#.##", text: $pricePerLitre)
                    decimalField("Litres", placeholder: "##.##L", text: $litres)

                    LabeledContent("Total Cost") {
                        Text(String(format: "$%.2f", totalCost))
                            .monospacedDigit()
                            .foregroundStyle(Theme.orange)
                    }

                    numberField("Odometer", placeholder: "#####kms", text: $odometer)
                    decimalField("Range", placeholder: "Distance Until Empty", text: $range)
                    decimalField("Avg L/100kms", placeholder: "Average L/100kms", text: $efficiency)
                    decimalField("Avg Speed", placeholder: "Average Speed km/h", text: $averageSpeed)

                    Button(action: saveEntry) {
                        Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.body)
                            .foregroundStyle(Theme.orange)
                        Text(saved ? "Saved" : "Take a Screenshot to save the Data")
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Theme.card)

                    Text("Tap the (+) to go full screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.black)
                }

                Section {
                    VStack(spacing: 5) {
                        Text("Daveytodd Inc.")
                            .font(.headline)
                            .foregroundStyle(Theme.orange)
                        Text("Created by David Todd")
                        Text("Credit to James Robertson")
                        Text("Copyright © 2022 Daveytodd Inc.")
                        Text("All rights reserved.")
                        Text("A D&R Square Hamburger Emporian Company, est. 2008")
                        Text("V 2.2.2 (3)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .listStyle(.insetGrouped)
            .navigationTitle("Fuel Info")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(Theme.orange)
        }
    }

    private func decimalField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        LabeledContent(title) {
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func numberField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        LabeledContent(title) {
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func saveEntry() {
        let parsedOdometer = Double(odometer.replacingOccurrences(of: "kms", with: "")) ?? 0
        let parsedRange = Double(range.replacingOccurrences(of: "kms", with: "")) ?? 0
        let parsedEfficiency = Double(efficiency) ?? 0
        let parsedSpeed = Double(averageSpeed) ?? 0
        let entry = FuelEntry(
            rego: rego,
            date: date,
            fuelType: fuelType,
            pricePerLitre: price,
            litres: volume,
            odometer: parsedOdometer,
            rangeKm: parsedRange,
            averageSpeed: parsedSpeed,
            calculatedLPer100Km: parsedEfficiency > 0 ? parsedEfficiency : nil
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
        } catch {
            saved = false
        }
    }
}
