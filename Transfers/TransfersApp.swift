//
//  TransfersApp.swift
//  Transfers
//
//  Created by Andrew Beckett on 10/07/2025.
//

import SwiftUI
import FirebaseCore

@main
struct TransfersApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
