import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @State private var showingWebImport = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guest User")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Anonymous Authentication")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Data Management") {
                    Button(action: { showingWebImport = true }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            Text("Import from Airport Website")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Export data functionality
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Incoming Flights")
                        Spacer()
                        Text("\(dataManager.incomingFlights.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Outgoing Flights")
                        Spacer()
                        Text("\(dataManager.outgoingFlights.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Baggage Transfers")
                        Spacer()
                        Text("\(dataManager.baggageTransfers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Bags")
                        Spacer()
                        Text("\(totalBags)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingWebImport) {
                WebImportView()
            }
        }
    }
    
    private var totalBags: Int {
        dataManager.baggageTransfers.reduce(0) { $0 + $1.bagCount }
    }
}

// MARK: - Web Import View
struct WebImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var arrivalsImportList: [IncomingFlight] = []
    @State private var departuresImportList: [OutgoingFlight] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Flight Type", selection: $selectedTab) {
                    Text("Arrivals").tag(0)
                    Text("Departures").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Web View Placeholder
                VStack(spacing: 20) {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Web Import Feature")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("This feature will allow you to import flights directly from the Manchester Airport website with multi-select functionality.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Coming Soon!")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Import Button
                Button("Import Selected Flights") {
                    // Import functionality
                    dismiss()
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding()
                .disabled(true)
            }
            .navigationTitle("Web Import")
            .navigationBarTitleDisplayMode(.inline)
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