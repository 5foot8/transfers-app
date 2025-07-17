import Foundation
import FirebaseFirestore

// MARK: - Incoming Flight Model
struct IncomingFlight: Identifiable, Codable {
    @DocumentID var id: String?
    var flightNumber: String
    var terminal: String
    var origin: String
    var scheduledTime: Date
    var actualArrivalTime: Date?
    var expectedArrivalTime: Date?
    var bagAvailableTime: Date?
    var carousel: String?
    var notes: String
    var cancelled: Bool
    var outgoingLinks: [OutgoingLink]
    var date: Date
    var collectedTime: Date?
    var deliveredTime: Date?
    var screeningBags: Int?
    var screeningStartTime: Date?
    var screeningEndTime: Date?
    var deliveredNonScreeningTime: Date?
    var deliveredScreeningTime: Date?
    
    init(flightNumber: String, terminal: String, origin: String, scheduledTime: Date, notes: String = "", date: Date = Date()) {
        self.flightNumber = flightNumber
        self.terminal = terminal
        self.origin = origin
        self.scheduledTime = scheduledTime
        self.notes = notes
        self.cancelled = false
        self.outgoingLinks = []
        self.date = date
    }
}

// MARK: - Outgoing Flight Model
struct OutgoingFlight: Identifiable, Codable {
    @DocumentID var id: String?
    var flightNumber: String
    var terminal: String
    var destination: String
    var scheduledTime: Date
    var actualTime: Date?
    var expectedTime: Date?
    var cancelled: Bool
    var bagsFromIncoming: [String: Int]
    
    init(flightNumber: String, terminal: String, destination: String, scheduledTime: Date) {
        self.flightNumber = flightNumber
        self.terminal = terminal
        self.destination = destination
        self.scheduledTime = scheduledTime
        self.cancelled = false
        self.bagsFromIncoming = [:]
    }
}

// MARK: - Outgoing Link Model
struct OutgoingLink: Identifiable, Codable {
    var id: String
    var outgoingFlightID: String
    var bagCount: Int
    var isMAGTransfer: Bool
    
    init(outgoingFlightID: String, bagCount: Int, isMAGTransfer: Bool = false) {
        self.id = UUID().uuidString
        self.outgoingFlightID = outgoingFlightID
        self.bagCount = bagCount
        self.isMAGTransfer = isMAGTransfer
    }
}

// MARK: - Baggage Transfer Model
struct BaggageTransfer: Identifiable, Codable {
    @DocumentID var id: String?
    var incomingFlightId: String
    var outgoingFlightId: String
    var bagCount: Int
    var isMAGTransfer: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(incomingFlightId: String, outgoingFlightId: String, bagCount: Int, isMAGTransfer: Bool = false) {
        self.incomingFlightId = incomingFlightId
        self.outgoingFlightId = outgoingFlightId
        self.bagCount = bagCount
        self.isMAGTransfer = isMAGTransfer
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Workflow Stats Model
struct WorkflowStats: Codable {
    var activeWorkflows: Int
    var completedWorkflows: Int
    var totalBags: Int
    var pendingCollections: Int
    var pendingDeliveries: Int
}

// MARK: - Flight Status Enum
enum FlightStatus {
    case scheduled
    case ready
    case collected
    case delivered
    case cancelled
    
    var color: String {
        switch self {
        case .scheduled: return "gray"
        case .ready: return "yellow"
        case .collected: return "blue"
        case .delivered: return "green"
        case .cancelled: return "red"
        }
    }
    
    var text: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .ready: return "Ready"
        case .collected: return "Collected"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Terminal Colors
func terminalColor(_ terminal: String) -> Color {
    switch terminal.lowercased() {
    case "1": return .blue
    case "2": return .green
    case "3": return .orange
    default: return .gray
    }
} 