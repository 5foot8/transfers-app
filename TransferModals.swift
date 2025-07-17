import SwiftUI

// MARK: - Create Transfer Modal
struct CreateTransferModal: View {
    let incomingFlights: [IncomingFlight]
    let outgoingFlights: [OutgoingFlight]
    let onSave: (BaggageTransfer) -> Void
    let onCancel: () -> Void
    
    @State private var selectedIncomingFlightId = ""
    @State private var selectedOutgoingFlightId = ""
    @State private var bagCount = ""
    @State private var isMAGTransfer = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Incoming Flight") {
                    Picker("Select Incoming Flight", selection: $selectedIncomingFlightId) {
                        Text("Select a flight").tag("")
                        ForEach(incomingFlights, id: \.id) { flight in
                            Text("\(flight.flightNumber) - \(flight.origin) (T\(flight.terminal))")
                                .tag(flight.id ?? "")
                        }
                    }
                }
                
                Section("Outgoing Flight") {
                    Picker("Select Outgoing Flight", selection: $selectedOutgoingFlightId) {
                        Text("Select a flight").tag("")
                        ForEach(outgoingFlights, id: \.id) { flight in
                            Text("\(flight.flightNumber) - \(flight.destination) (T\(flight.terminal))")
                                .tag(flight.id ?? "")
                        }
                    }
                }
                
                Section("Transfer Details") {
                    TextField("Number of Bags", text: $bagCount)
                        .keyboardType(.numberPad)
                    
                    Toggle("MAG Transfer", isOn: $isMAGTransfer)
                }
                
                if let incomingFlight = incomingFlights.first(where: { $0.id == selectedIncomingFlightId }),
                   let outgoingFlight = outgoingFlights.first(where: { $0.id == selectedOutgoingFlightId }) {
                    Section("Transfer Summary") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("From: \(incomingFlight.flightNumber) (\(incomingFlight.origin))")
                                .font(.subheadline)
                            
                            Text("To: \(outgoingFlight.flightNumber) (\(outgoingFlight.destination))")
                                .font(.subheadline)
                            
                            Text("Bags: \(bagCount.isEmpty ? "0" : bagCount)")
                                .font(.subheadline)
                            
                            if isMAGTransfer {
                                Text("MAG Transfer")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        guard let bagCountInt = Int(bagCount),
                              !selectedIncomingFlightId.isEmpty,
                              !selectedOutgoingFlightId.isEmpty else { return }
                        
                        let transfer = BaggageTransfer(
                            incomingFlightId: selectedIncomingFlightId,
                            outgoingFlightId: selectedOutgoingFlightId,
                            bagCount: bagCountInt,
                            isMAGTransfer: isMAGTransfer
                        )
                        onSave(transfer)
                    }
                    .disabled(selectedIncomingFlightId.isEmpty || selectedOutgoingFlightId.isEmpty || bagCount.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Transfer Modal
struct EditTransferModal: View {
    let transfer: BaggageTransfer
    let onSave: ([String: Any]) -> Void
    let onCancel: () -> Void
    
    @State private var bagCount = ""
    @State private var isMAGTransfer = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transfer Details") {
                    TextField("Number of Bags", text: $bagCount)
                        .keyboardType(.numberPad)
                    
                    Toggle("MAG Transfer", isOn: $isMAGTransfer)
                }
                
                Section("Current Transfer") {
                    Text("Transfer ID: \(transfer.id ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Created: \(transfer.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let bagCountInt = Int(bagCount) else { return }
                        
                        let updates: [String: Any] = [
                            "bagCount": bagCountInt,
                            "isMAGTransfer": isMAGTransfer,
                            "updatedAt": Date()
                        ]
                        onSave(updates)
                    }
                    .disabled(bagCount.isEmpty)
                }
            }
        }
        .onAppear {
            bagCount = String(transfer.bagCount)
            isMAGTransfer = transfer.isMAGTransfer
        }
    }
} 