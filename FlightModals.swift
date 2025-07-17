import SwiftUI

// MARK: - Incoming Flight Modal
struct IncomingFlightModal: View {
    let flight: IncomingFlight?
    let onSave: (IncomingFlight) -> Void
    let onCancel: () -> Void
    
    @State private var flightNumber = ""
    @State private var terminal = ""
    @State private var origin = ""
    @State private var scheduledTime = Date()
    @State private var notes = ""
    @State private var carousel = ""
    @State private var bagAvailableTime: Date?
    @State private var actualArrivalTime: Date?
    @State private var expectedArrivalTime: Date?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Flight Details") {
                    TextField("Flight Number", text: $flightNumber)
                    TextField("Terminal", text: $terminal)
                    TextField("Origin", text: $origin)
                    DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Additional Information") {
                    TextField("Carousel", text: $carousel)
                    DatePicker("Bag Available Time", selection: Binding(
                        get: { bagAvailableTime ?? Date() },
                        set: { bagAvailableTime = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("Actual Arrival Time", selection: Binding(
                        get: { actualArrivalTime ?? Date() },
                        set: { actualArrivalTime = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("Expected Arrival Time", selection: Binding(
                        get: { expectedArrivalTime ?? Date() },
                        set: { expectedArrivalTime = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(flight == nil ? "Add Incoming Flight" : "Edit Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newFlight = IncomingFlight(
                            flightNumber: flightNumber,
                            terminal: terminal,
                            origin: origin,
                            scheduledTime: scheduledTime,
                            notes: notes,
                            date: Date()
                        )
                        onSave(newFlight)
                    }
                    .disabled(flightNumber.isEmpty || terminal.isEmpty || origin.isEmpty)
                }
            }
        }
        .onAppear {
            if let flight = flight {
                flightNumber = flight.flightNumber
                terminal = flight.terminal
                origin = flight.origin
                scheduledTime = flight.scheduledTime
                notes = flight.notes
                carousel = flight.carousel ?? ""
                bagAvailableTime = flight.bagAvailableTime
                actualArrivalTime = flight.actualArrivalTime
                expectedArrivalTime = flight.expectedArrivalTime
            }
        }
    }
}

// MARK: - Outgoing Flight Modal
struct OutgoingFlightModal: View {
    let flight: OutgoingFlight?
    let onSave: (OutgoingFlight) -> Void
    let onCancel: () -> Void
    
    @State private var flightNumber = ""
    @State private var terminal = ""
    @State private var destination = ""
    @State private var scheduledTime = Date()
    @State private var actualTime: Date?
    @State private var expectedTime: Date?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Flight Details") {
                    TextField("Flight Number", text: $flightNumber)
                    TextField("Terminal", text: $terminal)
                    TextField("Destination", text: $destination)
                    DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Additional Information") {
                    DatePicker("Actual Time", selection: Binding(
                        get: { actualTime ?? Date() },
                        set: { actualTime = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("Expected Time", selection: Binding(
                        get: { expectedTime ?? Date() },
                        set: { expectedTime = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle(flight == nil ? "Add Outgoing Flight" : "Edit Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newFlight = OutgoingFlight(
                            flightNumber: flightNumber,
                            terminal: terminal,
                            destination: destination,
                            scheduledTime: scheduledTime
                        )
                        onSave(newFlight)
                    }
                    .disabled(flightNumber.isEmpty || terminal.isEmpty || destination.isEmpty)
                }
            }
        }
        .onAppear {
            if let flight = flight {
                flightNumber = flight.flightNumber
                terminal = flight.terminal
                destination = flight.destination
                scheduledTime = flight.scheduledTime
                actualTime = flight.actualTime
                expectedTime = flight.expectedTime
            }
        }
    }
} 