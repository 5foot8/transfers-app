import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 16) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Baggage Transfers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Flight Transfer Management System")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Login Button
            Button(action: {
                Task {
                    await authManager.signInAnonymously()
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.fill")
                    }
                    Text(authManager.isLoading ? "Signing In..." : "Continue as Guest")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
} 