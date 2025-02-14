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
    
    let network = NetworkManager.shared
    
    func updateLogin(_ user: UserData? = nil) {
        self.isAdmin = user?.isAdmin ?? false
        self.username = user?.username ?? ""
        self.userId = user?.id ?? 0
        self.isLoggedIn = user != nil ? true : false
    }
    
    func checkuserCredentials() {
        network.makeApiRequestFor(.getMembers) { result in
            switch result {
            case .success(let data):
                let users = try? JSONDecoder().decode([UserData].self, from: data) // gets the saved users from the database
                let currentUser = users?.first(where: { $0.id == self.userId }) // finds the logged in user's credentials
                self.updateLogin(currentUser) // updates their credentials or logs out if not in the database
            case .failure(let error):
                print("Error loading users: \(error)")
            }
        }
    }

    
    
}
