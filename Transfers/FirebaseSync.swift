import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Combine

@MainActor
class FirebaseSync: ObservableObject {
    static let shared = FirebaseSync()
    private let db = Firestore.firestore()
    
    @Published var isConnected: Bool = false
    @Published var lastSyncTime: Date? = nil
    
    private init() {
        Task {
            await setupAuth()
        }
    }
    
    private func setupAuth() async {
        do {
            try await Auth.auth().signInAnonymously()
            self.isConnected = true
        } catch {
            print("Firebase auth failed: \(error)")
        }
    }
    
    func syncIncomingFlights(_ flights: [IncomingFlight]) async {
        guard isConnected else { return }
        
        do {
            for flight in flights {
                try await db.collection("incomingFlights")
                    .document(flight.id.uuidString)
                    .setData(from: flight)
            }
            
            self.lastSyncTime = Date()
        } catch {
            print("Failed to sync incoming flights: \(error)")
        }
    }
    
    func syncOutgoingFlights(_ flights: [OutgoingFlight]) async {
        guard isConnected else { return }
        
        do {
            for flight in flights {
                try await db.collection("outgoingFlights")
                    .document(flight.id.uuidString)
                    .setData(from: flight)
            }
            
            self.lastSyncTime = Date()
        } catch {
            print("Failed to sync outgoing flights: \(error)")
        }
    }
    
    func loadIncomingFlights() async -> [IncomingFlight] {
        guard isConnected else { return [] }
        
        do {
            let snapshot = try await db.collection("incomingFlights").getDocuments()
            return snapshot.documents.compactMap { document in
                try? document.data(as: IncomingFlight.self)
            }
        } catch {
            print("Failed to load incoming flights: \(error)")
            return []
        }
    }
    
    func loadOutgoingFlights() async -> [OutgoingFlight] {
        guard isConnected else { return [] }
        
        do {
            let snapshot = try await db.collection("outgoingFlights").getDocuments()
            return snapshot.documents.compactMap { document in
                try? document.data(as: OutgoingFlight.self)
            }
        } catch {
            print("Failed to load outgoing flights: \(error)")
            return []
        }
    }
} 