import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            EntryView().tabItem { Label("Fill Up", systemImage: "plus.circle.fill") }
            HistoryView().tabItem { Label("History", systemImage: "list.bullet.rectangle") }
            AnalyticsView().tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
        }.tint(Theme.green).background(Color.black).preferredColorScheme(.dark)
    }
}

struct EntryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FuelEntry.date, order: .reverse) private var entries: [FuelEntry]
    @State private var rego = ""
    @State private var date = Date()
    @State private var fuelType = "95"
    @State private var price = ""
    @State private var litres = ""
    @State private var odometer = ""
    @State private var range = ""
    @State private var speed = ""
    @State private var saved = false
    private let fuels = ["91", "95", "98", "Diesel", "E10"]
    private var p: Double { Double(price) ?? 0 }
    private var l: Double { Double(litres) ?? 0 }
    private var cost: Double { p * l }
    private var efficiency: Double? {
        guard let odo = Double(odometer), let prior = entries.first(where: { $0.rego == rego.trimmingCharacters(in: .whitespaces).uppercased() }), odo > prior.odometer, l > 0 else { return nil }
        return l / (odo - prior.odometer) * 100
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle & fill-up") {
                    TextField("Car registration", text: $rego).textInputAutocapitalization(.characters).autocorrectionDisabled()
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Fuel type", selection: $fuelType) { ForEach(fuels, id: \.self) { Text($0).tag($0) } }
                }
                Section("Fuel details") {
                    decimalField("Price / litre ($)", text: $price)
                    decimalField("Litres", text: $litres)
                    HStack { Text("Total cost"); Spacer(); Text(cost, format: .currency(code: Locale.current.currency?.identifier ?? "AUD")).foregroundStyle(Theme.orange).fontWeight(.bold) }
                }
                Section("Trip details") {
                    decimalField("Odometer (km)", text: $odometer)
                    decimalField("Range (km)", text: $range)
                    decimalField("Avg speed (km/h)", text: $speed)
                    HStack { Text("Avg. consumption"); Spacer(); Text(efficiency.map { String(format: "%.1f L/100 km", $0) } ?? "Available after next fill").foregroundStyle(Theme.green) }
                }
                Section {
                    Button { save() } label: { Label(saved ? "Entry saved" : "Save fill-up", systemImage: saved ? "checkmark.circle.fill" : "tray.and.arrow.down.fill").frame(maxWidth: .infinity).fontWeight(.bold) }
                        .listRowBackground(Theme.green).disabled(rego.isEmpty || p <= 0 || l <= 0 || Double(odometer) == nil)
                }
            }.scrollContentBackground(.hidden).background(Color.black).navigationTitle("Fuel Information").toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    private func decimalField(_ title: String, text: Binding<String>) -> some View { TextField(title, text: text).keyboardType(.decimalPad) }
    private func save() {
        let odo = Double(odometer) ?? 0
        let entry = FuelEntry(rego: rego, date: date, fuelType: fuelType, pricePerLitre: p, litres: l, odometer: odo, rangeKm: Double(range) ?? 0, averageSpeed: Double(speed) ?? 0, calculatedLPer100Km: efficiency)
        context.insert(entry)
        do { try context.save(); saved = true; DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false } } catch { saved = false }
    }
}

struct HistoryView: View {
    @Query(sort: \FuelEntry.date, order: .reverse) private var entries: [FuelEntry]
    @Environment(\.modelContext) private var modelContext
    private var spend: Double { entries.reduce(0) { $0 + $1.totalCost } }
    var body: some View {
        NavigationStack {
            List {
                Section { HStack { summary("FILL-UPS", value: "\(entries.count)", tint: Theme.green); Spacer(); summary("TOTAL SPEND", value: spend.formatted(.currency(code: Locale.current.currency?.identifier ?? "AUD")), tint: Theme.orange) }.padding(.vertical, 4) }
                Section("Recent entries") {
                    if entries.isEmpty { ContentUnavailableView("No fill-ups yet", systemImage: "fuelpump", description: Text("Your saved fuel entries will appear here.")) }
                    ForEach(entries) { entry in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.rego.isEmpty ? "Vehicle" : entry.rego).font(.headline)
                                Text("\(entry.fuelType) · \(entry.date.formatted(date: .abbreviated, time: .omitted))").font(.subheadline).foregroundStyle(Theme.muted)
                                Text("\(entry.litres, specifier: "%.2f") L · \(entry.pricePerLitre, format: .currency(code: Locale.current.currency?.identifier ?? "AUD"))/L · \(entry.odometer, specifier: "%.0f") km").font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 5) { Text(entry.totalCost, format: .currency(code: Locale.current.currency?.identifier ?? "AUD")).fontWeight(.semibold).foregroundStyle(Theme.orange); if let eff = entry.calculatedLPer100Km { Text(String(format: "%.1f L/100", eff)).font(.caption).foregroundStyle(Theme.green) } }
                        }.listRowBackground(Theme.card)
                    }.onDelete(perform: delete)
                }
            }.scrollContentBackground(.hidden).background(Color.black).navigationTitle("History")
        }
    }
    private func summary(_ title: String, value: String, tint: Color) -> some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption2).foregroundStyle(Theme.muted); Text(value).font(.headline).foregroundStyle(tint) } }
    private func delete(_ offsets: IndexSet) { for index in offsets { modelContext.delete(entries[index]) } }
}

struct AnalyticsView: View {
    @Query(sort: \FuelEntry.date) private var entries: [FuelEntry]
    private var spend: Double { entries.reduce(0) { $0 + $1.totalCost } }
    private var distance: Double {
        let sorted = entries.sorted { $0.date < $1.date }
        guard sorted.count > 1 else { return 0 }
        return zip(sorted, sorted.dropFirst()).reduce(0) { sum, pair in pair.0.rego == pair.1.rego ? sum + max(0, pair.1.odometer - pair.0.odometer) : sum }
    }
    private var efficiencyEntries: [FuelEntry] { entries.filter { ($0.calculatedLPer100Km ?? 0) > 0 } }
    private var averageEfficiency: Double { let items = efficiencyEntries; return items.isEmpty ? 0 : items.reduce(0) { $0 + ($1.calculatedLPer100Km ?? 0) } / Double(items.count) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your driving, at a glance").font(.subheadline).foregroundStyle(Theme.muted).padding(.top, 4)
                    metric("Total fuel spend", value: spend.formatted(.currency(code: Locale.current.currency?.identifier ?? "AUD")), icon: "dollarsign.circle.fill", color: Theme.orange)
                    metric("Distance logged", value: distance.formatted(.number.precision(.fractionLength(0))) + " km", icon: "road.lanes.curved.left", color: Theme.green)
                    metric("Average efficiency", value: averageEfficiency > 0 ? String(format: "%.1f L/100 km", averageEfficiency) : "—", icon: "gauge.with.dots.needle.67percent", color: Theme.orange)
                    metric("Fill-ups recorded", value: "\(entries.count)", icon: "fuelpump.fill", color: Theme.green)
                    if !entries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SPEND OVER TIME").font(.caption.weight(.bold)).tracking(1).foregroundStyle(Theme.muted)
                            ForEach(Array(entries.suffix(8)), id: \.persistentModelID) { entry in
                                HStack { Text(entry.date.formatted(.dateTime.month(.abbreviated).day())).font(.caption).foregroundStyle(Theme.muted).frame(width: 56, alignment: .leading); GeometryReader { proxy in ZStack(alignment: .leading) { Capsule().fill(.white.opacity(0.07)); Capsule().fill(Theme.orange).frame(width: proxy.size.width * min(entry.totalCost / max(entries.map(\.totalCost).max() ?? 1, 1), 1)) } }; Text(entry.totalCost, format: .currency(code: Locale.current.currency?.identifier ?? "AUD")).font(.caption.monospacedDigit()).frame(width: 72, alignment: .trailing) }.frame(height: 16)
                            }
                        }.fuelCard()
                    }
                }.padding()
            }.background(Color.black).navigationTitle("Stats")
        }
    }
    private func metric(_ title: String, value: String, icon: String, color: Color) -> some View { HStack(spacing: 14) { Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 40); VStack(alignment: .leading, spacing: 5) { Text(title).font(.subheadline).foregroundStyle(Theme.muted); Text(value).font(.title3.bold()).foregroundStyle(.white) }; Spacer() }.fuelCard() }
}
