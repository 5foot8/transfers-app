import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore
import SwiftUI
import Combine

enum SyncMode: String, CaseIterable, Identifiable {
    case local = "Local Only"
    case cloud = "Cloud Sync"
    case live = "Live Session"
    
    var id: String { rawValue }
}

@MainActor
class FirebaseSync: ObservableObject {
    static let shared = FirebaseSync()
    private let db: Firestore
    
    @Published var syncMode: SyncMode = .local
    @Published var isConnected: Bool = false
    @Published var lastSyncTime: Date? = nil
    @Published var sessionID: String? = nil
    
    private init() {
        // Initialize Firestore with error handling
        if FirebaseApp.app() != nil {
            self.db = Firestore.firestore()
        } else {
            // Fallback - this shouldn't happen if FirebaseApp.configure() is called
            print("Warning: Firebase not configured, using default Firestore instance")
            self.db = Firestore.firestore()
        }
        
        // Load saved sync mode
        if let savedMode = UserDefaults.standard.string(forKey: "syncMode"),
           let mode = SyncMode(rawValue: savedMode) {
            syncMode = mode
        }
        
        // Only setup Firebase if not in local mode
        if syncMode != .local {
            setupAuth()
        }
    }
    
    func setSyncMode(_ mode: SyncMode) {
        syncMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "syncMode")
        
        if mode == .local {
            isConnected = false
            sessionID = nil
        } else {
            setupAuth()
        }
    }
    
    private func setupAuth() {
        Task {
            do {
                try await Auth.auth().signInAnonymously()
                self.isConnected = true
                
                if syncMode == .live {
                    // Generate or join session
                    setupLiveSession()
                }
            } catch {
                print("Firebase auth failed: \(error)")
                self.isConnected = false
            }
        }
    }
    
    private func setupLiveSession() {
        // Generate a unique session ID
        sessionID = UUID().uuidString
        UserDefaults.standard.set(sessionID, forKey: "sessionID")
        
        // Set up real-time listeners for live mode
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        guard let sessionID = sessionID else { return }
        
        // Listen for incoming flight changes
        db.collection("sessions")
            .document(sessionID)
            .collection("incomingFlights")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                
                Task { @MainActor in
                    for change in snapshot.documentChanges {
                        switch change.type {
                        case .added, .modified:
                            if let flight = try? change.document.data(as: IncomingFlight.self) {
                                // Notify the app of remote changes
                                NotificationCenter.default.post(
                                    name: .remoteFlightUpdated,
                                    object: flight
                                )
                            }
                        case .removed:
                            // Handle deletion
                            break
                        }
                    }
                }
            }
        
        // Listen for outgoing flight changes
        db.collection("sessions")
            .document(sessionID)
            .collection("outgoingFlights")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                
                Task { @MainActor in
                    for change in snapshot.documentChanges {
                        switch change.type {
                        case .added, .modified:
                            if let flight = try? change.document.data(as: OutgoingFlight.self) {
                                // Notify the app of remote changes
                                NotificationCenter.default.post(
                                    name: .remoteFlightUpdated,
                                    object: flight
                                )
                            }
                        case .removed:
                            // Handle deletion
                            break
                        }
                    }
                }
            }
    }
    
    func syncIncomingFlights(_ flights: [IncomingFlight]) async {
        guard syncMode != .local && isConnected else { return }
        
        do {
            let collection = syncMode == .live ? 
                db.collection("sessions").document(sessionID ?? "").collection("incomingFlights") :
                db.collection("incomingFlights")
            
            for flight in flights {
                try await collection
                    .document(flight.id.uuidString)
                    .setData(from: flight)
            }
            
            self.lastSyncTime = Date()
        } catch {
            print("Failed to sync incoming flights: \(error)")
        }
    }
    
    func syncOutgoingFlights(_ flights: [OutgoingFlight]) async {
        guard syncMode != .local && isConnected else { return }
        
        do {
            let collection = syncMode == .live ? 
                db.collection("sessions").document(sessionID ?? "").collection("outgoingFlights") :
                db.collection("outgoingFlights")
            
            for flight in flights {
                try await collection
                    .document(flight.id.uuidString)
                    .setData(from: flight)
            }
            
            self.lastSyncTime = Date()
        } catch {
            print("Failed to sync outgoing flights: \(error)")
        }
    }
    
    func loadIncomingFlights() async -> [IncomingFlight] {
        guard syncMode != .local && isConnected else { return [] }
        
        do {
            let collection = syncMode == .live ? 
                db.collection("sessions").document(sessionID ?? "").collection("incomingFlights") :
                db.collection("incomingFlights")
            
            let snapshot = try await collection.getDocuments()
            return snapshot.documents.compactMap { document in
                try? document.data(as: IncomingFlight.self)
            }
        } catch {
            print("Failed to load incoming flights: \(error)")
            return []
        }
    }
    
    func loadOutgoingFlights() async -> [OutgoingFlight] {
        guard syncMode != .local && isConnected else { return [] }
        
        do {
            let collection = syncMode == .live ? 
                db.collection("sessions").document(sessionID ?? "").collection("outgoingFlights") :
                db.collection("outgoingFlights")
            
            let snapshot = try await collection.getDocuments()
            return snapshot.documents.compactMap { document in
                try? document.data(as: OutgoingFlight.self)
            }
        } catch {
            print("Failed to load outgoing flights: \(error)")
            return []
        }
    }
    
    func joinSession(_ sessionID: String) async -> Bool {
        guard syncMode == .live else { return false }
        
        do {
            // Verify session exists
            let sessionDoc = try await db.collection("sessions").document(sessionID).getDocument()
            if sessionDoc.exists {
                self.sessionID = sessionID
                UserDefaults.standard.set(sessionID, forKey: "sessionID")
                setupRealtimeListeners()
                return true
            }
            return false
        } catch {
            print("Failed to join session: \(error)")
            return false
        }
    }
    
    func createSession() async -> String? {
        guard syncMode == .live else { return nil }
        
        do {
            let sessionID = UUID().uuidString
            try await db.collection("sessions").document(sessionID).setData([
                "createdAt": FieldValue.serverTimestamp(),
                "createdBy": Auth.auth().currentUser?.uid ?? "unknown"
            ])
            
            self.sessionID = sessionID
            UserDefaults.standard.set(sessionID, forKey: "sessionID")
            setupRealtimeListeners()
            return sessionID
        } catch {
            print("Failed to create session: \(error)")
            return nil
        }
    }
}

// Notification names for remote updates
extension Notification.Name {
    static let remoteFlightUpdated = Notification.Name("remoteFlightUpdated")
} 