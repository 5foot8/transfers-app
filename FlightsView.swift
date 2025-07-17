import SwiftUI

struct FlightsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    @State private var showingIncomingModal = false
    @State private var showingOutgoingModal = false
    @State private var editingFlight: Any? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Flight Type", selection: $selectedTab) {
                    Text("Incoming").tag(0)
                    Text("Outgoing").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                if selectedTab == 0 {
                    IncomingFlightsList(
                        flights: dataManager.incomingFlights,
                        onAdd: { showingIncomingModal = true },
                        onEdit: { flight in
                            editingFlight = flight
                            showingIncomingModal = true
                        }
                    )
                } else {
                    OutgoingFlightsList(
                        flights: dataManager.outgoingFlights,
                        onAdd: { showingOutgoingModal = true },
                        onEdit: { flight in
                            editingFlight = flight
                            showingOutgoingModal = true
                        }
                    )
                }
            }
            .navigationTitle("Flights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingIncomingModal) {
                IncomingFlightModal(
                    flight: editingFlight as? IncomingFlight,
                    onSave: { flight in
                        Task {
                            if let editingFlight = editingFlight as? IncomingFlight {
                                try await dataManager.updateIncomingFlight(editingFlight.id ?? "", updates: flight.toDictionary())
                            } else {
                                _ = try await dataManager.createIncomingFlight(flight)
                            }
                            showingIncomingModal = false
                            editingFlight = nil
                        }
                    },
                    onCancel: {
                        showingIncomingModal = false
                        editingFlight = nil
                    }
                )
            }
            .sheet(isPresented: $showingOutgoingModal) {
                OutgoingFlightModal(
                    flight: editingFlight as? OutgoingFlight,
                    onSave: { flight in
                        Task {
                            if let editingFlight = editingFlight as? OutgoingFlight {
                                try await dataManager.updateOutgoingFlight(editingFlight.id ?? "", updates: flight.toDictionary())
                            } else {
                                _ = try await dataManager.createOutgoingFlight(flight)
                            }
                            showingOutgoingModal = false
                            editingFlight = nil
                        }
                    },
                    onCancel: {
                        showingOutgoingModal = false
                        editingFlight = nil
                    }
                )
            }
        }
    }
}

// MARK: - Incoming Flights List
struct IncomingFlightsList: View {
    let flights: [IncomingFlight]
    let onAdd: () -> Void
    let onEdit: (IncomingFlight) -> Void
    
    var body: some View {
        VStack {
            if flights.isEmpty {
                EmptyStateView(
                    icon: "airplane.arrival",
                    title: "No Incoming Flights",
                    message: "Add your first incoming flight to get started"
                )
            } else {
                List(flights, id: \.id) { flight in
                    IncomingFlightRow(flight: flight, onEdit: onEdit)
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
    }
}

// MARK: - Outgoing Flights List
struct OutgoingFlightsList: View {
    let flights: [OutgoingFlight]
    let onAdd: () -> Void
    let onEdit: (OutgoingFlight) -> Void
    
    var body: some View {
        VStack {
            if flights.isEmpty {
                EmptyStateView(
                    icon: "airplane.departure",
                    title: "No Outgoing Flights",
                    message: "Add your first outgoing flight to get started"
                )
            } else {
                List(flights, id: \.id) { flight in
                    OutgoingFlightRow(flight: flight, onEdit: onEdit)
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
    }
}

// MARK: - Flight Row Views
struct IncomingFlightRow: View {
    let flight: IncomingFlight
    let onEdit: (IncomingFlight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.flightNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(flight.origin) → Terminal \(flight.terminal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(flight.scheduledTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    StatusBadge(flight: flight)
                }
            }
            
            if !flight.notes.isEmpty {
                Text(flight.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let carousel = flight.carousel {
                    Label("Carousel \(carousel)", systemImage: "shippingbox")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button("Edit") {
                    onEdit(flight)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct OutgoingFlightRow: View {
    let flight: OutgoingFlight
    let onEdit: (OutgoingFlight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.flightNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Terminal \(flight.terminal) → \(flight.destination)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(flight.scheduledTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    StatusBadge(flight: flight)
                }
            }
            
            HStack {
                Spacer()
                
                Button("Edit") {
                    onEdit(flight)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions
extension IncomingFlight {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "flightNumber": flightNumber,
            "terminal": terminal,
            "origin": origin,
            "scheduledTime": scheduledTime,
            "notes": notes,
            "cancelled": cancelled,
            "outgoingLinks": outgoingLinks,
            "date": date
        ]
        
        if let actualArrivalTime = actualArrivalTime { dict["actualArrivalTime"] = actualArrivalTime }
        if let expectedArrivalTime = expectedArrivalTime { dict["expectedArrivalTime"] = expectedArrivalTime }
        if let bagAvailableTime = bagAvailableTime { dict["bagAvailableTime"] = bagAvailableTime }
        if let carousel = carousel { dict["carousel"] = carousel }
        if let collectedTime = collectedTime { dict["collectedTime"] = collectedTime }
        if let deliveredTime = deliveredTime { dict["deliveredTime"] = deliveredTime }
        if let screeningBags = screeningBags { dict["screeningBags"] = screeningBags }
        if let screeningStartTime = screeningStartTime { dict["screeningStartTime"] = screeningStartTime }
        if let screeningEndTime = screeningEndTime { dict["screeningEndTime"] = screeningEndTime }
        if let deliveredNonScreeningTime = deliveredNonScreeningTime { dict["deliveredNonScreeningTime"] = deliveredNonScreeningTime }
        if let deliveredScreeningTime = deliveredScreeningTime { dict["deliveredScreeningTime"] = deliveredScreeningTime }
        
        return dict
    }
}

extension OutgoingFlight {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "flightNumber": flightNumber,
            "terminal": terminal,
            "destination": destination,
            "scheduledTime": scheduledTime,
            "cancelled": cancelled,
            "bagsFromIncoming": bagsFromIncoming
        ]
        
        if let actualTime = actualTime { dict["actualTime"] = actualTime }
        if let expectedTime = expectedTime { dict["expectedTime"] = expectedTime }
        
        return dict
    }
} 