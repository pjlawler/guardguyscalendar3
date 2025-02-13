//
//  GlobalManager.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/13/25.
//

import SwiftUI

@MainActor
final class GlobalManager: ObservableObject {
    
    @AppStorage("loggedInState") var isLoggedIn = false
    @AppStorage("loggedInUsername") var username = ""
    @AppStorage("loggedInAsAdmin") var isAdmin = false
    @AppStorage("loggedInUserId") var userId = 0
    @AppStorage("lastEventDownload") var lastDate = ""
    
    
    func updateLogin(_ user: UserData? = nil) {
        self.isAdmin = user?.isAdmin ?? false
        self.username = user?.username ?? ""
        self.userId = user?.id ?? 0
        self.isLoggedIn = user != nil ? true : false
    }
    
    

    
    
}
