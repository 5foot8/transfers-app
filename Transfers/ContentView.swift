import SwiftUI
import PDFKit
import Combine
import WebKit

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
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
        
        // Sync to Firebase if enabled
        Task {
            await FirebaseSync.shared.syncIncomingFlights(incomingFlights)
            await FirebaseSync.shared.syncOutgoingFlights(outgoingFlights)
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
            // 1. Large aircraft icon for import
            HStack {
                Spacer()
                Button(action: { showingWebImport = true }) {
                    Image(systemName: "airplane")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)
                }
                .accessibilityLabel("Import Flights")
                Spacer()
                Button(action: { showingPairing = true }) {
                    Image(systemName: "link")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)
                }
                .accessibilityLabel("Pair Flights")
                Spacer()
            }
            // 4. Reduce space above heading
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
                now: now,
                timer: timer,
                saveData: saveData,
                loadData: loadData,
                filterForToday: filterForToday,
                addOutgoingFlight: addOutgoingFlight,
                removeOutgoingLink: removeOutgoingLink,
                deleteIncomingFlight: deleteIncomingFlight,
                showingSettings: $showingSettings,
                collapsedTerminals: $collapsedTerminals
            )
        }
        .sheet(isPresented: $showingWebImport) {
            EnhancedImportSheet(
                arrivalsImportList: $arrivalsImportList,
                departuresImportList: $departuresImportList,
                allArrivals: incomingFlights,
                allDepartures: outgoingFlights,
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
            
            // Set up notification handling for remote updates
            NotificationCenter.default.addObserver(
                forName: .remoteFlightUpdated,
                object: nil,
                queue: .main
            ) { notification in
                // Handle remote flight updates
                if let flight = notification.object as? IncomingFlight {
                    // Update local data if needed
                    if let index = incomingFlights.firstIndex(where: { $0.id == flight.id }) {
                        incomingFlights[index] = flight
                    } else {
                        incomingFlights.append(flight)
                    }
                } else if let flight = notification.object as? OutgoingFlight {
                    // Update local data if needed
                    if let index = outgoingFlights.firstIndex(where: { $0.id == flight.id }) {
                        outgoingFlights[index] = flight
                    } else {
                        outgoingFlights.append(flight)
                    }
                }
            }
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
}

// Utility function for matching flights by code, terminal, and scheduled time (within 1 min)
extension Array where Element == OutgoingFlight {
    mutating func updateOrAppend(_ flight: OutgoingFlight) {
        if let idx = self.firstIndex(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 }) {
            self[idx] = flight
        } else {
            self.append(flight)
        }
    }
    func find(_ flight: OutgoingFlight) -> OutgoingFlight? {
        self.first(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 })
    }
}

extension Array where Element == IncomingFlight {
    mutating func updateOrAppend(_ flight: IncomingFlight) {
        if let idx = self.firstIndex(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 }) {
            self[idx] = flight
        } else {
            self.append(flight)
        }
    }
    func find(_ flight: IncomingFlight) -> IncomingFlight? {
        self.first(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 })
    }
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
                addOutgoingFlight: addOutgoingFlight
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
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(showingAddIncoming: $showingAddIncoming, showingSettings: $showingSettings)
            ExpandCollapseButtons(expandedFlights: $expandedFlights, incomingFlights: incomingFlights)
            FlightListView(
                terminals: terminals,
                incomingFlights: incomingFlights,
                outgoingFlights: outgoingFlights,
                expandedFlights: $expandedFlights,
                showingAddOutgoingFor: $showingAddOutgoingFor,
                removeOutgoingLink: removeOutgoingLink,
                deleteIncomingFlight: deleteIncomingFlight,
                collapsedTerminals: $collapsedTerminals
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
    @ObservedObject var firebaseSync = FirebaseSync.shared
    @State private var showingSessionSheet = false
    @State private var sessionIDInput = ""
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
                
                Section(header: Text("Data Sync")) {
                    Picker("Sync Mode", selection: $firebaseSync.syncMode) {
                        ForEach(SyncMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: firebaseSync.syncMode) { _, newMode in
                        firebaseSync.setSyncMode(newMode)
                    }
                    
                    if firebaseSync.syncMode != .local {
                        HStack {
                            Circle()
                                .fill(firebaseSync.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(firebaseSync.isConnected ? "Connected" : "Disconnected")
                                .foregroundColor(firebaseSync.isConnected ? .green : .red)
                        }
                        
                        if let lastSync = firebaseSync.lastSyncTime {
                            Text("Last sync: \(lastSync, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if firebaseSync.syncMode == .live {
                        if let sessionID = firebaseSync.sessionID {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Session ID:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(sessionID)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        } else {
                            Button("Create Session") {
                                Task {
                                    await firebaseSync.createSession()
                                }
                            }
                        }
                        
                        Button("Join Session") {
                            showingSessionSheet = true
                        }
                    }
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
            .sheet(isPresented: $showingSessionSheet) {
                NavigationView {
                    VStack(spacing: 20) {
                        Text("Join Live Session")
                            .font(.title2)
                            .padding(.top)
                        
                        Text("Enter the session ID to join a live session with other devices:")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        TextField("Session ID", text: $sessionIDInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button("Join") {
                            Task {
                                let success = await firebaseSync.joinSession(sessionIDInput)
                                if success {
                                    showingSessionSheet = false
                                    sessionIDInput = ""
                                }
                            }
                        }
                        .disabled(sessionIDInput.isEmpty)
                        
                        Spacer()
                    }
                    .navigationTitle("Join Session")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingSessionSheet = false
                                sessionIDInput = ""
                            }
                        }
                    }
                }
            }
        }
    }
}

// Update header to add settings button
struct HeaderView: View {
    @Binding var showingAddIncoming: Bool
    @Binding var showingSettings: Bool
    @ObservedObject var firebaseSync = FirebaseSync.shared
    
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
            
            // Firebase status indicator
            if firebaseSync.syncMode != .local {
                HStack(spacing: 4) {
                    Circle()
                        .fill(firebaseSync.isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(firebaseSync.syncMode.rawValue)
                        .font(.caption2)
                        .foregroundColor(firebaseSync.isConnected ? .green : .red)
                }
                .padding(.horizontal, 4)
            }
            
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
    
    var body: some View {
        List {
            ForEach(terminals, id: \.self) { terminal in
                let filteredFlights = incomingFlights.filter { $0.terminal == terminal }
                CollapsibleTerminalSection(
                    terminal: terminal,
                    incomingFlights: filteredFlights,
                    outgoingFlights: outgoingFlights,
                    expandedFlights: $expandedFlights,
                    showingAddOutgoingFor: $showingAddOutgoingFor,
                    removeOutgoingLink: removeOutgoingLink,
                    deleteIncomingFlight: deleteIncomingFlight,
                    collapsedTerminals: $collapsedTerminals
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

struct IncomingFlightSectionView: View {
    let terminal: String
    let incomingFlights: [IncomingFlight]
    let outgoingFlights: [OutgoingFlight]
    @Binding var expandedFlights: Set<UUID>
    var onAddOutgoing: (UUID) -> Void
    var onRemoveOutgoing: (UUID, UUID) -> Void
    var onDeleteIncoming: (UUID) -> Void
    
    var body: some View {
        Section(header: Text("Terminal \(terminal)").font(.title2)) {
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
                    onAddOutgoing: { onAddOutgoing(incoming.id) },
                    onRemoveOutgoing: { outgoingID in onRemoveOutgoing(incoming.id, outgoingID) },
                    onDelete: { onDeleteIncoming(incoming.id) }
                )
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlightHeaderView(
                incoming: incoming,
                onToggleExpand: onToggleExpand,
                onAddOutgoing: onAddOutgoing,
                onDelete: onDelete
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
    let onToggleExpand: () -> Void
    let onAddOutgoing: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleExpand) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            HStack(spacing: 4) {
                Text(incoming.flightNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(incoming.terminal.uppercased())
                    .font(.subheadline).bold()
                    .foregroundColor(terminalColor(incoming.terminal))
            }
            .font(.subheadline)
            Spacer()
            Text(incoming.scheduledTime, style: .time)
                .font(.subheadline)
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
    
    private var isExpanded: Bool {
        // This will be handled by the parent view
        false
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
                }
                Text("To: \(outgoing.destination)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(outgoing.scheduledTime, style: .time)
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
                    Text(outgoing.scheduledTime, style: .time)
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

// Flight Data structure for web import
struct FlightData: Hashable {
    let flightNumber: String
    let time: String
    let origin: String
    let terminal: String
    let airline: String
    let status: String
    let isArrival: Bool
}

// Enhanced Web Import System
struct EnhancedWebImportView: UIViewControllerRepresentable {
    let url: URL
    let existingFlights: [String] // Flight numbers already in database
    var onFlightSelected: (FlightData) -> Void
    var onFlightDeselected: (FlightData) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            existingFlights: existingFlights,
            onFlightSelected: onFlightSelected,
            onFlightDeselected: onFlightDeselected
        )
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        let js = """
        (function() {
            // Enhanced CSS for different states
            var style = document.createElement('style');
            style.innerHTML = `
                .__flight_hover { background: #ffe066 !important; cursor: pointer !important; }
                .__flight_selected { background: #4CAF50 !important; color: white !important; }
                .__flight_existing { background: #FF9800 !important; color: white !important; }
                .__flight_selected.__flight_existing { background: #FF5722 !important; color: white !important; }
            `;
            document.head.appendChild(style);
            
            var selectedFlights = new Set();
            var existingFlights = \(existingFlights);
            
            function getFlightKey(row) {
                const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                const time = row.querySelector('span[style*="width: 80px"]')?.innerText?.trim();
                const terminal = row.querySelector('td:nth-child(3)')?.innerText?.trim();
                return flightNumber + '|' + time + '|' + terminal;
            }
            
            function updateRowStyle(row) {
                const key = getFlightKey(row);
                const isSelected = selectedFlights.has(key);
                const isExisting = existingFlights.includes(row.querySelector('span[class*="vwba0x"]')?.innerText?.trim());
                
                row.classList.remove('__flight_hover', '__flight_selected', '__flight_existing');
                
                if (isSelected && isExisting) {
                    row.classList.add('__flight_selected', '__flight_existing');
                } else if (isSelected) {
                    row.classList.add('__flight_selected');
                } else if (isExisting) {
                    row.classList.add('__flight_existing');
                }
            }
            
            function extractFlightData(row) {
                const schedTime = row.querySelector('span[style*="width: 80px"]')?.innerText?.trim();
                const origin = row.querySelector('span[class*="ss8qoa8"]')?.innerText?.trim();
                const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                const airline = row.querySelector('span[class*="w6c5ku"]')?.innerText?.trim();
                const terminal = row.querySelector('td:nth-child(3)')?.innerText?.trim();
                const status = row.querySelector('td:last-child')?.innerText?.trim();
                
                return {
                    flight_number: flightNumber,
                    scheduled_time: schedTime,
                    origin: origin,
                    airline: airline,
                    terminal: terminal,
                    status: status,
                    is_arrival: true
                };
            }
            
            function toggleFlightSelection(row) {
                const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                if (!flightNumber || flightNumber === '') return;
                
                const key = getFlightKey(row);
                const flightData = extractFlightData(row);
                
                if (selectedFlights.has(key)) {
                    selectedFlights.delete(key);
                    window.webkit?.messageHandlers?.flightDeselected?.postMessage(flightData);
                } else {
                    selectedFlights.add(key);
                    window.webkit?.messageHandlers?.flightSelected?.postMessage(flightData);
                }
                
                updateRowStyle(row);
            }
            
            function attachHandlers() {
                document.querySelectorAll('tr').forEach(row => {
                    if (!row.__hasEnhancedHandler) {
                        const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                        if (flightNumber && flightNumber !== '') {
                            row.addEventListener('mouseenter', function() {
                                if (!this.classList.contains('__flight_selected') && !this.classList.contains('__flight_existing')) {
                                    this.classList.add('__flight_hover');
                                }
                            });
                            
                            row.addEventListener('mouseleave', function() {
                                this.classList.remove('__flight_hover');
                            });
                            
                            row.addEventListener('click', function(event) {
                                event.stopPropagation();
                                event.preventDefault();
                                toggleFlightSelection(this);
                            }, true);
                            
                            // Set initial style for existing flights
                            updateRowStyle(row);
                        }
                        row.__hasEnhancedHandler = true;
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
        webView.configuration.userContentController.add(context.coordinator, name: "flightSelected")
        webView.configuration.userContentController.add(context.coordinator, name: "flightDeselected")
        
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
        let existingFlights: [String]
        let onFlightSelected: (FlightData) -> Void
        let onFlightDeselected: (FlightData) -> Void
        weak var webView: WKWebView?
        
        init(existingFlights: [String], onFlightSelected: @escaping (FlightData) -> Void, onFlightDeselected: @escaping (FlightData) -> Void) {
            self.existingFlights = existingFlights
            self.onFlightSelected = onFlightSelected
            self.onFlightDeselected = onFlightDeselected
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let dict = message.body as? [String: Any] {
                let flightData = FlightData(
                    flightNumber: dict["flight_number"] as? String ?? "",
                    time: dict["scheduled_time"] as? String ?? "",
                    origin: dict["origin"] as? String ?? "",
                    terminal: dict["terminal"] as? String ?? "",
                    airline: dict["airline"] as? String ?? "",
                    status: dict["status"] as? String ?? "",
                    isArrival: dict["is_arrival"] as? Bool ?? true
                )
                
                if message.name == "flightSelected" {
                    onFlightSelected(flightData)
                } else if message.name == "flightDeselected" {
                    onFlightDeselected(flightData)
                }
            }
        }
    }
}

// Enhanced Import Sheet with combined arrivals/departures
struct EnhancedImportSheet: View {
    @Binding var arrivalsImportList: [IncomingFlight]
    @Binding var departuresImportList: [OutgoingFlight]
    var allArrivals: [IncomingFlight]
    var allDepartures: [OutgoingFlight]
    var onDone: () -> Void
    
    @State private var selectedTab = 0
    @State private var selectedFlights: Set<String> = []
    @State private var showingDepartures = false
    
    var existingFlightNumbers: [String] {
        let arrivalNumbers = allArrivals.map { $0.flightNumber }
        let departureNumbers = allDepartures.map { $0.flightNumber }
        return Array(Set(arrivalNumbers + departureNumbers))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Import Type", selection: $selectedTab) {
                    Text("Arrivals").tag(0)
                    Text("Departures").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.top, .horizontal])
                
                Divider()
                
                // Web view
                if selectedTab == 0 {
                    EnhancedWebImportView(
                        url: URL(string: "https://www.manchesterairport.co.uk/flight-information/arrivals/")!,
                        existingFlights: existingFlightNumbers,
                        onFlightSelected: { flightData in
                            let flight = IncomingFlight(
                                flightNumber: flightData.flightNumber,
                                terminal: flightData.terminal,
                                origin: flightData.origin,
                                scheduledTime: parseTime(flightData.time),
                                notes: "",
                                date: today()
                            )
                            if !arrivalsImportList.contains(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 }) {
                                arrivalsImportList.append(flight)
                            }
                        },
                        onFlightDeselected: { flightData in
                            arrivalsImportList.removeAll { flight in
                                flight.flightNumber == flightData.flightNumber && 
                                flight.terminal == flightData.terminal &&
                                abs(flight.scheduledTime.timeIntervalSince(parseTime(flightData.time))) < 60
                            }
                        }
                    )
                } else {
                    EnhancedDeparturesWebImportView(
                        existingFlights: existingFlightNumbers,
                        onFlightSelected: { flightData in
                            let flight = OutgoingFlight(
                                flightNumber: flightData.flightNumber,
                                terminal: flightData.terminal,
                                destination: flightData.origin, // Note: origin field contains destination for departures
                                scheduledTime: parseTime(flightData.time),
                                notes: "",
                                date: today()
                            )
                            if !departuresImportList.contains(where: { $0.flightNumber == flight.flightNumber && $0.terminal == flight.terminal && abs($0.scheduledTime.timeIntervalSince(flight.scheduledTime)) < 60 }) {
                                departuresImportList.append(flight)
                            }
                        },
                        onFlightDeselected: { flightData in
                            departuresImportList.removeAll { flight in
                                flight.flightNumber == flightData.flightNumber && 
                                flight.terminal == flightData.terminal &&
                                abs(flight.scheduledTime.timeIntervalSince(parseTime(flightData.time))) < 60
                            }
                        }
                    )
                }
                
                Divider()
                
                // Selected flights list at bottom
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Selected Flights")
                            .font(.headline)
                        Spacer()
                        Text("\(arrivalsImportList.count + departuresImportList.count) total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(arrivalsImportList, id: \.id) { flight in
                                HStack {
                                    Text("🛬 \(flight.flightNumber)")
                                        .font(.subheadline)
                                        .bold()
                                    Text(flight.terminal.uppercased())
                                        .font(.caption)
                                        .foregroundColor(terminalColor(flight.terminal))
                                    Text(flight.scheduledTime, style: .time)
                                        .font(.caption)
                                    Text(flight.origin)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            }
                            
                            ForEach(departuresImportList, id: \.id) { flight in
                                HStack {
                                    Text("🛫 \(flight.flightNumber)")
                                        .font(.subheadline)
                                        .bold()
                                    Text(flight.terminal.uppercased())
                                        .font(.caption)
                                        .foregroundColor(terminalColor(flight.terminal))
                                    Text(flight.scheduledTime, style: .time)
                                        .font(.caption)
                                    Text(flight.destination)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 150)
                }
                .padding(.vertical, 8)
                
                // Done button
                Button("Import Selected Flights (\(arrivalsImportList.count + departuresImportList.count))") {
                    onDone()
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .disabled(arrivalsImportList.isEmpty && departuresImportList.isEmpty)
            }
            .navigationTitle("Import Flights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let today = Calendar.current.startOfDay(for: Date())
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
        }
        return today
    }
}

// Enhanced Departures Web Import View
struct EnhancedDeparturesWebImportView: UIViewControllerRepresentable {
    let existingFlights: [String]
    var onFlightSelected: (FlightData) -> Void
    var onFlightDeselected: (FlightData) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            existingFlights: existingFlights,
            onFlightSelected: onFlightSelected,
            onFlightDeselected: onFlightDeselected
        )
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        let js = """
        (function() {
            // Enhanced CSS for departures
            var style = document.createElement('style');
            style.innerHTML = `
                .__flight_hover { background: #cce3ff !important; cursor: pointer !important; }
                .__flight_selected { background: #4CAF50 !important; color: white !important; }
                .__flight_existing { background: #FF9800 !important; color: white !important; }
                .__flight_selected.__flight_existing { background: #FF5722 !important; color: white !important; }
            `;
            document.head.appendChild(style);
            
            var selectedFlights = new Set();
            var existingFlights = \(existingFlights);
            
            function getFlightKey(row) {
                const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                const time = row.querySelector('span[style*="width: 80px"]')?.innerText?.trim();
                const terminal = row.querySelector('td:nth-child(3)')?.innerText?.trim();
                return flightNumber + '|' + time + '|' + terminal;
            }
            
            function updateRowStyle(row) {
                const key = getFlightKey(row);
                const isSelected = selectedFlights.has(key);
                const isExisting = existingFlights.includes(row.querySelector('span[class*="vwba0x"]')?.innerText?.trim());
                
                row.classList.remove('__flight_hover', '__flight_selected', '__flight_existing');
                
                if (isSelected && isExisting) {
                    row.classList.add('__flight_selected', '__flight_existing');
                } else if (isSelected) {
                    row.classList.add('__flight_selected');
                } else if (isExisting) {
                    row.classList.add('__flight_existing');
                }
            }
            
            function extractFlightData(row) {
                const schedTime = row.querySelector('span[style*="width: 80px"]')?.innerText?.trim();
                const destination = row.querySelector('span[class*="ss8qoa8"]')?.innerText?.trim();
                const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                const airline = row.querySelector('span[class*="w6c5ku"]')?.innerText?.trim();
                const terminal = row.querySelector('td:nth-child(3)')?.innerText?.trim();
                const status = row.querySelector('td:last-child')?.innerText?.trim();
                
                return {
                    flight_number: flightNumber,
                    scheduled_time: schedTime,
                    origin: destination, // Note: origin field contains destination for departures
                    airline: airline,
                    terminal: terminal,
                    status: status,
                    is_arrival: false
                };
            }
            
            function toggleFlightSelection(row) {
                const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                if (!flightNumber || flightNumber === '') return;
                
                const key = getFlightKey(row);
                const flightData = extractFlightData(row);
                
                if (selectedFlights.has(key)) {
                    selectedFlights.delete(key);
                    window.webkit?.messageHandlers?.flightDeselected?.postMessage(flightData);
                } else {
                    selectedFlights.add(key);
                    window.webkit?.messageHandlers?.flightSelected?.postMessage(flightData);
                }
                
                updateRowStyle(row);
            }
            
            function attachHandlers() {
                document.querySelectorAll('tr').forEach(row => {
                    if (!row.__hasEnhancedHandler) {
                        const flightNumber = row.querySelector('span[class*="vwba0x"]')?.innerText?.trim();
                        if (flightNumber && flightNumber !== '') {
                            row.addEventListener('mouseenter', function() {
                                if (!this.classList.contains('__flight_selected') && !this.classList.contains('__flight_existing')) {
                                    this.classList.add('__flight_hover');
                                }
                            });
                            
                            row.addEventListener('mouseleave', function() {
                                this.classList.remove('__flight_hover');
                            });
                            
                            row.addEventListener('click', function(event) {
                                event.stopPropagation();
                                event.preventDefault();
                                toggleFlightSelection(this);
                            }, true);
                            
                            // Set initial style for existing flights
                            updateRowStyle(row);
                        }
                        row.__hasEnhancedHandler = true;
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
        webView.configuration.userContentController.add(context.coordinator, name: "flightSelected")
        webView.configuration.userContentController.add(context.coordinator, name: "flightDeselected")
        
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
        let existingFlights: [String]
        let onFlightSelected: (FlightData) -> Void
        let onFlightDeselected: (FlightData) -> Void
        weak var webView: WKWebView?
        
        init(existingFlights: [String], onFlightSelected: @escaping (FlightData) -> Void, onFlightDeselected: @escaping (FlightData) -> Void) {
            self.existingFlights = existingFlights
            self.onFlightSelected = onFlightSelected
            self.onFlightDeselected = onFlightDeselected
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let dict = message.body as? [String: Any] {
                let flightData = FlightData(
                    flightNumber: dict["flight_number"] as? String ?? "",
                    time: dict["scheduled_time"] as? String ?? "",
                    origin: dict["origin"] as? String ?? "",
                    terminal: dict["terminal"] as? String ?? "",
                    airline: dict["airline"] as? String ?? "",
                    status: dict["status"] as? String ?? "",
                    isArrival: dict["is_arrival"] as? Bool ?? false
                )
                
                if message.name == "flightSelected" {
                    onFlightSelected(flightData)
                } else if message.name == "flightDeselected" {
                    onFlightDeselected(flightData)
                }
            }
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
                        onDelete: { deleteIncomingFlight(incoming.id) }
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
        }
        .headerProminence(.standard)
    }
} 
