import SwiftUI
import PDFKit
internal import Combine
import WebKit
import SwiftSoup

// 1. Define atRiskThreshold at the top level
let atRiskThreshold: TimeInterval = 1 * 60 * 60

// Add missing Array extensions
extension Array where Element == IncomingFlight {
    mutating func updateOrAppend(_ flight: IncomingFlight) {
        if let index = firstIndex(where: { $0.flightNumber == flight.flightNumber && $0.scheduledTime == flight.scheduledTime }) {
            self[index] = flight
        } else {
            append(flight)
        }
    }
    
    func find(_ flight: IncomingFlight) -> IncomingFlight? {
        return first(where: { $0.flightNumber == flight.flightNumber && $0.scheduledTime == flight.scheduledTime })
    }
}

extension Array where Element == OutgoingFlight {
    mutating func updateOrAppend(_ flight: OutgoingFlight) {
        if let index = firstIndex(where: { $0.flightNumber == flight.flightNumber && $0.scheduledTime == flight.scheduledTime }) {
            self[index] = flight
        } else {
            append(flight)
        }
    }
    
    func find(_ flight: OutgoingFlight) -> OutgoingFlight? {
        return first(where: { $0.flightNumber == flight.flightNumber && $0.scheduledTime == flight.scheduledTime })
    }
}

func today() -> Date {
    Calendar.current.startOfDay(for: Date())
}

func terminalColor(_ terminal: String) -> Color {
    switch terminal.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
    case "1", "T1": return .blue
    case "2", "T2": return .green
    case "3", "T3": return .orange
    default: return .gray
    }
}

// Add theme enum and state
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }
}

// 1. Add TopBarView subview
struct TopBarView: View {
    @Binding var showingWebImport: Bool
    @Binding var showingPairing: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAddIncoming: Bool
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TMS")
                    .font(.title).bold()
                Text("Transfer Management System")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .padding(4)
            }
            .accessibilityLabel("Settings")
            Button(action: { showingAddIncoming = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .padding(4)
            }
            .accessibilityLabel("Add Incoming Flight")
        }
        .padding(.horizontal)
        .padding(.top, 2)
    }
}

// 2. Add MainContentBodyView subview
struct MainContentBodyView: View {
    @Binding var incomingFlights: [IncomingFlight]
    @Binding var outgoingFlights: [OutgoingFlight]
    let terminals: [String]
    @Binding var expandedFlights: Set<UUID>
    @Binding var showingAddIncoming: Bool
    @Binding var showingAddOutgoingFor: IncomingFlight?
    @Binding var showingPDFPreview: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingResetAlert: Bool
    @Binding var showingLivePage: Bool
    @Binding var pdfData: Data?
    @Binding var showingSettings: Bool
    @Binding var collapsedTerminals: Set<String>
    let removeOutgoingLink: (UUID, UUID) -> Void
    let deleteIncomingFlight: (UUID) -> Void
    let addOutgoingFlight: (UUID, OutgoingFlight, Int) -> Void
    let showAtRiskOnly: Bool
    let aetherFlights: [String: (terminal: String, scheduledTime: Date, expectedBags: Int, status: String)]
    @Binding var selectedFlightForDetails: IncomingFlight?
    var body: some View {
        MainContentView(
            incomingFlights: $incomingFlights,
            outgoingFlights: $outgoingFlights,
            terminals: terminals,
            expandedFlights: $expandedFlights,
            showingAddIncoming: $showingAddIncoming,
            showingAddOutgoingFor: $showingAddOutgoingFor,
            showingPDFPreview: $showingPDFPreview,
            showingShareSheet: $showingShareSheet,
            showingResetAlert: $showingResetAlert,
            showingLivePage: $showingLivePage,
            pdfData: $pdfData,
            now: Date(),
            timer: Timer.publish(every: 1, on: .main, in: .common).autoconnect(),
            saveData: {},
            loadData: {},
            filterForToday: {},
            addOutgoingFlight: addOutgoingFlight,
            removeOutgoingLink: removeOutgoingLink,
            deleteIncomingFlight: deleteIncomingFlight,
            showingSettings: $showingSettings,
            collapsedTerminals: $collapsedTerminals,
            showAtRiskOnly: showAtRiskOnly,
            aetherFlights: aetherFlights,
            selectedFlightForDetails: $selectedFlightForDetails
        )
    }
}

struct ContentView: View {
    @State private var incomingFlights: [IncomingFlight] = []
    @State private var outgoingFlights: [OutgoingFlight] = []
    @State private var showingAddIncoming = false
    @State private var editingIncomingID: UUID? = nil
    @State private var showingAddOutgoingFor: IncomingFlight? = nil
    @State private var expandedFlights: Set<UUID> = []
    @State private var pdfData: Data? = nil
    @State private var showingShareSheet = false
    @State private var showingPDFPreview = false
    @State private var showingResetAlert = false
    @State private var showingLivePage = false
    @State private var now = Date()
    @State private var showingWebImport = false
    @State private var arrivalsImportList: [IncomingFlight] = []
    @State private var departuresImportList: [OutgoingFlight] = []
    @State private var selectedDeparture: OutgoingFlight? = nil
    @State private var bagCountsForPanel: [UUID: Int] = [:]
    @State private var showingSettings = false
    @State private var appTheme: AppTheme = .system
    @State private var collapsedTerminals: Set<String> = []
    @State private var showingPairing = false
    @State private var showAtRiskOnly = false
    @State private var showingAetherSheet = false
    @State private var aetherFlights: [String: (terminal: String, scheduledTime: Date, expectedBags: Int, status: String)] = [:] // flightNumber: (terminal, time, bags, status)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var selectedFlightForDetails: IncomingFlight? = nil
    @State private var showingUrgentOverlay = false
    @State private var showAllOutgoingInOverlay = false
    @State private var webLoaderFlight: IncomingFlight? = nil
    
    var terminals: [String] {
        let allTerminals = incomingFlights.map { $0.terminal }
        let uniqueTerminals = Set(allTerminals)
        return Array(uniqueTerminals).sorted()
    }
    
    func saveData() {
        let encoder = JSONEncoder()
        if let incomingData = try? encoder.encode(incomingFlights) {
            UserDefaults.standard.set(incomingData, forKey: "incomingFlights")
        }
        if let outgoingData = try? encoder.encode(outgoingFlights) {
            UserDefaults.standard.set(outgoingData, forKey: "outgoingFlights")
        }
    }

    func loadData() {
        let decoder = JSONDecoder()
        if let incomingData = UserDefaults.standard.data(forKey: "incomingFlights"),
           let decodedIncoming = try? decoder.decode([IncomingFlight].self, from: incomingData) {
            incomingFlights = decodedIncoming
        }
        if let outgoingData = UserDefaults.standard.data(forKey: "outgoingFlights"),
           let decodedOutgoing = try? decoder.decode([OutgoingFlight].self, from: outgoingData) {
            outgoingFlights = decodedOutgoing
        }
    }
    
    func filterForToday() {
        let todayDate = today()
        incomingFlights = incomingFlights.filter { Calendar.current.isDate($0.date, inSameDayAs: todayDate) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBarView(
                showingWebImport: $showingWebImport,
                showingPairing: $showingPairing,
                showingSettings: $showingSettings,
                showingAddIncoming: $showingAddIncoming
            )
            HStack(spacing: 16) {
                Button(action: { showingWebImport = true }) {
                    Label("Import Flights", systemImage: "square.and.arrow.down")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                Button(action: { showingPairing = true }) {
                    Label("Pair Flights", systemImage: "link")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
            UrgentOutgoingButton(
                urgentFlights: urgentFlights,
                onTap: { showingUrgentOverlay = true },
                isOverlayPresented: showingUrgentOverlay
            )
            MainContentBodyView(
                incomingFlights: $incomingFlights,
                outgoingFlights: $outgoingFlights,
                terminals: terminals,
                expandedFlights: $expandedFlights,
                showingAddIncoming: $showingAddIncoming,
                showingAddOutgoingFor: $showingAddOutgoingFor,
                showingPDFPreview: $showingPDFPreview,
                showingShareSheet: $showingShareSheet,
                showingResetAlert: $showingResetAlert,
                showingLivePage: $showingLivePage,
                pdfData: $pdfData,
                showingSettings: $showingSettings,
                collapsedTerminals: $collapsedTerminals,
                removeOutgoingLink: removeOutgoingLink,
                deleteIncomingFlight: deleteIncomingFlight,
                addOutgoingFlight: addOutgoingFlight,
                showAtRiskOnly: showAtRiskOnly,
                aetherFlights: aetherFlights,
                selectedFlightForDetails: $selectedFlightForDetails
            )
        }
        .sheet(isPresented: $showingWebImport) {
            ArrivalsImportSheet(
                arrivalsImportList: $arrivalsImportList,
                departuresImportList: $departuresImportList,
                selectedDeparture: $selectedDeparture,
                bagCountsForPanel: $bagCountsForPanel,
                allArrivals: incomingFlights,
                onSaveDepartureBags: { departure, bagCounts in
                    var outgoing = departure
                    
                    // First, add or update the outgoing flight
                    outgoingFlights.updateOrAppend(outgoing)
                    
                    // Get the final outgoing flight (with updated ID if it was appended)
                    let finalOutgoing = outgoingFlights.find(outgoing) ?? outgoing
                    
                    // Now create the links from incoming flights to this outgoing flight
                    for (arrivalID, count) in bagCounts where count > 0 {
                        // Find the arrival by UUID
                        if let arrivalIndex = incomingFlights.firstIndex(where: { $0.id == arrivalID }) {
                            var arrival = incomingFlights[arrivalIndex]
                            
                            // Add the outgoing link if it doesn't exist
                            if !arrival.outgoingLinks.contains(where: { $0.outgoingFlightID == finalOutgoing.id }) {
                                arrival.outgoingLinks.append(OutgoingLink(outgoingFlightID: finalOutgoing.id, bagCount: count))
                            }
                            
                            // Update the arrival flight
                            incomingFlights[arrivalIndex] = arrival
                            
                            // Update the bagsFromIncoming dictionary
                            outgoing.bagsFromIncoming[arrival.flightNumber] = count
                        }
                    }
                    
                    // Update the outgoing flight with the bag counts
                    if let outgoingIndex = outgoingFlights.firstIndex(where: { $0.id == finalOutgoing.id }) {
                        outgoingFlights[outgoingIndex].bagsFromIncoming = outgoing.bagsFromIncoming
                    }
                },
                onDone: {
                    for flight in arrivalsImportList {
                        incomingFlights.updateOrAppend(flight)
                    }
                    for flight in departuresImportList {
                        outgoingFlights.updateOrAppend(flight)
                    }
                    arrivalsImportList = []
                    departuresImportList = []
                    showingWebImport = false
                }
            )
        }
        .onAppear(perform: {
            loadData()
            filterForToday()
        })
        .onChange(of: incomingFlights) { _, _ in saveData() }
        .onChange(of: outgoingFlights) { _, _ in saveData() }
        .onReceive(timer) { _ in }
        .sheet(isPresented: $showingLivePage) {
            LivePageView(
                incomingFlights: incomingFlights,
                outgoingFlights: outgoingFlights,
                now: now
            )
        }
        // 4. Settings sheet
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(
                appTheme: $appTheme,
                onResetDay: {
                    incomingFlights = []
                    outgoingFlights = []
                },
                onClose: { showingSettings = false }
            )
        }
        .sheet(isPresented: $showingPairing) {
            PairingView(arrivals: incomingFlights, departures: outgoingFlights) { pairs in
                // Update the data model with the new pairs
                for pair in pairs {
                    // Add outgoing link to arrival
                    if let idx = incomingFlights.firstIndex(where: { $0.id == pair.arrival.id }) {
                        var arrival = incomingFlights[idx]
                        if !arrival.outgoingLinks.contains(where: { $0.outgoingFlightID == pair.departure.id }) {
                            arrival.outgoingLinks.append(OutgoingLink(outgoingFlightID: pair.departure.id, bagCount: pair.bagCount))
                        } else if let linkIdx = arrival.outgoingLinks.firstIndex(where: { $0.outgoingFlightID == pair.departure.id }) {
                            arrival.outgoingLinks[linkIdx].bagCount = pair.bagCount
                        }
                        incomingFlights[idx] = arrival
                    }
                    // Add bag count to departure
                    if let idx = outgoingFlights.firstIndex(where: { $0.id == pair.departure.id }) {
                        let arrivalFlightNumber = pair.arrival.flightNumber
                        outgoingFlights[idx].bagsFromIncoming[arrivalFlightNumber] = pair.bagCount
                    }
                }
            }
        }
        // Apply theme
        .preferredColorScheme(appTheme == .system ? nil : (appTheme == .light ? .light : .dark))
        .sheet(item: $selectedFlightForDetails) { flight in
            IncomingFlightDetailsView(
                flight: flight,
                outgoingFlights: outgoingFlights,
                onRefresh: {
                    // Show the background web loader for this flight
                    webLoaderFlight = flight
                },
                onClose: { selectedFlightForDetails = nil }
            )
        }
        .sheet(isPresented: $showingUrgentOverlay) {
            OutgoingUrgentOverlay(
                urgentFlights: urgentFlights,
                allOutgoing: outgoingFlights,
                incomingFlights: incomingFlights,
                showAll: $showAllOutgoingInOverlay,
                onClose: { showingUrgentOverlay = false }
            )
        }
        // Add the background web loader to the view hierarchy
        .background(
            Group {
                if let flight = webLoaderFlight {
                    BackgroundWebViewLoader(
                        url: URL(string: "https://www.manchesterairport.co.uk/flight-information/arrivals/itinerary/?id=\(flight.flightNumber)-\(DateFormatter.with(format: "yyyyMMdd").string(from: flight.scheduledTime))A")!,
                        scheduledTime: flight.scheduledTime,
                        onResult: { bagTime, carousel in
                            DispatchQueue.main.async {
                                if let idx = incomingFlights.firstIndex(where: { $0.id == flight.id }) {
                                    var updated = incomingFlights[idx]
                                    updated.bagAvailableTime = bagTime
                                    updated.carousel = carousel
                                    incomingFlights[idx] = updated
                                    selectedFlightForDetails = updated
                                }
                                webLoaderFlight = nil
                            }
                        }
                    )
                }
            }
        )
    }
    
    func addOutgoingFlight(to incomingID: UUID, outgoing: OutgoingFlight, bagCount: Int) {
        var usedOutgoing = outgoing
        if let idx = outgoingFlights.firstIndex(where: { $0.flightNumber == outgoing.flightNumber && $0.scheduledTime == outgoing.scheduledTime }) {
            usedOutgoing = outgoingFlights[idx]
        } else {
            outgoingFlights.append(outgoing)
        }
        if let idx = incomingFlights.firstIndex(where: { $0.id == incomingID }) {
            var incoming = incomingFlights[idx]
            if !incoming.outgoingLinks.contains(where: { $0.outgoingFlightID == usedOutgoing.id }) {
                incoming.outgoingLinks.append(OutgoingLink(outgoingFlightID: usedOutgoing.id, bagCount: bagCount))
            }
            incomingFlights[idx] = incoming
        }
        if let idx = outgoingFlights.firstIndex(where: { $0.flightNumber == usedOutgoing.flightNumber && $0.scheduledTime == usedOutgoing.scheduledTime }) {
            let incomingFlightNumber = getFlightNumber(for: incomingID)
            if !incomingFlightNumber.isEmpty {
                outgoingFlights[idx].bagsFromIncoming[incomingFlightNumber] = bagCount
            }
        }
    }
    
    func removeOutgoingLink(incomingID: UUID, outgoingID: UUID) {
        if let idx = incomingFlights.firstIndex(where: { $0.id == incomingID }) {
            var incoming = incomingFlights[idx]
            incoming.outgoingLinks.removeAll { $0.outgoingFlightID == outgoingID }
            incomingFlights[idx] = incoming
        }
        if let idx = outgoingFlights.firstIndex(where: { $0.id == outgoingID }) {
            let incomingFlightNumber = getFlightNumber(for: incomingID)
            if !incomingFlightNumber.isEmpty {
                outgoingFlights[idx].bagsFromIncoming.removeValue(forKey: incomingFlightNumber)
            }
        }
    }

    func deleteIncomingFlight(id: UUID) {
        let flightNumber = getFlightNumber(for: id)
        incomingFlights.removeAll { $0.id == id }
        for idx in outgoingFlights.indices {
            if !flightNumber.isEmpty {
                outgoingFlights[idx].bagsFromIncoming.removeValue(forKey: flightNumber)
            }
        }
    }

    // Helper to get flightNumber from incomingID
    func getFlightNumber(for incomingID: UUID) -> String {
        incomingFlights.first(where: { $0.id == incomingID })?.flightNumber ?? ""
    }

    private var urgentFlights: [OutgoingFlight] {
        outgoingFlights.filter { outgoing in
            let totalBags = outgoing.bagsFromIncoming.values.reduce(0, +)
            if totalBags == 0 { return false }
            if outgoing.cancelled { return false }
            for (incomingFlightNumber, _) in outgoing.bagsFromIncoming {
                if let incoming = incomingFlights.first(where: { $0.flightNumber == incomingFlightNumber }),
                   incoming.actualArrivalTime != nil, !incoming.cancelled {
                    let arrTime = incoming.actualArrivalTime ?? incoming.scheduledTime
                    let depTime = outgoing.actualTime ?? outgoing.scheduledTime
                    if depTime.timeIntervalSince(arrTime) < atRiskThreshold {
                        return true
                    }
                }
            }
            return false
        }
    }
}

struct UrgentOutgoingButton: View {
    let urgentFlights: [OutgoingFlight]
    let onTap: () -> Void
    let isOverlayPresented: Bool
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: urgentFlights.isEmpty ? "airplane.departure" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(urgentFlights.isEmpty ? .blue : .white)
                    .scaleEffect(isOverlayPresented || urgentFlights.isEmpty ? 1.0 : 1.1 + 0.05 * sin(Date().timeIntervalSinceReferenceDate * 4))
                    .animation(urgentFlights.isEmpty ? .none : .easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: urgentFlights.isEmpty)
                Text(urgentFlights.isEmpty ? "Outgoing" : "Urgent")
                    .font(.headline)
                    .foregroundColor(urgentFlights.isEmpty ? .blue : .white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(urgentFlights.isEmpty ? Color(.systemGray6) : Color.red)
            .cornerRadius(16)
            .shadow(color: urgentFlights.isEmpty ? .clear : .red.opacity(0.4), radius: urgentFlights.isEmpty ? 0 : 10)
        }
        .accessibilityLabel(urgentFlights.isEmpty ? "Show Outgoing Flights" : "Show Urgent Flights")
    }
}

// 1. Move countdownString to top level
func countdownString(_ interval: TimeInterval) -> String {
    if interval < 0 { return "0 min" }
    let mins = Int(interval) / 60
    let hrs = mins / 60
    let minsOnly = mins % 60
    if hrs > 0 {
        return String(format: "%d hr %02d min", hrs, minsOnly)
    } else {
        return String(format: "%d min", minsOnly)
    }
}

// Helper to show time with S/E/A
func timeWithSuffix(for flight: IncomingFlight) -> String {
    if flight.cancelled {
        return "CANCELLED"
    } else if let actual = flight.actualArrivalTime {
        return "\(formatTime(actual)) A"
    } else if let expected = flight.expectedArrivalTime {
        return "\(formatTime(expected)) E"
    } else {
        return "\(formatTime(flight.scheduledTime)) S"
    }
}

func timeWithSuffix(for flight: OutgoingFlight) -> String {
    if flight.cancelled {
        return "CANCELLED"
    } else if let actual = flight.actualTime {
        return "\(formatTime(actual)) A"
    } else if let expected = flight.expectedTime {
        return "\(formatTime(expected)) E"
    } else {
        return "\(formatTime(flight.scheduledTime)) S"
    }
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter.string(from: date)
}

struct MainContentView: View {
    @Binding var incomingFlights: [IncomingFlight]
    @Binding var outgoingFlights: [OutgoingFlight]
    let terminals: [String]
    @Binding var expandedFlights: Set<UUID>
    @Binding var showingAddIncoming: Bool
    @Binding var showingAddOutgoingFor: IncomingFlight?
    @Binding var showingPDFPreview: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingResetAlert: Bool
    @Binding var showingLivePage: Bool
    @Binding var pdfData: Data?
    let now: Date
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    let saveData: () -> Void
    let loadData: () -> Void
    let filterForToday: () -> Void
    let addOutgoingFlight: (UUID, OutgoingFlight, Int) -> Void
    let removeOutgoingLink: (UUID, UUID) -> Void
    let deleteIncomingFlight: (UUID) -> Void
    @Binding var showingSettings: Bool
    @Binding var collapsedTerminals: Set<String>
    let showAtRiskOnly: Bool
    let aetherFlights: [String: (terminal: String, scheduledTime: Date, expectedBags: Int, status: String)]
    @Binding var selectedFlightForDetails: IncomingFlight?
    
    var body: some View {
        NavigationView {
            MainContentBody(
                incomingFlights: $incomingFlights,
                outgoingFlights: $outgoingFlights,
                terminals: terminals,
                expandedFlights: $expandedFlights,
                showingAddIncoming: $showingAddIncoming,
                showingAddOutgoingFor: $showingAddOutgoingFor,
                showingPDFPreview: $showingPDFPreview,
                showingShareSheet: $showingShareSheet,
                showingResetAlert: $showingResetAlert,
                showingLivePage: $showingLivePage,
                pdfData: $pdfData,
                showingSettings: $showingSettings,
                collapsedTerminals: $collapsedTerminals,
                removeOutgoingLink: removeOutgoingLink,
                deleteIncomingFlight: deleteIncomingFlight,
                addOutgoingFlight: addOutgoingFlight,
                showAtRiskOnly: showAtRiskOnly,
                aetherFlights: aetherFlights,
                selectedFlightForDetails: $selectedFlightForDetails
            )
        }
        .onAppear(perform: {
            loadData()
            filterForToday()
        })
        .onChange(of: incomingFlights) { _, _ in saveData() }
        .onChange(of: outgoingFlights) { _, _ in saveData() }
        .onReceive(timer) { _ in }
        .sheet(isPresented: $showingLivePage) {
            LivePageView(
                incomingFlights: incomingFlights,
                outgoingFlights: outgoingFlights,
                now: now
            )
        }
    }
}

struct MainContentBody: View {
    @Binding var incomingFlights: [IncomingFlight]
    @Binding var outgoingFlights: [OutgoingFlight]
    let terminals: [String]
    @Binding var expandedFlights: Set<UUID>
    @Binding var showingAddIncoming: Bool
    @Binding var showingAddOutgoingFor: IncomingFlight?
    @Binding var showingPDFPreview: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingResetAlert: Bool
    @Binding var showingLivePage: Bool
    @Binding var pdfData: Data?
    @Binding var showingSettings: Bool
    @Binding var collapsedTerminals: Set<String>
    let removeOutgoingLink: (UUID, UUID) -> Void
    let deleteIncomingFlight: (UUID) -> Void
    let addOutgoingFlight: (UUID, OutgoingFlight, Int) -> Void
    let showAtRiskOnly: Bool
    let aetherFlights: [String: (terminal: String, scheduledTime: Date, expectedBags: Int, status: String)]
    @Binding var selectedFlightForDetails: IncomingFlight?
    
    var body: some View {
        VStack(spacing: 0) {
            ExpandCollapseButtons(expandedFlights: $expandedFlights, incomingFlights: incomingFlights)
            FlightListView(
                terminals: terminals,
                incomingFlights: incomingFlights,
                outgoingFlights: outgoingFlights,
                expandedFlights: $expandedFlights,
                showingAddOutgoingFor: $showingAddOutgoingFor,
                removeOutgoingLink: removeOutgoingLink,
                deleteIncomingFlight: deleteIncomingFlight,
                collapsedTerminals: $collapsedTerminals,
                showAtRiskOnly: showAtRiskOnly,
                aetherFlights: aetherFlights,
                selectedFlightForDetails: $selectedFlightForDetails
            )
            Spacer(minLength: 0)
            PDFExportButton(
                incomingFlights: incomingFlights,
                outgoingFlights: outgoingFlights,
                pdfData: $pdfData,
                showingPDFPreview: $showingPDFPreview,
                showingShareSheet: $showingShareSheet
            )
        }
        .navigationTitle("")
        .toolbar { }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("Reset Day?"),
                message: Text("This will clear all incoming and outgoing flights for today. Are you sure?"),
                primaryButton: .destructive(Text("Reset")) {
                    incomingFlights = []
                    outgoingFlights = []
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingAddIncoming) {
            AddIncomingFlightView { newFlight in
                incomingFlights.append(newFlight)
            }
        }
        .sheet(item: $showingAddOutgoingFor) { incoming in
            AddOutgoingFlightView(existingFlights: outgoingFlights) { newOutgoing, bagCount in
                addOutgoingFlight(incoming.id, newOutgoing, bagCount)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        showingLivePage = true
                    }
                }
        )
    }
}

// 4. Settings sheet view
struct SettingsSheet: View {
    @Binding var appTheme: AppTheme
    var onResetDay: () -> Void
    var onClose: () -> Void
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Theme")) {
                    Picker("Theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button(role: .destructive, action: onResetDay) {
                        Label("Reset Day", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onClose() }
                }
            }
        }
    }
}

struct ExpandCollapseButtons: View {
    @Binding var expandedFlights: Set<UUID>
    let incomingFlights: [IncomingFlight]
    
    var body: some View {
        HStack {
            Button("Expand All") {
                let allIds = incomingFlights.map { $0.id }
                expandedFlights = Set(allIds)
            }
            .padding(.horizontal)
            Button("Collapse All") {
                expandedFlights = []
            }
            .padding(.horizontal)
        }
    }
}

struct FlightListView: View {
    let terminals: [String]
    let incomingFlights: [IncomingFlight]
    let outgoingFlights: [OutgoingFlight]
    @Binding var expandedFlights: Set<UUID>
    @Binding var showingAddOutgoingFor: IncomingFlight?
    let removeOutgoingLink: (UUID, UUID) -> Void
    let deleteIncomingFlight: (UUID) -> Void
    @Binding var collapsedTerminals: Set<String>
    let showAtRiskOnly: Bool
    let aetherFlights: [String: (terminal: String, scheduledTime: Date, expectedBags: Int, status: String)]
    @Binding var selectedFlightForDetails: IncomingFlight?
    
    var body: some View {
        List {
            ForEach(terminals, id: \.self) { terminal in
                let filteredFlights = incomingFlights.filter { $0.terminal == terminal }
                let displayFlights = showAtRiskOnly ? filteredFlights.filter { incoming in
                    incoming.outgoingLinks.contains { link in
                        if let out = outgoingFlights.first(where: { $0.id == link.outgoingFlightID }) {
                            let arrTime = incoming.actualArrivalTime ?? incoming.scheduledTime
                            let depTime = out.actualTime ?? out.scheduledTime
                            return depTime.timeIntervalSince(arrTime) < atRiskThreshold
                        }
                        return false
                    } || aetherFlights[incoming.flightNumber] != nil
                } : filteredFlights
                CollapsibleTerminalSection(
                    terminal: terminal,
                    incomingFlights: displayFlights,
                    outgoingFlights: outgoingFlights,
                    expandedFlights: $expandedFlights,
                    showingAddOutgoingFor: $showingAddOutgoingFor,
                    removeOutgoingLink: removeOutgoingLink,
                    deleteIncomingFlight: deleteIncomingFlight,
                    collapsedTerminals: $collapsedTerminals, 
                    showAtRiskOnly: showAtRiskOnly,
                    aetherFlights: aetherFlights,
                    selectedFlightForDetails: $selectedFlightForDetails
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
    }
}

struct PDFExportButton: View {
    let incomingFlights: [IncomingFlight]
    let outgoingFlights: [OutgoingFlight]
    @Binding var pdfData: Data?
    @Binding var showingPDFPreview: Bool
    @Binding var showingShareSheet: Bool
    
    var body: some View {
        Button(action: {
            // Fix: Generate PDF before presenting sheet
            if let data = TransferPDFExporter.generatePDF(incomingFlights: incomingFlights, outgoingFlights: outgoingFlights, reportDate: today()) {
                pdfData = data
                showingPDFPreview = true
            }
        }) {
            Text("Export to PDF")
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(.bottom)
        .sheet(isPresented: $showingPDFPreview) {
            if let data = pdfData {
                PDFPreviewView(pdfData: data) {
                    showingPDFPreview = false
                    showingShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = pdfData {
                ActivityView(activityItems: [data])
            }
        }
    }
}

struct IncomingFlightRowView: View {
    let incoming: IncomingFlight
    let outgoingFlights: [OutgoingFlight]
    let isExpanded: Bool
    var onToggleExpand: () -> Void
    var onAddOutgoing: () -> Void
    var onRemoveOutgoing: (UUID) -> Void
    var onDelete: () -> Void
    @Binding var selectedFlightForDetails: IncomingFlight?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlightHeaderView(
                incoming: incoming,
                isExpanded: isExpanded,
                onToggleExpand: onToggleExpand,
                onAddOutgoing: onAddOutgoing,
                onDelete: onDelete,
                onRefresh: nil,
                selectedFlightForDetails: $selectedFlightForDetails,
                outgoingFlights: outgoingFlights
            )
            if isExpanded {
                ExpandedFlightView(
                    incoming: incoming,
                    outgoingFlights: outgoingFlights,
                    onRemoveOutgoing: onRemoveOutgoing
                )
            } else {
                CollapsedFlightView(
                    incoming: incoming,
                    outgoingFlights: outgoingFlights
                )
            }
        }
        .padding(.vertical, 2)
    }
}

struct FlightHeaderView: View {
    let incoming: IncomingFlight
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onAddOutgoing: () -> Void
    let onDelete: () -> Void
    var onRefresh: (() -> Void)? = nil
    @Binding var selectedFlightForDetails: IncomingFlight?
    let outgoingFlights: [OutgoingFlight]
    @State private var isRefreshing = false
    
    var body: some View {
        HStack {
            Button(action: onToggleExpand) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 0 : 0))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            HStack(spacing: 4) {
                Text(incoming.flightNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(incoming.cancelled ? .gray : (isAtRisk ? .white : .primary))
                    .strikethrough(incoming.cancelled)
                    .padding(4)
                    .background(incoming.cancelled ? Color.gray.opacity(0.4) : (isAtRisk ? Color.red : Color.clear))
                    .cornerRadius(6)
                    .onTapGesture {
                        selectedFlightForDetails = incoming
                    }
                Text(incoming.terminal.uppercased())
                    .font(.subheadline).bold()
                    .foregroundColor(terminalColor(incoming.terminal))
                Text(incoming.origin)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            Spacer()
            // 2. Show time with suffix
            Text(timeWithSuffix(for: incoming))
                .font(.subheadline)
            if let onRefresh = onRefresh {
                Button(action: {
                    isRefreshing = true
                    onRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { isRefreshing = false }
                }) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Update arrival data")
            }
            Button(action: onAddOutgoing) {
                Image(systemName: "plus")
                    .font(.body)
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel("Add Outgoing Flight")
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    var isAtRisk: Bool {
        incoming.outgoingLinks.contains { link in
            if let out = outgoingFlights.first(where: { $0.id == link.outgoingFlightID }), !out.cancelled {
                let arrTime = incoming.actualArrivalTime ?? incoming.scheduledTime
                let depTime = out.actualTime ?? out.scheduledTime
                return depTime.timeIntervalSince(arrTime) < atRiskThreshold
            }
            return false
        }
    }
}

struct ExpandedFlightView: View {
    let incoming: IncomingFlight
    let outgoingFlights: [OutgoingFlight]
    let onRemoveOutgoing: (UUID) -> Void
    
    var body: some View {
        let sortedLinks = incoming.outgoingLinks.sorted { lhs, rhs in
            let lhsFlight = outgoingFlights.first { $0.id == lhs.outgoingFlightID }
            let rhsFlight = outgoingFlights.first { $0.id == rhs.outgoingFlightID }
            return (lhsFlight?.scheduledTime ?? .distantFuture) < (rhsFlight?.scheduledTime ?? .distantFuture)
        }
        let outgoingLinks = sortedLinks.enumerated().map { (index, link) in
            (index, link, outgoingFlights.first(where: { $0.id == link.outgoingFlightID }))
        }
        
        ForEach(outgoingLinks, id: \.1.id) { (index, link, outgoing) in
            if let outgoing = outgoing {
                OutgoingFlightRowView(
                    index: index,
                    link: link,
                    outgoing: outgoing,
                    incomingFlightNumber: incoming.flightNumber,
                    onRemoveOutgoing: onRemoveOutgoing
                )
            }
        }
    }
}

struct OutgoingFlightRowView: View {
    let index: Int
    let link: OutgoingLink
    let outgoing: OutgoingFlight
    let incomingFlightNumber: String
    let onRemoveOutgoing: (UUID) -> Void
    
    var body: some View {
        HStack {
            Text("\(index + 1).")
                .frame(width: 24, alignment: .trailing)
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(outgoing.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(outgoing.terminal.uppercased())
                        .font(.subheadline).bold()
                        .foregroundColor(terminalColor(outgoing.terminal))
                    Text(outgoing.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 24)
            }
            Spacer()
            Text(timeWithSuffix(for: outgoing))
                .font(.caption)
                .frame(width: 60)
            // Use OutgoingLink's bagCount directly
            Text("\(link.bagCount)")
                .frame(width: 40)
            Rectangle()
                .frame(width: 60, height: 24)
                .foregroundColor(.clear)
                .overlay(Text(" ").font(.caption))
            Button(action: { onRemoveOutgoing(outgoing.id) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 2)
    }
}

struct CollapsedFlightView: View {
    let incoming: IncomingFlight
    let outgoingFlights: [OutgoingFlight]
    
    var body: some View {
        let bagTotal = incoming.outgoingLinks.reduce(0) { $0 + $1.bagCount }
        let earliestTime = incoming.outgoingLinks.compactMap { link in
            outgoingFlights.first(where: { $0.id == link.outgoingFlightID })?.scheduledTime
        }.min()
        
        HStack(spacing: 16) {
            Text("Bags: \(bagTotal)")
                .font(.caption)
            if let earliest = earliestTime {
                Text("Earliest: \(earliest, style: .time)")
                    .font(.caption)
            }
        }
        .padding(.leading, 32)
        .padding(.vertical, 2)
    }
}

struct AddIncomingFlightView: View {
    @Environment(\.dismiss) var dismiss
    @State private var flightNumber = ""
    @State private var terminal = ""
    @State private var origin = ""
    @State private var scheduledTime = Date()
    @State private var notes = ""
    var prefill: IncomingFlight? = nil
    var onAdd: (IncomingFlight) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Flight Number", text: Binding(
                    get: { flightNumber },
                    set: { flightNumber = $0.uppercased() }
                ))
                TextField("Terminal (1, 2, or 3)", text: Binding(
                    get: { terminal },
                    set: { terminal = $0.uppercased() }
                ))
                TextField("Origin", text: Binding(
                    get: { origin },
                    set: { origin = $0.uppercased() }
                ))
                DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    .colorScheme(.light)
                TextField("Notes", text: Binding(
                    get: { notes },
                    set: { notes = $0.uppercased() }
                ))
            }
            .navigationTitle("Add Incoming Flight")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newFlight = IncomingFlight(flightNumber: flightNumber, terminal: terminal, origin: origin, scheduledTime: scheduledTime, notes: notes, date: today())
                        onAdd(newFlight)
                        dismiss()
                    }
                    .disabled(flightNumber.isEmpty || terminal.isEmpty || origin.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let prefill = prefill {
                flightNumber = prefill.flightNumber
                terminal = prefill.terminal
                origin = prefill.origin
                scheduledTime = prefill.scheduledTime
                notes = prefill.notes
            }
        }
    }
}

struct AddOutgoingFlightView: View {
    @Environment(\.dismiss) var dismiss
    @State private var flightNumber = ""
    @State private var terminal = ""
    @State private var destination = ""
    @State private var scheduledTime = Date()
    @State private var bagCount = ""
    var existingFlights: [OutgoingFlight]
    var onAdd: (OutgoingFlight, Int) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Flight Number", text: Binding(
                    get: { flightNumber },
                    set: { flightNumber = $0.uppercased() }
                ))
                TextField("Terminal (1, 2, or 3)", text: Binding(
                    get: { terminal },
                    set: { terminal = $0.uppercased() }
                ))
                TextField("Destination", text: Binding(
                    get: { destination },
                    set: { destination = $0.uppercased() }
                ))
                DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    .colorScheme(.light)
                TextField("Bag Count", text: $bagCount)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Add Outgoing Flight")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let outgoing = OutgoingFlight(flightNumber: flightNumber, terminal: terminal, destination: destination, scheduledTime: scheduledTime)
                        onAdd(outgoing, Int(bagCount) ?? 0)
                        dismiss()
                    }
                    .disabled(flightNumber.isEmpty || terminal.isEmpty || destination.isEmpty || Int(bagCount) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 

// UIKit wrapper for share sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 

struct PDFPreviewView: View {
    let pdfData: Data
    var onShare: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            PDFKitRepresentedView(data: pdfData)
                .edgesIgnoringSafeArea(.all)
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share/Email PDF")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
            }
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let data: Data
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    func updateUIView(_ pdfView: PDFView, context: Context) {}
} 

struct LivePageView: View {
    let incomingFlights: [IncomingFlight]
    let outgoingFlights: [OutgoingFlight]
    let now: Date
    @Environment(\.dismiss) var dismiss
    
    var filteredOutgoingFlights: [OutgoingFlight] {
        outgoingFlights
            .filter { outgoing in
                let totalBags = outgoing.bagsFromIncoming.values.reduce(0, +)
                return totalBags > 0
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    var nextPriorityFlight: OutgoingFlight? {
        return filteredOutgoingFlights.first { $0.scheduledTime > now }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let nextFlight = nextPriorityFlight {
                    PriorityFlightView(
                        nextFlight: nextFlight,
                        incomingFlights: incomingFlights,
                        now: now
                    )
                }
                
                List {
                    ForEach(filteredOutgoingFlights) { outgoing in
                        LiveFlightRowView(
                            outgoing: outgoing,
                            incomingFlights: incomingFlights,
                            now: now
                        )
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Live Outgoing Flights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PriorityFlightView: View {
    let nextFlight: OutgoingFlight
    let incomingFlights: [IncomingFlight]
    let now: Date
    
    var body: some View {
        let totalBags = nextFlight.bagsFromIncoming.values.reduce(0, +)
        let associatedIncomings = nextFlight.bagsFromIncoming.keys.compactMap { flightNumber in
            incomingFlights.first(where: { $0.flightNumber == flightNumber })
        }
        let timeToDeparture = nextFlight.scheduledTime.timeIntervalSince(now)
        let countdownColor: Color = timeToDeparture < 40*60 ? .red : (timeToDeparture < 60*60 ? .orange : .primary)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(countdownColor)
                Text("NEXT PRIORITY")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(countdownString(timeToDeparture))
                    .font(.headline)
                    .foregroundColor(countdownColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(countdownColor.opacity(0.2)))
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(nextFlight.flightNumber)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Terminal \(nextFlight.terminal)")
                        .font(.subheadline)
                    Text("To: \(nextFlight.destination)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(nextFlight.scheduledTime, style: .time)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("\(totalBags) bags")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if !associatedIncomings.isEmpty {
                Text("Bags from:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(associatedIncomings, id: \.flightNumber) { incoming in
                    let bagCount = nextFlight.bagsFromIncoming[incoming.flightNumber] ?? 0
                    HStack {
                        Text("• \(incoming.flightNumber) (\(incoming.origin))")
                            .font(.caption)
                        Spacer()
                        Text("\(bagCount) bags")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(countdownColor.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(countdownColor, lineWidth: 2))
        .padding(.horizontal)
        .padding(.top)
    }
    
    func countdownString(_ interval: TimeInterval) -> String {
        if interval < 0 { return "0 min" }
        let mins = Int(interval) / 60
        let hrs = mins / 60
        let minsOnly = mins % 60
        if hrs > 0 {
            return String(format: "%d hr %02d min", hrs, minsOnly)
        } else {
            return String(format: "%d min", minsOnly)
        }
    }
}

struct LiveFlightRowView: View {
    let outgoing: OutgoingFlight
    let incomingFlights: [IncomingFlight]
    let now: Date
    @State private var isUpdating = false // New state variable
    
    var body: some View {
        let timeToDeparture = outgoing.scheduledTime.timeIntervalSince(now)
        let isDeparted = outgoing.scheduledTime < now
        let countdownColor: Color = isDeparted ? .gray : (timeToDeparture < 40*60 ? .red : (timeToDeparture < 60*60 ? .orange : .primary))
        let totalBags = outgoing.bagsFromIncoming.values.reduce(0, +)
        let associatedIncomings = outgoing.bagsFromIncoming.keys.compactMap { flightNumber in
            incomingFlights.first(where: { $0.flightNumber == flightNumber })
        }
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(outgoing.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Terminal \(outgoing.terminal)")
                        .font(.subheadline)
                    Text("To: \(outgoing.destination)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(timeWithSuffix(for: outgoing))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isDeparted ? .gray : countdownColor)
                    if !isDeparted {
                        Text(countdownString(timeToDeparture))
                            .font(.caption)
                            .foregroundColor(countdownColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(countdownColor.opacity(0.2)))
                    } else {
                        Text("DEPARTED")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text("\(totalBags) bags")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    // 3. Refresh icon
                    Button(action: { updateFlightData() }) {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Update flight data")
                }
            }
            
            if !associatedIncomings.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ForEach(associatedIncomings, id: \.flightNumber) { incoming in
                        let bagCount = outgoing.bagsFromIncoming[incoming.flightNumber] ?? 0
                        HStack {
                            Text("• \(incoming.flightNumber) (\(incoming.origin))")
                                .font(.caption)
                            Spacer()
                            Text("\(bagCount) bags")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 2)
        .background(isDeparted ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    func updateFlightData() {
        isUpdating = true
        // In a real app, you would fetch fresh data from the web or API
        // For now, we'll just simulate a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isUpdating = false
        }
    }
    
    func countdownString(_ interval: TimeInterval) -> String {
        if interval < 0 { return "0 min" }
        let mins = Int(interval) / 60
        let hrs = mins / 60
        let minsOnly = mins % 60
        if hrs > 0 {
            return String(format: "%d hr %02d min", hrs, minsOnly)
        } else {
            return String(format: "%d min", minsOnly)
        }
    }
} 

// Add a new UIViewControllerRepresentable for the web import
struct ManchesterWebImportView: UIViewControllerRepresentable {
    let url: URL
    var onFlightImported: (IncomingFlight) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFlightImported: onFlightImported)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let js = """
        (function() {
          // Add CSS for hover highlight
          var style = document.createElement('style');
          style.innerHTML = '.__flight_hover { background: #ffe066 !important; cursor: pointer !important; }';
          document.head.appendChild(style);

          function extractAndSend(row) {
            const schedTime = row.querySelector('span[style*="width: 80px"]')?.innerText;
            const actualTime = row.querySelector('span[class*="status-time"]')?.innerText || null;
            const origin = row.querySelector('span[class*="ss8qoa8"]')?.innerText;
            const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText;
            const airline = row.querySelector('span[class*="w6c5ku"]')?.innerText;
            const terminal = row.querySelector('td:nth-child(3)')?.innerText;
            const status = row.querySelector('td:last-child')?.innerText;
            const expectedTime = row.querySelector('span[class*="expected"]')?.innerText || null;
            const cancelled = row.querySelector('span[class*="cancelled"]')?.innerText === 'Cancelled';
            const flightData = {
              scheduled_time: schedTime,
              actual_time: actualTime,
              expected_time: expectedTime,
              cancelled: cancelled,
              origin: origin,
              flight_number: flightNumber,
              airline: airline,
              terminal: terminal,
              status: status
            };
            window.webkit?.messageHandlers?.flightData?.postMessage(flightData);
          }

          function attachHandlers() {
            document.querySelectorAll('tr').forEach(row => {
              if (!row.__hasFlightHandler) {
                row.addEventListener('mouseenter', function() {
                  row.classList.add('__flight_hover');
                });
                row.addEventListener('mouseleave', function() {
                  row.classList.remove('__flight_hover');
                });
                row.addEventListener('click', function(event) {
                  const flightNumber = row.querySelector('span[class*=\"vwba0x\"]')?.innerText;
                  if (!flightNumber || flightNumber.trim() === '') return; // Let site handle navigation rows
                  event.stopPropagation();
                  event.preventDefault();
                  extractAndSend(row);
                }, true);
                row.__hasFlightHandler = true;
              }
            });
          }

          // Initial attach
          attachHandlers();

          // Observe for new rows
          const observer = new MutationObserver(attachHandlers);
          observer.observe(document.body, { childList: true, subtree: true });
        })();
        """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(context.coordinator, name: "flightData")
        let vc = UIViewController()
        webView.frame = vc.view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(webView)
        webView.load(URLRequest(url: url))
        context.coordinator.webView = webView
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onFlightImported: (IncomingFlight) -> Void
        weak var webView: WKWebView?

        init(onFlightImported: @escaping (IncomingFlight) -> Void) {
            self.onFlightImported = onFlightImported
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "flightData", let dict = message.body as? [String: Any] {
                let statusLabel = (dict["status_label"] as? String ?? dict["status"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let isCancelled = statusLabel.lowercased().contains("cancelled")
                let flight = IncomingFlight(
                    flightNumber: dict["flight_number"] as? String ?? "",
                    terminal: dict["terminal"] as? String ?? "",
                    origin: dict["origin"] as? String ?? "",
                    scheduledTime: parseTime(dict["scheduled_time"] as? String) ?? today(),
                    actualArrivalTime: parseTime(dict["actual_time"] as? String),
                    expectedArrivalTime: parseTime(dict["expected_time"] as? String),
                    notes: statusLabel,
                    cancelled: isCancelled,
                    date: today()
                )
                onFlightImported(flight)
            }
        }

        func parseTime(_ timeString: String?) -> Date? {
            guard let timeString = timeString, !timeString.isEmpty else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let today = Calendar.current.startOfDay(for: Date())
            if let time = formatter.date(from: timeString) {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: time)
                let minute = calendar.component(.minute, from: time)
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
            }
            return nil
        }
    }
} 

// Import Sheet with TabView (Arrivals and Departures)
struct ArrivalsImportSheet: View {
    @Binding var arrivalsImportList: [IncomingFlight]
    @Binding var departuresImportList: [OutgoingFlight]
    @Binding var selectedDeparture: OutgoingFlight?
    @Binding var bagCountsForPanel: [UUID: Int]
    var allArrivals: [IncomingFlight]
    var onSaveDepartureBags: (OutgoingFlight, [UUID: Int]) -> Void
    var onDone: () -> Void
    @State private var selectedTab = 0
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    Picker("Import Type", selection: $selectedTab) {
                        Text("Arrivals").tag(0)
                        Text("Departures").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.top, .horizontal])
                    Divider()
                    if selectedTab == 0 {
                        ArrivalsWebImportView(arrivalsImportList: $arrivalsImportList)
                    } else {
                        DeparturesWebImportView(
                            departuresImportList: $departuresImportList
                        )
                    }
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Selected Arrivals:")
                            .font(.headline)
                            .padding(.top, 8)
                        if arrivalsImportList.isEmpty {
                            Text("No arrivals selected yet.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            List {
                                ForEach(arrivalsImportList, id: \ .id) { flight in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            HStack(spacing: 4) {
                                                Text(flight.flightNumber)
                                                Text(flight.terminal.uppercased())
                                                    .font(.subheadline).bold()
                                                    .foregroundColor(terminalColor(flight.terminal))
                                            }
                                            Text(flight.origin)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(flight.scheduledTime, style: .time)
                                                .font(.caption2)
                                        }
                                        Spacer()
                                        Button(action: {
                                            if let idx = arrivalsImportList.firstIndex(of: flight) {
                                                arrivalsImportList.remove(at: idx)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    .padding(.horizontal)
                    VStack(alignment: .leading) {
                        Text("Selected Departures:")
                            .font(.headline)
                            .padding(.top, 8)
                        if departuresImportList.isEmpty {
                            Text("No departures selected yet.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            List {
                                ForEach(departuresImportList, id: \ .id) { flight in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            HStack(spacing: 4) {
                                                Text(flight.flightNumber)
                                                Text(flight.terminal.uppercased())
                                                    .font(.subheadline).bold()
                                                    .foregroundColor(terminalColor(flight.terminal))
                                            }
                                            Text(flight.destination)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(flight.scheduledTime, style: .time)
                                                .font(.caption2)
                                        }
                                        Spacer()
                                        Button(action: {
                                            if let idx = departuresImportList.firstIndex(of: flight) {
                                                departuresImportList.remove(at: idx)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                    Button("Done") {
                        onDone()
                    }
                    .font(.headline)
                    .padding()
                }
                .navigationTitle("Import Flights")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// Arrivals Web Import View (wraps ManchesterWebImportView)
struct ArrivalsWebImportView: View {
    @Binding var arrivalsImportList: [IncomingFlight]
    var body: some View {
        ManchesterWebImportView(
            url: URL(string: "https://www.manchesterairport.co.uk/flight-information/arrivals/")!,
            onFlightImported: { flight in
                // Only add if not already in the list (by flight number, terminal, and scheduled time)
                if !arrivalsImportList.contains(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 }) {
                    arrivalsImportList.append(flight)
                }
            }
        )
    }
}

// Departures Web Import View
struct DeparturesWebImportView: View {
    @Binding var departuresImportList: [OutgoingFlight]
    var body: some View {
        ManchesterDeparturesWebImportView(
            onFlightImported: { flight in
                // Only add if not already in the list (by flight number, terminal, and scheduled time)
                if !departuresImportList.contains(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 }) {
                    departuresImportList.append(flight)
                }
            },
            selectedDeparture: nil
        )
    }
}

// Bottom panel for bag entry
struct DepartureBagPanel: View {
    let departure: OutgoingFlight
    let arrivals: [IncomingFlight]
    @Binding var bagCounts: [UUID: Int] // Use flightNumber as key
    var onSave: () -> Void
    var onCancel: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Capsule().frame(width: 40, height: 6).foregroundColor(.gray.opacity(0.3)).padding(.top, 8)
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text("Departure: ")
                        Text(departure.flightNumber).bold()
                        Text(departure.terminal.uppercased())
                            .font(.subheadline).bold()
                            .foregroundColor(terminalColor(departure.terminal))
                    }
                    Text(departure.destination)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(departure.scheduledTime, style: .time)
                        .font(.caption2)
                }
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Bags from Arrivals:").font(.headline)
                if arrivals.isEmpty {
                    Text("No arrivals available to transfer from.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(arrivals.sorted(by: { $0.scheduledTime < $1.scheduledTime }), id: \ .id) { arrival in
                                HStack(spacing: 8) {
                                    Text(arrival.flightNumber)
                                        .font(.subheadline).bold()
                                    Text(arrival.terminal.uppercased())
                                        .font(.subheadline).bold()
                                        .foregroundColor(terminalColor(arrival.terminal))
                                    Text(arrival.scheduledTime, style: .time)
                                        .font(.caption)
                                    Spacer()
                                    Stepper(value: Binding(
                                        get: { bagCounts[arrival.id] ?? 0 },
                                        set: { bagCounts[arrival.id] = $0 }
                                    ), in: 0...999) {
                                        Text("\(bagCounts[arrival.id] ?? 0)")
                                            .frame(width: 32)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(minHeight: 120, maxHeight: 260)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .animation(.default, value: arrivals.count)
            Button("Save") {
                onSave()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// Manchester Departures Web Import View (like ManchesterWebImportView but for departures)
struct ManchesterDeparturesWebImportView: UIViewControllerRepresentable {
    var onFlightImported: (OutgoingFlight) -> Void
    var selectedDeparture: OutgoingFlight?

    func makeCoordinator() -> Coordinator {
        Coordinator(onFlightImported: onFlightImported)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let js = """
        (function() {
          // Add CSS for hover highlight (blue for departures)
          var style = document.createElement('style');
          style.innerHTML = '.__flight_hover_departure { background: #cce3ff !important; cursor: pointer !important; }';
          document.head.appendChild(style);

          function extractAndSend(row) {
            const schedTime = row.querySelector('span[style*="width: 80px"]')?.innerText;
            const actualTime = row.querySelector('span[class*="status-time"]')?.innerText || null;
            const destination = row.querySelector('span[class*="ss8qoa8"]')?.innerText;
            const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText;
            const airline = row.querySelector('span[class*="w6c5ku"]')?.innerText;
            const terminal = row.querySelector('td:nth-child(3)')?.innerText;
            const status = row.querySelector('td:last-child')?.innerText;
            const flightData = {
              scheduled_time: schedTime,
              actual_time: actualTime,
              destination: destination,
              flight_number: flightNumber,
              airline: airline,
              terminal: terminal,
              status: status
            };
            window.webkit?.messageHandlers?.flightData?.postMessage(flightData);
          }

          function attachHandlers() {
            document.querySelectorAll('tr').forEach(row => {
              if (!row.__hasFlightHandlerDeparture) {
                row.addEventListener('mouseenter', function() {
                  row.classList.add('__flight_hover_departure');
                });
                row.addEventListener('mouseleave', function() {
                  row.classList.remove('__flight_hover_departure');
                });
                row.addEventListener('click', function(event) {
                  const flightNumber = row.querySelector('span[class*=\"vwba0x\"]')?.innerText;
                  if (!flightNumber || flightNumber.trim() === '') return; // Let site handle navigation rows
                  event.stopPropagation();
                  event.preventDefault();
                  extractAndSend(row);
                }, true);
                row.__hasFlightHandlerDeparture = true;
              }
            });
          }

          // Initial attach
          attachHandlers();

          // Observe for new rows
          const observer = new MutationObserver(attachHandlers);
          observer.observe(document.body, { childList: true, subtree: true });
        })();
        """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(context.coordinator, name: "flightData")
        let vc = UIViewController()
        webView.frame = vc.view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(webView)
        webView.load(URLRequest(url: URL(string: "https://www.manchesterairport.co.uk/flight-information/departures/")!))
        context.coordinator.webView = webView
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onFlightImported: (OutgoingFlight) -> Void
        weak var webView: WKWebView?

        init(onFlightImported: @escaping (OutgoingFlight) -> Void) {
            self.onFlightImported = onFlightImported
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "flightData", let dict = message.body as? [String: Any] {
                let statusLabel = (dict["status_label"] as? String ?? dict["status"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let isCancelled = statusLabel.lowercased().contains("cancelled")
                let flight = OutgoingFlight(
                    flightNumber: dict["flight_number"] as? String ?? "",
                    terminal: dict["terminal"] as? String ?? "",
                    destination: dict["destination"] as? String ?? "",
                    scheduledTime: parseTime(dict["scheduled_time"] as? String) ?? today(),
                    actualTime: parseTime(dict["actual_time"] as? String),
                    expectedTime: nil, // Add if available
                    cancelled: isCancelled
                )
                onFlightImported(flight)
            }
        }

        func parseTime(_ timeString: String?) -> Date? {
            guard let timeString = timeString, !timeString.isEmpty else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let today = Calendar.current.startOfDay(for: Date())
            if let time = formatter.date(from: timeString) {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: time)
                let minute = calendar.component(.minute, from: time)
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
            }
            return nil
        }
    }
} 

// Collapsible terminal section
struct CollapsibleTerminalSection: View {
    let terminal: String
    let incomingFlights: [IncomingFlight]
    let outgoingFlights: [OutgoingFlight]
    @Binding var expandedFlights: Set<UUID>
    @Binding var showingAddOutgoingFor: IncomingFlight?
    let removeOutgoingLink: (UUID, UUID) -> Void
    let deleteIncomingFlight: (UUID) -> Void
    @Binding var collapsedTerminals: Set<String>
    let showAtRiskOnly: Bool
    let aetherFlights: [String: (terminal: String, scheduledTime: Date, expectedBags: Int, status: String)]
    @Binding var selectedFlightForDetails: IncomingFlight?
    
    var isCollapsed: Bool {
        collapsedTerminals.contains(terminal)
    }
    
    var body: some View {
        Section(header:
            VStack(spacing: 0) {
                Button(action: {
                    if isCollapsed {
                        collapsedTerminals.remove(terminal)
                    } else {
                        collapsedTerminals.insert(terminal)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Terminal \(terminal)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        if isCollapsed && !incomingFlights.isEmpty {
                            Text("(\(incomingFlights.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 2)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 0)
        ) {
            if !isCollapsed {
                ForEach(incomingFlights) { incoming in
                    IncomingFlightRowView(
                        incoming: incoming,
                        outgoingFlights: outgoingFlights,
                        isExpanded: expandedFlights.contains(incoming.id),
                        onToggleExpand: {
                            if expandedFlights.contains(incoming.id) {
                                expandedFlights.remove(incoming.id)
                            } else {
                                expandedFlights.insert(incoming.id)
                            }
                        },
                        onAddOutgoing: { showingAddOutgoingFor = incoming },
                        onRemoveOutgoing: { outgoingID in removeOutgoingLink(incoming.id, outgoingID) },
                        onDelete: { deleteIncomingFlight(incoming.id) },
                        selectedFlightForDetails: $selectedFlightForDetails
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
        }
        .headerProminence(.standard)
    } 
}

struct IncomingFlightDetailsView: View {
    let flight: IncomingFlight
    let outgoingFlights: [OutgoingFlight]
    var onRefresh: () -> Void
    var onClose: () -> Void
    @State private var isRefreshing = false
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(flight.flightNumber)
                    .font(.largeTitle).bold()
                Text(flight.terminal.uppercased())
                    .font(.title2).bold()
                    .foregroundColor(terminalColor(flight.terminal))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(.secondary)
                }
            }
            Text(flight.origin)
                .font(.title3)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Label(timeWithSuffix(for: flight), systemImage: "clock")
                    .font(.title2)
                if isRefreshing {
                    ProgressView()
                } else {
                    Button(action: {
                        isRefreshing = true
                        onRefresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { isRefreshing = false }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Update arrival data")
                }
            }
            // NEW: Bag available time and carousel
            if let bagTime = flight.bagAvailableTime {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.blue)
                    Text("Bags available: \(formatTime(bagTime))")
                        .font(.headline)
                }
            }
            if let carousel = flight.carousel, !carousel.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "suitcase")
                        .foregroundColor(.orange)
                    Text("Carousel: \(carousel)")
                        .font(.headline)
                }
            }
            if flight.cancelled {
                Text("CANCELLED")
                    .font(.title2).bold()
                    .foregroundColor(.red)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Bag Connections:").font(.headline)
                ForEach(flight.outgoingLinks, id: \.id) { link in
                    if let out = outgoingFlights.first(where: { $0.id == link.outgoingFlightID }) {
                        HStack {
                            Text("\(out.flightNumber) → \(out.destination)")
                                .font(.body)
                            Spacer()
                            Text("\(link.bagCount) bags")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
        .padding(32)
    }
}

// 6. Implement OutgoingUrgentOverlay
struct OutgoingUrgentOverlay: View {
    let urgentFlights: [OutgoingFlight]
    let allOutgoing: [OutgoingFlight]
    let incomingFlights: [IncomingFlight]
    @Binding var showAll: Bool
    var onClose: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "airplane.departure").foregroundColor(.blue)
                Text(showAll || urgentFlights.isEmpty ? "All Outgoing Flights" : "Urgent Flights")
                    .font(.title2).bold()
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(.secondary)
                }
            }
            .padding()
            if !urgentFlights.isEmpty {
                Toggle("Show All Outgoing", isOn: $showAll)
                    .padding(.horizontal)
            }
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach((showAll || urgentFlights.isEmpty ? allOutgoing.sorted(by: { ($0.actualTime ?? $0.scheduledTime) < ($1.actualTime ?? $1.scheduledTime) }) : urgentFlights), id: \.id) { flight in
                        HStack(spacing: 8) {
                            Image(systemName: "airplane.departure").foregroundColor(.blue)
                            Text(flight.flightNumber)
                                .font(.headline).bold()
                            Text(flight.terminal.uppercased())
                                .font(.subheadline).bold()
                                .foregroundColor(terminalColor(flight.terminal))
                            Text(flight.destination)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(timeWithSuffix(for: flight))
                                .font(.subheadline)
                                .foregroundColor(flight.cancelled ? .red : .primary)
                        }
                        .padding(10)
                        .background(flight.cancelled ? Color.gray.opacity(0.2) : Color.blue.opacity(0.07))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
        .padding(24)
    }
}

// Helper: Fetch and parse collect time and carousel from the Arriving passenger section
func fetchBagAvailableTimeAndCarousel(flightNumber: String, scheduledTime: Date, completion: @escaping (Date?, String?) -> Void) {
    // Try multiple dates to handle overnight flights
    let calendar = Calendar.current
    let scheduledDate = scheduledTime
    let previousDate = calendar.date(byAdding: .day, value: -1, to: scheduledDate) ?? scheduledDate
    let nextDate = calendar.date(byAdding: .day, value: 1, to: scheduledDate) ?? scheduledDate
    
    let datesToTry = [scheduledDate, previousDate, nextDate]
    
    func tryDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        let urlString = "https://www.manchesterairport.co.uk/flight-information/arrivals/itinerary/?id=\(flightNumber)-\(dateString)A"
        print("[DEBUG] Trying date: \(dateString) - URL: \(urlString)")
        guard let url = URL(string: urlString) else { 
            print("[DEBUG] Invalid URL for date: \(dateString)")
            tryNextDate()
            return 
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { 
                print("[DEBUG] No data or HTML for date: \(dateString)")
                tryNextDate()
                return 
            }
            // --- DIAGNOSTIC: Print first 1000 chars of HTML ---
            print("[DEBUG] HTML preview for date \(dateString):\n" + html.prefix(1000))
            do {
                let doc = try SwiftSoup.parse(html)
                // --- DIAGNOSTIC: Print all <p> tags and their text ---
                let allPs = try doc.select("p")
                print("[DEBUG] All <p> tags for date \(dateString):")
                for p in allPs.array() {
                    print("[DEBUG] <p>: \(try? p.text() ?? "nil")")
                }
                // Find the <h3> with 'Arriving passenger'
                guard let arrivingHeader = try? doc.select("h3:matchesOwn(^Arriving passenger$)").first() else {
                    print("[DEBUG] No 'Arriving passenger' header found for date: \(dateString)")
                    tryNextDate()
                    return
                }
                // Get the parent container
                guard let parentContainer = try? arrivingHeader.parent() else {
                    print("[DEBUG] No parent container for 'Arriving passenger' header for date: \(dateString)")
                    tryNextDate()
                    return
                }
                // Search all descendants for 'Collect your luggage'
                let collectPs = try? parentContainer.select("*:contains(Collect your luggage)")
                print("[DEBUG] Found \(collectPs?.array().count ?? 0) elements containing 'Collect your luggage' in parentContainer for date: \(dateString)")
                if let timelineText = try? parentContainer.text() {
                    print("[DEBUG] parentContainer text: \(timelineText)")
                }
                var found = false
                for collectP in collectPs?.array() ?? [] {
                    print("[DEBUG] Processing element: \(collectP.tagName()) with text: \(try? collectP.text() ?? "nil")")
                    guard let parentDiv = try? collectP.parent() else { continue }
                    // Find the closest preceding <b> for the time
                    var timeText: String? = nil
                    if let grandParent = try? parentDiv.parent() {
                        let siblings = grandParent.getChildNodes()
                        var foundSibling = false
                        for node in siblings {
                            if let elem = node as? Element, elem == parentDiv {
                                foundSibling = true
                                break
                            }
                            if let elem = node as? Element, elem.tagName() == "b" {
                                timeText = (try? elem.text())
                            }
                        }
                        if !foundSibling { timeText = nil }
                    }
                    print("[DEBUG] timeText: \(String(describing: timeText))")
                    // Find the next sibling div for the carousel
                    var carouselText: String? = nil
                    if let nextDiv = try? parentDiv.nextElementSibling() {
                        carouselText = (try? nextDiv.text())
                    }
                    print("[DEBUG] carouselText: \(String(describing: carouselText))")
                    // Parse time (e.g., 23:41*)
                    var bagTime: Date? = nil
                    if let tText = timeText {
                        let timeRegex = try NSRegularExpression(pattern: "(\\d{2}:\\d{2})", options: [])
                        let timeMatch = timeRegex.firstMatch(in: tText, options: [], range: NSRange(location: 0, length: tText.utf16.count))
                        if let match = timeMatch, let range = Range(match.range(at: 1), in: tText) {
                            let timeStr = String(tText[range])
                            let timeFormatter = DateFormatter()
                            timeFormatter.dateFormat = "HH:mm"
                            if let t = timeFormatter.date(from: timeStr) {
                                let calendar = Calendar.current
                                let hour = calendar.component(.hour, from: t)
                                let minute = calendar.component(.minute, from: t)
                                bagTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledTime)
                            }
                        }
                    }
                    // Parse carousel (e.g., "Carousel 14" or "Carousel 04")
                    var carousel: String? = nil
                    if let cText = carouselText {
                        let carouselRegex = try NSRegularExpression(pattern: "Carousel\\s*0*(\\d+)", options: .caseInsensitive)
                        let carouselMatch = carouselRegex.firstMatch(in: cText, options: [], range: NSRange(location: 0, length: cText.utf16.count))
                        if let match = carouselMatch, let range = Range(match.range(at: 1), in: cText) {
                            carousel = String(cText[range])
                        }
                    }
                    print("[DEBUG] Parsed bagTime: \(String(describing: bagTime)), carousel: \(String(describing: carousel))")
                    completion(bagTime, carousel)
                    found = true
                    return
                }
                if !found {
                    // Fallback: search the whole document for 'Collect your luggage' and check if it's after the header
                    let allCollectPs = try? doc.select("*:contains(Collect your luggage)")
                    print("[DEBUG] Fallback: Found \(allCollectPs?.array().count ?? 0) elements containing 'Collect your luggage' in whole doc for date: \(dateString)")
                    for collectP in allCollectPs?.array() ?? [] {
                        // Check if this element is after the arrivingHeader in the DOM
                        if let headerIndex = try? arrivingHeader.elementSiblingIndex(),
                           let collectIndex = try? collectP.elementSiblingIndex(),
                           collectIndex > headerIndex {
                            print("[DEBUG] Fallback: Processing element after header: \(collectP.tagName()) with text: \(try? collectP.text() ?? "nil")")
                            guard let parentDiv = try? collectP.parent() else { continue }
                            // Find the closest preceding <b> for the time
                            var timeText: String? = nil
                            if let grandParent = try? parentDiv.parent() {
                                let siblings = grandParent.getChildNodes()
                                var foundSibling = false
                                for node in siblings {
                                    if let elem = node as? Element, elem == parentDiv {
                                        foundSibling = true
                                        break
                                    }
                                    if let elem = node as? Element, elem.tagName() == "b" {
                                        timeText = (try? elem.text())
                                    }
                                }
                                if !foundSibling { timeText = nil }
                            }
                            print("[DEBUG] timeText: \(String(describing: timeText))")
                            // Find the next sibling div for the carousel
                            var carouselText: String? = nil
                            if let nextDiv = try? parentDiv.nextElementSibling() {
                                carouselText = (try? nextDiv.text())
                            }
                            print("[DEBUG] carouselText: \(String(describing: carouselText))")
                            // Parse time (e.g., 23:41*)
                            var bagTime: Date? = nil
                            if let tText = timeText {
                                let timeRegex = try NSRegularExpression(pattern: "(\\d{2}:\\d{2})", options: [])
                                let timeMatch = timeRegex.firstMatch(in: tText, options: [], range: NSRange(location: 0, length: tText.utf16.count))
                                if let match = timeMatch, let range = Range(match.range(at: 1), in: tText) {
                                    let timeStr = String(tText[range])
                                    let timeFormatter = DateFormatter()
                                    timeFormatter.dateFormat = "HH:mm"
                                    if let t = timeFormatter.date(from: timeStr) {
                                        let calendar = Calendar.current
                                        let hour = calendar.component(.hour, from: t)
                                        let minute = calendar.component(.minute, from: t)
                                        bagTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledTime)
                                    }
                                }
                            }
                            // Parse carousel (e.g., "Carousel 14" or "Carousel 04")
                            var carousel: String? = nil
                            if let cText = carouselText {
                                let carouselRegex = try NSRegularExpression(pattern: "Carousel\\s*0*(\\d+)", options: .caseInsensitive)
                                let carouselMatch = carouselRegex.firstMatch(in: cText, options: [], range: NSRange(location: 0, length: cText.utf16.count))
                                if let match = carouselMatch, let range = Range(match.range(at: 1), in: cText) {
                                    carousel = String(cText[range])
                                }
                            }
                            print("[DEBUG] Parsed bagTime: \(String(describing: bagTime)), carousel: \(String(describing: carousel))")
                            completion(bagTime, carousel)
                            return
                        }
                    }
                }
                print("[DEBUG] No 'Collect your luggage' step found in Arriving passenger section for date: \(dateString)")
                tryNextDate()
            } catch {
                print("[DEBUG] Error parsing HTML for date: \(dateString) - \(error)")
                tryNextDate()
            }
        }.resume()
    }
    
    var currentDateIndex = 0
    
    func tryNextDate() {
        currentDateIndex += 1
        if currentDateIndex < datesToTry.count {
            tryDate(datesToTry[currentDateIndex])
        } else {
            print("[DEBUG] Tried all dates (\(datesToTry.count)) - no data found")
            completion(nil, nil)
        }
    }
    
    // Start with the first date
    tryDate(datesToTry[currentDateIndex])
}

// Helper: Fetch and parse collect time and carousel using WKWebView (handles JS-loaded content)
func fetchBagAvailableTimeAndCarouselWithWebView(flightNumber: String, scheduledTime: Date, completion: @escaping (Date?, String?) -> Void) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateString = formatter.string(from: scheduledTime)
    let urlString = "https://www.manchesterairport.co.uk/flight-information/arrivals/itinerary/?id=\(flightNumber)-\(dateString)A"
    print("[DEBUG][WKWebView] Loading: \(urlString)")
    let webView = WKWebView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    // webView.isHidden = true // REMOVE this line
    let request = URLRequest(url: URL(string: urlString)!)
    let navDelegate = WebViewNavDelegate { webView in
        // JS: Find the timeline, then the 'Collect your luggage' step, and extract time and carousel
        let js = """
        (function() {
            function getText(node) {
                return node && node.innerText ? node.innerText.trim() : '';
            }
            // Find all timeline steps
            var steps = Array.from(document.querySelectorAll('p')).filter(p => getText(p).toLowerCase().includes('collect your luggage'));
            if (steps.length === 0) return JSON.stringify({ time: null, carousel: null });
            var step = steps[0];
            // Find the time (look for previous sibling with time)
            var time = null;
            var node = step.parentElement;
            while (node && !time) {
                var prev = node.previousElementSibling;
                while (prev) {
                    var txt = getText(prev);
                    var match = txt.match(/\\d{2}:\\d{2}/);
                    if (match) { time = match[0]; break; }
                    prev = prev.previousElementSibling;
                }
                node = node.parentElement;
            }
            // Find carousel (look for next sibling with 'Carousel')
            var carousel = null;
            node = step.parentElement;
            while (node && !carousel) {
                var next = node.nextElementSibling;
                while (next) {
                    var txt = getText(next);
                    var match = txt.match(/Carousel\\s*0*(\\d+)/i);
                    if (match) { carousel = match[1]; break; }
                    next = next.nextElementSibling;
                }
                node = node.parentElement;
            }
            return JSON.stringify({ time: time, carousel: carousel });
        })();
        """
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("[DEBUG][WKWebView] JS error: \(error)")
                completion(nil, nil)
                return
            }
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[DEBUG][WKWebView] JS result parse error")
                completion(nil, nil)
                return
            }
            print("[DEBUG][WKWebView] JS result: \(dict)")
            // Parse time
            var bagTime: Date? = nil
            if let timeStr = dict["time"] as? String {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                if let t = timeFormatter.date(from: timeStr) {
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: t)
                    let minute = calendar.component(.minute, from: t)
                    bagTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledTime)
                }
            }
            let carousel = dict["carousel"] as? String
            completion(bagTime, carousel)
        }
    }
    webView.navigationDelegate = navDelegate
    UIApplication.shared.windows.first?.rootViewController?.view.addSubview(webView)
    webView.load(request)
}

class WebViewNavDelegate: NSObject, WKNavigationDelegate {
    let onFinish: (WKWebView) -> Void
    init(onFinish: @escaping (WKWebView) -> Void) { self.onFinish = onFinish }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Wait for JS to render
            self.onFinish(webView)
            webView.removeFromSuperview()
        }
    }
}

// SwiftUI wrapper for background WKWebView scraping
struct BackgroundWebViewLoader: UIViewRepresentable {
    let url: URL
    let scheduledTime: Date
    let onResult: (Date?, String?) -> Void
    func makeCoordinator() -> Coordinator {
        Coordinator(scheduledTime: scheduledTime, onResult: onResult)
    }
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        webView.navigationDelegate = context.coordinator
        // Set a realistic iPhone Safari user agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.load(URLRequest(url: url))
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    class Coordinator: NSObject, WKNavigationDelegate {
        let scheduledTime: Date
        let onResult: (Date?, String?) -> Void
        init(scheduledTime: Date, onResult: @escaping (Date?, String?) -> Void) {
            self.scheduledTime = scheduledTime
            self.onResult = onResult
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Print the first 1000 chars of the HTML
                webView.evaluateJavaScript("document.documentElement.outerHTML") { htmlResult, htmlError in
                    if let html = htmlResult as? String {
                        print("[DEBUG][WKWebView] HTML preview:\n" + html.prefix(1000))
                    } else if let htmlError = htmlError {
                        print("[DEBUG][WKWebView] HTML error: \(htmlError)")
                    }
                }
                let js = """
                (function() {
                    function getText(node) {
                        return node && node.innerText ? node.innerText.trim() : '';
                    }
                    var steps = Array.from(document.querySelectorAll('p')).filter(p => getText(p).toLowerCase().includes('collect your luggage'));
                    if (steps.length === 0) return JSON.stringify({ time: null, carousel: null });
                    var step = steps[0];
                    var time = null;
                    var node = step.parentElement;
                    while (node && !time) {
                        var prev = node.previousElementSibling;
                        while (prev) {
                            var txt = getText(prev);
                            var match = txt.match(/\\d{2}:\\d{2}/);
                            if (match) { time = match[0]; break; }
                            prev = prev.previousElementSibling;
                        }
                        node = node.parentElement;
                    }
                    var carousel = null;
                    node = step.parentElement;
                    while (node && !carousel) {
                        var next = node.nextElementSibling;
                        while (next) {
                            var txt = getText(next);
                            var match = txt.match(/Carousel\\s*0*(\\d+)/i);
                            if (match) { carousel = match[1]; break; }
                            next = next.nextElementSibling;
                        }
                        node = node.parentElement;
                    }
                    return JSON.stringify({ time: time, carousel: carousel });
                })();
                """
                webView.evaluateJavaScript(js) { result, error in
                    if let error = error {
                        print("[DEBUG][WKWebView] JS error: \(error)")
                    }
                    print("[DEBUG][WKWebView] JS raw result: \(String(describing: result))")
                    var bagTime: Date? = nil
                    var carousel: String? = nil
                    if let jsonString = result as? String,
                       let data = jsonString.data(using: .utf8),
                       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let timeStr = dict["time"] as? String {
                            let timeFormatter = DateFormatter()
                            timeFormatter.dateFormat = "HH:mm"
                            if let t = timeFormatter.date(from: timeStr) {
                                let calendar = Calendar.current
                                let hour = calendar.component(.hour, from: t)
                                let minute = calendar.component(.minute, from: t)
                                bagTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: self.scheduledTime)
                            }
                        }
                        carousel = dict["carousel"] as? String
                        print("[DEBUG][WKWebView] Parsed bagTime: \(String(describing: bagTime)), carousel: \(String(describing: carousel))")
                    }
                    print("[DEBUG][WKWebView] Calling onResult with bagTime: \(String(describing: bagTime)), carousel: \(String(describing: carousel))")
                    self.onResult(bagTime, carousel)
                }
            }
        }
    }
}

extension DateFormatter {
    static func with(format: String) -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = format
        return df
    }
}
