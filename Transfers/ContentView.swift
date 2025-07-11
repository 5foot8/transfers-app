import SwiftUI
import PDFKit

func today() -> Date {
    Calendar.current.startOfDay(for: Date())
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
    
    var terminals: [String] {
        Array(Set(incomingFlights.map { $0.terminal })).sorted()
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
        // Optionally, filter outgoingFlights if you add a date property there in the future
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Transfer Management System")
                        .font(.largeTitle)
                        .padding(.top)
                    Spacer()
                    Button(action: { showingAddIncoming = true }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .padding()
                    }
                    .accessibilityLabel("Add Incoming Flight")
                }
                .padding(.horizontal)
                
                HStack {
                    Button("Expand All") {
                        expandedFlights = Set(incomingFlights.map { $0.id })
                    }
                    .padding(.horizontal)
                    Button("Collapse All") {
                        expandedFlights = []
                    }
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(terminals, id: \.self) { terminal in
                        IncomingFlightSectionView(
                            terminal: terminal,
                            incomingFlights: incomingFlights.filter { $0.terminal == terminal },
                            outgoingFlights: outgoingFlights,
                            expandedFlights: $expandedFlights,
                            onAddOutgoing: { incomingID in
                                if let flight = incomingFlights.first(where: { $0.id == incomingID }) {
                                    showingAddOutgoingFor = flight
                                }
                            },
                            onRemoveOutgoing: removeOutgoingLink,
                            onDeleteIncoming: { incomingID in
                                deleteIncomingFlight(id: incomingID)
                            }
                        )
                    }
                }
                .listStyle(.plain)
                
                Spacer()
                
                Button(action: {
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
            .navigationTitle("Transfers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingResetAlert = true }) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset Day")
                    }
                    .foregroundColor(.red)
                }
            }
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
                    addOutgoingFlight(to: incoming.id, outgoing: newOutgoing, bagCount: bagCount)
                }
            }
        }
        .onAppear(perform: {
            loadData()
            filterForToday()
        })
        .onChange(of: incomingFlights) { _ in saveData() }
        .onChange(of: outgoingFlights) { _ in saveData() }
    }
    
    func addOutgoingFlight(to incomingID: UUID, outgoing: OutgoingFlight, bagCount: Int) {
        // Add outgoing flight if not already present
        var outgoingFlight = outgoing
        if let idx = outgoingFlights.firstIndex(where: { $0.flightNumber == outgoing.flightNumber && $0.scheduledTime == outgoing.scheduledTime }) {
            outgoingFlight = outgoingFlights[idx]
        } else {
            outgoingFlights.append(outgoing)
        }
        // Link to incoming
        if let idx = incomingFlights.firstIndex(where: { $0.id == incomingID }) {
            var incoming = incomingFlights[idx]
            if !incoming.outgoingLinks.contains(where: { $0.outgoingFlightID == outgoingFlight.id }) {
                incoming.outgoingLinks.append(OutgoingLink(outgoingFlightID: outgoingFlight.id, bagCount: bagCount))
            }
            incomingFlights[idx] = incoming
        }
        // Update bag mapping in outgoing
        if let idx = outgoingFlights.firstIndex(where: { $0.id == outgoingFlight.id }) {
            outgoingFlights[idx].bagsFromIncoming[incomingID] = bagCount
        }
    }
    
    func removeOutgoingLink(incomingID: UUID, outgoingID: UUID) {
        // Remove link from incoming
        if let idx = incomingFlights.firstIndex(where: { $0.id == incomingID }) {
            var incoming = incomingFlights[idx]
            incoming.outgoingLinks.removeAll { $0.outgoingFlightID == outgoingID }
            incomingFlights[idx] = incoming
        }
        // Remove bag mapping from outgoing
        if let idx = outgoingFlights.firstIndex(where: { $0.id == outgoingID }) {
            outgoingFlights[idx].bagsFromIncoming.removeValue(forKey: incomingID)
        }
    }

    func deleteIncomingFlight(id: UUID) {
        incomingFlights.removeAll { $0.id == id }
        // Optionally, remove bag mappings from outgoing flights
        for idx in outgoingFlights.indices {
            outgoingFlights[idx].bagsFromIncoming.removeValue(forKey: id)
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
            HStack {
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                HStack {
                    Text(incoming.flightNumber)
                    Text("(")
                    Text(incoming.terminal).bold()
                    Text(")")
                }
                .font(.headline)
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
            .padding(.vertical, 4)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            if isExpanded {
                let outgoingLinks: [(Int, OutgoingLink, OutgoingFlight?)] = {
                    let sortedLinks = incoming.outgoingLinks.sorted { lhs, rhs in
                        let lhsFlight = outgoingFlights.first { $0.id == lhs.outgoingFlightID }
                        let rhsFlight = outgoingFlights.first { $0.id == rhs.outgoingFlightID }
                        return (lhsFlight?.scheduledTime ?? .distantFuture) < (rhsFlight?.scheduledTime ?? .distantFuture)
                    }
                    return sortedLinks.enumerated().map { (index, link) in
                        (index, link, outgoingFlights.first(where: { $0.id == link.outgoingFlightID }))
                    }
                }()
                ForEach(outgoingLinks, id: \.1.id) { (index, link, outgoing) in
                    if let outgoing = outgoing {
                        HStack {
                            Text("\(index + 1).")
                                .frame(width: 24, alignment: .trailing)
                            VStack(alignment: .leading) {
                                HStack(spacing: 2) {
                                    Text(outgoing.flightNumber)
                                    Text("(")
                                    Text(outgoing.terminal).bold()
                                    Text(")")
                                }
                                Text("To: \(outgoing.destination)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(outgoing.scheduledTime, style: .time)
                                .font(.caption)
                                .frame(width: 60)
                            Text("\(link.bagCount)")
                                .frame(width: 40)
                            Rectangle()
                                .frame(width: 60, height: 24)
                                .foregroundColor(.clear)
                                .overlay(Text(" ").font(.caption)) // Blank for actual bags received
                            Button(action: { onRemoveOutgoing(outgoing.id) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            } else {
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
            }
        }
    }
}

struct AddIncomingFlightView: View {
    @Environment(\.dismiss) var dismiss
    @State private var flightNumber = ""
    @State private var terminal = ""
    @State private var origin = ""
    @State private var scheduledTime = Date()
    @State private var notes = ""
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