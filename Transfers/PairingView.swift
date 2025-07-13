import SwiftUI

struct FlightPair: Hashable, Identifiable {
    let id = UUID()
    let arrival: IncomingFlight
    let departure: OutgoingFlight
    var bagCount: Int
}

struct PairingView: View {
    let arrivals: [IncomingFlight]
    let departures: [OutgoingFlight]
    var onComplete: ([FlightPair]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var selectedArrivals: Set<UUID> = []
    @State private var selectedDepartures: Set<UUID> = []
    @State private var pairs: [FlightPair] = []
    @State private var bagCounts: [String: String] = [:] // key: "arrivalID-departureID"

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Arrivals Section
                        Text("Arrivals").font(.title2).bold().padding(.top, 8)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                            ForEach(arrivals, id: \.id) { arrival in
                                ArrivalRow(arrival: arrival, selected: selectedArrivals.contains(arrival.id))
                                    .onTapGesture {
                                        if selectedArrivals.contains(arrival.id) {
                                            selectedArrivals.remove(arrival.id)
                                        } else {
                                            selectedArrivals.insert(arrival.id)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 4)
                        // Departures Section
                        Text("Departures").font(.title2).bold().padding(.top, 12)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                            ForEach(departures, id: \.id) { departure in
                                DepartureRow(departure: departure, selected: selectedDepartures.contains(departure.id))
                                    .onTapGesture {
                                        if selectedDepartures.contains(departure.id) {
                                            selectedDepartures.remove(departure.id)
                                        } else {
                                            selectedDepartures.insert(departure.id)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 4)
                        // Pairing Section
                        if !selectedPairs.isEmpty {
                            Divider().padding(.vertical, 8)
                            ForEach(selectedPairs.indices, id: \.self) { idx in
                                let (arrival, departure) = selectedPairs[idx]
                                let key = "\(arrival.id.uuidString)-\(departure.id.uuidString)"
                                HStack(spacing: 8) {
                                    ArrivalRow(arrival: arrival, selected: false)
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                    DepartureRow(departure: departure, selected: false)
                                    TextField("Bags", text: Binding(
                                        get: { bagCounts[key] ?? existingBagCount(arrival: arrival, departure: departure) },
                                        set: { newValue in
                                            bagCounts[key] = newValue
                                            updatePair(arrival: arrival, departure: departure, bagCount: newValue)
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .font(.headline)
                                    .frame(width: 44)
                                    .textFieldStyle(.roundedBorder)
                                    Button(action: {
                                        removePair(arrival: arrival, departure: departure)
                                        bagCounts[key] = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        // Summary Section
                        if !pairs.isEmpty {
                            Divider().padding(.vertical, 8)
                            ForEach(pairs, id: \.id) { pair in
                                HStack(spacing: 8) {
                                    ArrivalRow(arrival: pair.arrival, selected: false)
                                    Image(systemName: "arrow.right")
                                        .font(.body)
                                    DepartureRow(departure: pair.departure, selected: false)
                                    Text("\(pair.bagCount)")
                                        .font(.body)
                                        .frame(width: 44)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                // Bottom buttons
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    Spacer()
                    Button("Done") {
                        onComplete(pairs)
                        dismiss()
                    }
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .disabled(pairs.isEmpty)
                }
                .background(Color(.systemBackground))
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
            .navigationTitle("Pair Flights")
        }
    }

    // All selected arrival-departure pairs
    var selectedPairs: [(IncomingFlight, OutgoingFlight)] {
        let selectedArr = arrivals.filter { selectedArrivals.contains($0.id) }
        let selectedDep = departures.filter { selectedDepartures.contains($0.id) }
        var result: [(IncomingFlight, OutgoingFlight)] = []
        for a in selectedArr {
            for d in selectedDep {
                result.append((a, d))
            }
        }
        return result
    }

    func existingBagCount(arrival: IncomingFlight, departure: OutgoingFlight) -> String {
        if let pair = pairs.first(where: { $0.arrival.id == arrival.id && $0.departure.id == departure.id }) {
            return String(pair.bagCount)
        }
        return ""
    }

    func updatePair(arrival: IncomingFlight, departure: OutgoingFlight, bagCount: String) {
        guard let count = Int(bagCount), count > 0 else { return }
        if let idx = pairs.firstIndex(where: { $0.arrival.id == arrival.id && $0.departure.id == departure.id }) {
            pairs[idx].bagCount = count
        } else {
            pairs.append(FlightPair(arrival: arrival, departure: departure, bagCount: count))
        }
    }

    func removePair(arrival: IncomingFlight, departure: OutgoingFlight) {
        if let idx = pairs.firstIndex(where: { $0.arrival.id == arrival.id && $0.departure.id == departure.id }) {
            pairs.remove(at: idx)
        }
    }
}

struct ArrivalRow: View {
    let arrival: IncomingFlight
    let selected: Bool
    var body: some View {
        HStack(spacing: 6) {
            Text(arrival.flightNumber)
                .fontWeight(.bold)
                .font(.title3.monospaced())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(2)
            Text(airportCode(from: arrival.origin))
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(arrival.scheduledTime, style: .time)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(arrival.terminal.uppercased())
                .font(.headline).bold()
                .foregroundColor(terminalColor(arrival.terminal))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(2)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .background(selected ? Color.blue.opacity(0.13) : Color.clear)
        .cornerRadius(4)
    }
    func airportCode(from s: String) -> String {
        if let open = s.lastIndex(of: "("), let close = s.lastIndex(of: ")"), open < close {
            return String(s[s.index(after: open)..<close])
        } else if s.count == 3 {
            return s
        } else {
            return "---"
        }
    }
    func terminalColor(_ terminal: String) -> Color {
        switch terminal.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "1", "T1": return .blue
        case "2", "T2": return .green
        case "3", "T3": return .orange
        default: return .gray
        }
    }
}

struct DepartureRow: View {
    let departure: OutgoingFlight
    let selected: Bool
    var body: some View {
        HStack(spacing: 6) {
            Text(departure.flightNumber)
                .fontWeight(.bold)
                .font(.title3.monospaced())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(2)
            Text(airportCode(from: departure.destination))
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(departure.scheduledTime, style: .time)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(departure.terminal.uppercased())
                .font(.headline).bold()
                .foregroundColor(terminalColor(departure.terminal))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(2)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .background(selected ? Color.green.opacity(0.13) : Color.clear)
        .cornerRadius(4)
    }
    func airportCode(from s: String) -> String {
        if let open = s.lastIndex(of: "("), let close = s.lastIndex(of: ")"), open < close {
            return String(s[s.index(after: open)..<close])
        } else if s.count == 3 {
            return s
        } else {
            return "---"
        }
    }
    func terminalColor(_ terminal: String) -> Color {
        switch terminal.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "1", "T1": return .blue
        case "2", "T2": return .green
        case "3", "T3": return .orange
        default: return .gray
        }
    }
} 