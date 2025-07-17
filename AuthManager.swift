import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.user = user
            }
        }
    }
    
    func signInAnonymously() async {
        isLoading = true
        do {
            let result = try await Auth.auth().signInAnonymously()
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Sign in error: \(error)")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            user = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
} 