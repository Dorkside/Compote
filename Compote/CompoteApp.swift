//
//  CompoteApp.swift
//  Compote
//
//  Created by James MARTIN on 01.02.2024.
//

import SwiftUI

@main
struct CompoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            // Settings or preferences view goes here
            Text("Preferences")
        }
    }
    
    init() {
    }
}
