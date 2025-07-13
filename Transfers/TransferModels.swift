import Foundation

struct IncomingFlight: Identifiable, Hashable, Codable {
    let id: UUID
    var flightNumber: String
    var terminal: String
    var origin: String
    var scheduledTime: Date
    var actualArrivalTime: Date? // new, preferred
    var expectedArrivalTime: Date? // new, for E suffix
    var notes: String
    var cancelled: Bool // new
    // Outgoing flights associated with this incoming flight
    var outgoingLinks: [OutgoingLink]
    var date: Date // Only the day component matters
    
    init(flightNumber: String, terminal: String, origin: String, scheduledTime: Date, actualArrivalTime: Date? = nil, expectedArrivalTime: Date? = nil, notes: String = "", cancelled: Bool = false, date: Date = Date()) {
        self.id = UUID()
        self.flightNumber = flightNumber
        self.terminal = terminal
        self.origin = origin
        self.scheduledTime = scheduledTime
        self.actualArrivalTime = actualArrivalTime
        self.expectedArrivalTime = expectedArrivalTime
        self.notes = notes
        self.cancelled = cancelled
        self.outgoingLinks = []
        self.date = Calendar.current.startOfDay(for: date)
    }
}

struct OutgoingFlight: Identifiable, Hashable, Codable {
    let id: UUID
    var flightNumber: String
    var terminal: String
    var destination: String
    var scheduledTime: Date
    var actualTime: Date?
    var expectedTime: Date? // new, for E suffix
    var cancelled: Bool // new
    // Mapping from incoming flightNumber to bag count
    var bagsFromIncoming: [String: Int]
    
    init(flightNumber: String, terminal: String, destination: String, scheduledTime: Date, actualTime: Date? = nil, expectedTime: Date? = nil, cancelled: Bool = false) {
        self.id = UUID()
        self.flightNumber = flightNumber
        self.terminal = terminal
        self.destination = destination
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.expectedTime = expectedTime
        self.cancelled = cancelled
        self.bagsFromIncoming = [:]
    }
    
    var totalBags: Int {
        bagsFromIncoming.values.reduce(0, +)
    }
}

struct OutgoingLink: Identifiable, Hashable, Codable {
    let id: UUID
    var outgoingFlightID: UUID
    var bagCount: Int
    // Optionally, add more fields if needed
    init(outgoingFlightID: UUID, bagCount: Int) {
        self.id = UUID()
        self.outgoingFlightID = outgoingFlightID
        self.bagCount = bagCount
    }
} 