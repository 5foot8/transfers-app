import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Baggage Transfer Dashboard")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Overview of baggage transfer operations and workflow status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(getStats(), id: \.name) { stat in
                            StatCard(stat: stat)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Flights
                    VStack(spacing: 16) {
                        HStack {
                            Text("Recent Incoming Flights")
                                .font(.headline)
                            Spacer()
                            NavigationLink("View All", destination: FlightsView())
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if dataManager.getTodayIncomingFlights().isEmpty {
                            EmptyStateView(
                                icon: "airplane",
                                title: "No Flights Today",
                                message: "Add incoming flights to get started"
                            )
                        } else {
                            ForEach(dataManager.getTodayIncomingFlights().prefix(5), id: \.id) { flight in
                                FlightRowView(flight: flight)
                            }
                        }
                    }
                    
                    // Recent Outgoing Flights
                    VStack(spacing: 16) {
                        HStack {
                            Text("Recent Outgoing Flights")
                                .font(.headline)
                            Spacer()
                            NavigationLink("View All", destination: FlightsView())
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if dataManager.getTodayOutgoingFlights().isEmpty {
                            EmptyStateView(
                                icon: "airplane.departure",
                                title: "No Departures Today",
                                message: "Add outgoing flights to get started"
                            )
                        } else {
                            ForEach(dataManager.getTodayOutgoingFlights().prefix(5), id: \.id) { flight in
                                OutgoingFlightRowView(flight: flight)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func getStats() -> [StatItem] {
        let stats = dataManager.getWorkflowStats()
        let todayIncoming = dataManager.getTodayIncomingFlights()
        let todayOutgoing = dataManager.getTodayOutgoingFlights()
        
        return [
            StatItem(
                name: "Incoming Flights",
                value: "\(todayIncoming.count)",
                icon: "airplane.arrival",
                color: .blue,
                description: "Flights with baggage today"
            ),
            StatItem(
                name: "Outgoing Flights",
                value: "\(todayOutgoing.count)",
                icon: "airplane.departure",
                color: .green,
                description: "Flights receiving baggage"
            ),
            StatItem(
                name: "Total Bags",
                value: "\(stats.totalBags)",
                icon: "shippingbox",
                color: .purple,
                description: "Bags being transferred"
            ),
            StatItem(
                name: "Pending Collections",
                value: "\(stats.pendingCollections)",
                icon: "clock",
                color: .orange,
                description: "Bags ready for collection"
            ),
            StatItem(
                name: "Pending Deliveries",
                value: "\(stats.pendingDeliveries)",
                icon: "arrow.triangle.2.circlepath",
                color: .yellow,
                description: "Bags to be delivered"
            ),
            StatItem(
                name: "Active Workflows",
                value: "\(stats.activeWorkflows)",
                icon: "checkmark.circle",
                color: .indigo,
                description: "Ongoing operations"
            )
        ]
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let stat: StatItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stat.icon)
                    .font(.title2)
                    .foregroundColor(stat.color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(stat.value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(stat.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct FlightRowView: View {
    let flight: IncomingFlight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane.arrival")
                .font(.title3)
                .foregroundColor(.blue)
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
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(flight.scheduledTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                
                StatusBadge(flight: flight)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct OutgoingFlightRowView: View {
    let flight: OutgoingFlight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.flightNumber)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Terminal \(flight.terminal) → \(flight.destination)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(flight.scheduledTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                
                StatusBadge(flight: flight)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct StatusBadge: View {
    let flight: Any
    
    var body: some View {
        let (text, color) = getStatus()
        
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private func getStatus() -> (String, Color) {
        if let incomingFlight = flight as? IncomingFlight {
            if incomingFlight.cancelled {
                return ("Cancelled", .red)
            } else if incomingFlight.collectedTime != nil {
                return ("Collected", .green)
            } else if let bagAvailableTime = incomingFlight.bagAvailableTime, bagAvailableTime <= Date() {
                return ("Ready", .orange)
            } else {
                return ("Scheduled", .gray)
            }
        } else if let outgoingFlight = flight as? OutgoingFlight {
            if outgoingFlight.cancelled {
                return ("Cancelled", .red)
            } else if outgoingFlight.actualTime != nil {
                return ("Departed", .green)
            } else {
                return ("Scheduled", .gray)
            }
        }
        return ("Unknown", .gray)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatItem {
    let name: String
    let value: String
    let icon: String
    let color: Color
    let description: String
} 