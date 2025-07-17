import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct TransfersApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataManager = DataManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            FlightsView()
                .tabItem {
                    Image(systemName: "airplane")
                    Text("Flights")
                }
            
            TransfersView()
                .tabItem {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Transfers")
                }
            
            WorkflowView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Workflow")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
} 