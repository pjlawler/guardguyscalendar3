//
//  EditUserView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//

import SwiftUI

struct EditUserView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var globalManager: GlobalManager
    
    @ObservedObject var viewModel: UsersViewModel
    var user: UserData?
    
    // Local state for editable fields.
    @State private var username: String
    @State private var email: String
    @State private var password: String = ""
    @State private var isAdmin: Bool
    
    private var usersOwnProfile: Bool {
        user?.id == globalManager.userId
    }

    
    init(viewModel: UsersViewModel, user: UserData? = nil) {
        self.viewModel = viewModel
        self.user = user
        if let user = user {
            _username = State(initialValue: user.username ?? "")
            _email = State(initialValue: user.email ?? "")
            _isAdmin = State(initialValue: user.isAdmin ?? false)
        } else {
            _username = State(initialValue: "")
            _email = State(initialValue: "")
            _isAdmin = State(initialValue: false)
        }
    }
    
    var disableSave: Bool {
        username.isEmpty || email.isEmpty || (password.isEmpty && user == nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User Information")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    user == nil ? SecureField("Password", text: $password) : SecureField("Password (optional)", text: $password)

                    // Show the Admin toggle only if the logged‑in user is an admin.
                    if globalManager.isAdmin {
                        Toggle("Admin", isOn: $isAdmin)
                            .disabled(usersOwnProfile)  // Prevent modifying your own admin status.
                    }
                }
                
            
            }
            .navigationTitle(user == nil ? "Add User" : "Edit User")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Create a user to save. For new users, the id might be 0 (or you can let your backend assign an id).
                        let userToSave = UserData(
                            id: user?.id ?? 0,
                            username: username,
                            email: email,
                            password: password, // if editing the user, password must be empty or nil if the user doesn't want to change the password
                            isAdmin: isAdmin,
                            createdAt: nil,
                            updatedAt: nil
                        )
                        
                        if user == nil {
                            viewModel.addUser(userToSave)
                        } else {
                            viewModel.editUser(userToSave)
                        }
                        dismiss()
                    }.disabled(disableSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            
            if usersOwnProfile {
                Button("Logout") {
                    globalManager.updateLogin(nil)
                }.buttonStyle(.bordered)
            }
        }
    }
}
