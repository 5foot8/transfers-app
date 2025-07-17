import SwiftUI

struct TransfersView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCreateModal = false
    @State private var showingEditModal = false
    @State private var editingTransfer: BaggageTransfer? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(getTransferStats(), id: \.title) { stat in
                            TransferStatCard(stat: stat)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Transfers List
                if dataManager.baggageTransfers.isEmpty {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "No Transfers",
                        message: "Create your first baggage transfer to get started"
                    )
                } else {
                    List {
                        ForEach(groupedTransfers.keys.sorted(), id: \.self) { incomingFlightId in
                            if let group = groupedTransfers[incomingFlightId] {
                                TransferGroupView(
                                    group: group,
                                    onEdit: { transfer in
                                        editingTransfer = transfer
                                        showingEditModal = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transfers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateModal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateModal) {
                CreateTransferModal(
                    incomingFlights: dataManager.incomingFlights,
                    outgoingFlights: dataManager.outgoingFlights,
                    onSave: { transfer in
                        Task {
                            _ = try await dataManager.createBaggageTransfer(transfer)
                            showingCreateModal = false
                        }
                    },
                    onCancel: { showingCreateModal = false }
                )
            }
            .sheet(isPresented: $showingEditModal) {
                if let transfer = editingTransfer {
                    EditTransferModal(
                        transfer: transfer,
                        onSave: { updates in
                            Task {
                                try await dataManager.updateBaggageTransfer(transfer.id ?? "", updates: updates)
                                showingEditModal = false
                                editingTransfer = nil
                            }
                        },
                        onCancel: {
                            showingEditModal = false
                            editingTransfer = nil
                        }
                    )
                }
            }
        }
    }
    
    private var groupedTransfers: [String: TransferGroup] {
        var groups: [String: TransferGroup] = [:]
        
        for transfer in dataManager.baggageTransfers {
            let incomingFlight = dataManager.incomingFlights.first { $0.id == transfer.incomingFlightId }
            let outgoingFlight = dataManager.outgoingFlights.first { $0.id == transfer.outgoingFlightId }
            
            guard let incomingFlight = incomingFlight else { continue }
            
            if groups[transfer.incomingFlightId] == nil {
                groups[transfer.incomingFlightId] = TransferGroup(
                    incomingFlight: incomingFlight,
                    transfers: [],
                    totalBags: 0
                )
            }
            
            groups[transfer.incomingFlightId]?.transfers.append(
                TransferWithFlights(
                    transfer: transfer,
                    outgoingFlight: outgoingFlight
                )
            )
            groups[transfer.incomingFlightId]?.totalBags += transfer.bagCount
        }
        
        return groups
    }
    
    private func getTransferStats() -> [TransferStat] {
        let totalTransfers = dataManager.baggageTransfers.count
        let totalBags = dataManager.baggageTransfers.reduce(0) { $0 + $1.bagCount }
        let magTransfers = dataManager.baggageTransfers.filter { $0.isMAGTransfer }.count
        
        return [
            TransferStat(title: "Total Transfers", value: "\(totalTransfers)", icon: "arrow.triangle.2.circlepath", color: .blue),
            TransferStat(title: "Total Bags", value: "\(totalBags)", icon: "shippingbox", color: .green),
            TransferStat(title: "MAG Transfers", value: "\(magTransfers)", icon: "star", color: .orange)
        ]
    }
}

// MARK: - Supporting Views
struct TransferStatCard: View {
    let stat: TransferStat
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.title2)
                .foregroundColor(stat.color)
            
            Text(stat.value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 80)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TransferGroupView: View {
    let group: TransferGroup
    let onEdit: (BaggageTransfer) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Incoming Flight Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.incomingFlight.flightNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(group.incomingFlight.origin) → Terminal \(group.incomingFlight.terminal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(group.totalBags) bags")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(group.transfers.count) transfers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Transfers
            ForEach(group.transfers, id: \.transfer.id) { transferWithFlights in
                TransferRowView(
                    transferWithFlights: transferWithFlights,
                    onEdit: onEdit
                )
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TransferRowView: View {
    let transferWithFlights: TransferWithFlights
    let onEdit: (BaggageTransfer) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.right")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                if let outgoingFlight = transferWithFlights.outgoingFlight {
                    Text(outgoingFlight.flightNumber)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Terminal \(outgoingFlight.terminal) → \(outgoingFlight.destination)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Unknown Flight")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transferWithFlights.transfer.bagCount) bags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if transferWithFlights.transfer.isMAGTransfer {
                    Text("MAG")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            Button("Edit") {
                onEdit(transferWithFlights.transfer)
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Data Structures
struct TransferGroup {
    let incomingFlight: IncomingFlight
    var transfers: [TransferWithFlights]
    var totalBags: Int
}

struct TransferWithFlights {
    let transfer: BaggageTransfer
    let outgoingFlight: OutgoingFlight?
}

struct TransferStat {
    let title: String
    let value: String
    let icon: String
    let color: Color
} 