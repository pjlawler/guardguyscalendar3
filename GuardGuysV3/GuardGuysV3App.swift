//
//  GuardGuysV3App.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//

import SwiftUI

@main
struct GuardGuysV3App: App {
    
    @StateObject var gloabalManager = GlobalManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gloabalManager)
        }
    }
}
