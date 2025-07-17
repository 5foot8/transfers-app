import SwiftUI

struct WorkflowView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workflow Operations")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Manage baggage collection and delivery operations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Pending Collections
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Pending Collections")
                                .font(.headline)
                            Spacer()
                            Text("\(pendingCollections.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        if pendingCollections.isEmpty {
                            EmptyStateView(
                                icon: "clock",
                                title: "No Pending Collections",
                                message: "All bags are collected or not yet available"
                            )
                        } else {
                            ForEach(pendingCollections, id: \.id) { flight in
                                CollectionTaskRow(flight: flight)
                            }
                        }
                    }
                    
                    // Pending Deliveries
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Pending Deliveries")
                                .font(.headline)
                            Spacer()
                            Text("\(pendingDeliveries.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        if pendingDeliveries.isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle",
                                title: "No Pending Deliveries",
                                message: "All collected bags have been delivered"
                            )
                        } else {
                            ForEach(pendingDeliveries, id: \.id) { flight in
                                DeliveryTaskRow(flight: flight)
                            }
                        }
                    }
                    
                    // Today's Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            SummaryCard(
                                title: "Total Flights",
                                value: "\(dataManager.getTodayIncomingFlights().count + dataManager.getTodayOutgoingFlights().count)",
                                icon: "airplane",
                                color: .blue
                            )
                            
                            SummaryCard(
                                title: "Total Bags",
                                value: "\(totalBagsToday)",
                                icon: "shippingbox",
                                color: .green
                            )
                            
                            SummaryCard(
                                title: "Completed",
                                value: "\(completedTasks)",
                                icon: "checkmark.circle",
                                color: .green
                            )
                            
                            SummaryCard(
                                title: "In Progress",
                                value: "\(inProgressTasks)",
                                icon: "arrow.triangle.2.circlepath",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Workflow")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var pendingCollections: [IncomingFlight] {
        let todayFlights = dataManager.getTodayIncomingFlights()
        return todayFlights.filter { flight in
            !flight.collectedTime.isNotNil && 
            flight.bagAvailableTime.isNotNil && 
            flight.bagAvailableTime! <= Date()
        }
    }
    
    private var pendingDeliveries: [IncomingFlight] {
        let todayFlights = dataManager.getTodayIncomingFlights()
        return todayFlights.filter { flight in
            flight.collectedTime.isNotNil && 
            !flight.deliveredTime.isNotNil
        }
    }
    
    private var totalBagsToday: Int {
        dataManager.getTodayIncomingFlights().reduce(0) { total, flight in
            total + flight.outgoingLinks.reduce(0) { sum, link in
                sum + link.bagCount
            }
        }
    }
    
    private var completedTasks: Int {
        let todayFlights = dataManager.getTodayIncomingFlights()
        return todayFlights.filter { $0.deliveredTime.isNotNil }.count
    }
    
    private var inProgressTasks: Int {
        pendingCollections.count + pendingDeliveries.count
    }
}

// MARK: - Supporting Views
struct CollectionTaskRow: View {
    let flight: IncomingFlight
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.flightNumber)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(flight.origin) → Terminal \(flight.terminal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let carousel = flight.carousel {
                    Text("Carousel \(carousel)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let bagAvailableTime = flight.bagAvailableTime {
                    Text("Available \(bagAvailableTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Button("Mark Collected") {
                    Task {
                        try await dataManager.updateIncomingFlight(
                            flight.id ?? "",
                            updates: ["collectedTime": Date()]
                        )
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct DeliveryTaskRow: View {
    let flight: IncomingFlight
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.flightNumber)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Terminal \(flight.terminal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(flight.outgoingLinks.count) transfers")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let collectedTime = flight.collectedTime {
                    Text("Collected \(collectedTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Button("Mark Delivered") {
                    Task {
                        try await dataManager.updateIncomingFlight(
                            flight.id ?? "",
                            updates: ["deliveredTime": Date()]
                        )
                    }
                }
                .font(.caption)
                .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
} 