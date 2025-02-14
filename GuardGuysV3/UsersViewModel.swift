//
//  UsersViewModel.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//


import SwiftUI

final class UsersViewModel: ObservableObject {
  
    @Published var isLoading = false
    @Published var showUserDetails: Bool = false
    @Published var selectedUser: UserData?
    
    @AppStorage("loggedInUserId") var userId = 0
    @AppStorage("loggedInAsAdmin") var isAdmin = false
    
    @Published var users: [UserData] = []
    
    var usersToDisplay: [UserData] {
        self.users.filter { self.isAdmin ? true : $0.id == self.userId }
    }
   
    let network = NetworkManager.shared
    
    func loadUsers() {
        
        self.isLoading = true
        
        network.makeApiRequestFor(.getMembers) { result in
            switch result {
            case .success(let data):
                self.isLoading = false
                let users = try? JSONDecoder().decode([UserData].self, from: data)
                self.users = users ?? []
                
            case .failure(let error):
                self.isLoading = false
                self.users = []
                print("Error loading users: \(error)")
            }
        }
    }
    func addUser(_ user: UserData) {
        
        self.isLoading = true
        
        network.makeApiRequestFor(.addMember(data: user)) { result in
            switch result {
            case .success( _):
                self.loadUsers()
                
            case .failure(let error):
                self.isLoading = false
                print("Error add a new user: \(error)")
            }
        }
    }
    func editUser(_ user: UserData) {
        
        print("\(user.username ?? "no name")")
        
        self.isLoading = true
        
        network.makeApiRequestFor(.editMember(id: user.id ?? 0, data: user)) { result in
            switch result {
            case .success( _):
                self.loadUsers()
                
            case .failure(let error):
                self.isLoading = false
                print("Error updating a user: \(error)")
            }
        }
    }
    func deleteUser(_ user: UserData) {
        
        self.isLoading = true
        print("Deleting user \(user.username ?? "no name")")
        network.makeApiRequestFor(.deleteMember(id: user.id ?? 0)) { result in
            switch result {
            case .success( _):
                self.loadUsers()
                
            case .failure(let error):
                self.isLoading = false
                print("Error updating a user: \(error)")
            }
        }
    }
    
}
