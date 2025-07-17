import Foundation
import FirebaseFirestore
import Combine

class DataManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var incomingFlights: [IncomingFlight] = []
    @Published var outgoingFlights: [OutgoingFlight] = []
    @Published var baggageTransfers: [BaggageTransfer] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupListeners()
    }
    
    // MARK: - Listeners
    private func setupListeners() {
        setupIncomingFlightsListener()
        setupOutgoingFlightsListener()
        setupBaggageTransfersListener()
    }
    
    private func setupIncomingFlightsListener() {
        db.collection("incomingFlights")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching incoming flights: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.incomingFlights = documents.compactMap { document in
                    try? document.data(as: IncomingFlight.self)
                }.sorted { $0.scheduledTime < $1.scheduledTime }
            }
    }
    
    private func setupOutgoingFlightsListener() {
        db.collection("outgoingFlights")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching outgoing flights: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.outgoingFlights = documents.compactMap { document in
                    try? document.data(as: OutgoingFlight.self)
                }.sorted { $0.scheduledTime < $1.scheduledTime }
            }
    }
    
    private func setupBaggageTransfersListener() {
        db.collection("baggageTransfers")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching baggage transfers: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.baggageTransfers = documents.compactMap { document in
                    try? document.data(as: BaggageTransfer.self)
                }
            }
    }
    
    // MARK: - Incoming Flights CRUD
    func createIncomingFlight(_ flight: IncomingFlight) async throws -> String {
        let docRef = try await db.collection("incomingFlights").addDocument(from: flight)
        return docRef.documentID
    }
    
    func updateIncomingFlight(_ id: String, updates: [String: Any]) async throws {
        try await db.collection("incomingFlights").document(id).updateData(updates)
    }
    
    func deleteIncomingFlight(_ id: String) async throws {
        try await db.collection("incomingFlights").document(id).delete()
    }
    
    // MARK: - Outgoing Flights CRUD
    func createOutgoingFlight(_ flight: OutgoingFlight) async throws -> String {
        let docRef = try await db.collection("outgoingFlights").addDocument(from: flight)
        return docRef.documentID
    }
    
    func updateOutgoingFlight(_ id: String, updates: [String: Any]) async throws {
        try await db.collection("outgoingFlights").document(id).updateData(updates)
    }
    
    func deleteOutgoingFlight(_ id: String) async throws {
        try await db.collection("outgoingFlights").document(id).delete()
    }
    
    // MARK: - Baggage Transfers CRUD
    func createBaggageTransfer(_ transfer: BaggageTransfer) async throws -> String {
        let docRef = try await db.collection("baggageTransfers").addDocument(from: transfer)
        return docRef.documentID
    }
    
    func updateBaggageTransfer(_ id: String, updates: [String: Any]) async throws {
        try await db.collection("baggageTransfers").document(id).updateData(updates)
    }
    
    func deleteBaggageTransfer(_ id: String) async throws {
        try await db.collection("baggageTransfers").document(id).delete()
    }
    
    // MARK: - Helper Methods
    func getTodayIncomingFlights() -> [IncomingFlight] {
        let today = Calendar.current.startOfDay(for: Date())
        return incomingFlights.filter { flight in
            Calendar.current.isDate(flight.date, inSameDayAs: today)
        }
    }
    
    func getTodayOutgoingFlights() -> [OutgoingFlight] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return outgoingFlights.filter { flight in
            flight.scheduledTime >= today && flight.scheduledTime < tomorrow
        }
    }
    
    func getWorkflowStats() -> WorkflowStats {
        let todayIncoming = getTodayIncomingFlights()
        let todayOutgoing = getTodayOutgoingFlights()
        
        let pendingCollections = todayIncoming.filter { flight in
            !flight.collectedTime.isNil && flight.bagAvailableTime.isNotNil && flight.bagAvailableTime! <= Date()
        }
        
        let pendingDeliveries = todayIncoming.filter { flight in
            flight.collectedTime.isNotNil && flight.deliveredTime.isNil
        }
        
        let totalBags = todayIncoming.reduce(0) { total, flight in
            total + flight.outgoingLinks.reduce(0) { sum, link in
                sum + link.bagCount
            }
        }
        
        return WorkflowStats(
            activeWorkflows: pendingCollections.count + pendingDeliveries.count,
            completedWorkflows: baggageTransfers.count,
            totalBags: totalBags,
            pendingCollections: pendingCollections.count,
            pendingDeliveries: pendingDeliveries.count
        )
    }
}

// MARK: - Optional Extensions
extension Optional {
    var isNil: Bool {
        return self == nil
    }
    
    var isNotNil: Bool {
        return self != nil
    }
} 