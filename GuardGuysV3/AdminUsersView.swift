//
//  AdminUsersView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//

import SwiftUI

struct AdminUsersView: View {
    
    @ObservedObject private var viewModel: UsersViewModel
    @EnvironmentObject private var globalManager: GlobalManager
    
    init() {
        self.viewModel = UsersViewModel()
    }
    
    var body: some View {
        Group {
            NavigationStack {
                List {
                    ForEach(viewModel.usersToDisplay, id: \.id) { user in
                        VStack(alignment: .leading) {
                            Text(user.username ?? "Unknown")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Set the selected user and show the edit sheet.
                            viewModel.selectedUser = user
                            viewModel.showUserDetails = true
                        }
                    }
                    // Enable swipe-to-delete for the list rows.
                    .onDelete { indexSet in
                        // The indices refer to the filtered array.
                        let usersToDelete = indexSet.map { viewModel.usersToDisplay[$0] }
                        for user in usersToDelete {
                            viewModel.deleteUser(user)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if viewModel.users.isEmpty {
                        Text("No Users Found")
                            .font(.headline)
                            .padding(.top, 30)
                    }
                    if viewModel.isLoading {
                        ZStack {
                            Color.clear
                            ProgressView()
                        }
                        .background(.ultraThinMaterial)
                    }
                }
                .navigationTitle("Users")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // For adding a new user, clear the selected user (set to nil)
                            // so that the edit view knows it's in "add" mode.
                            viewModel.selectedUser = nil
                            viewModel.showUserDetails = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .onAppear { viewModel.loadUsers() }
        }
        // Present the add/edit user sheet.
        .sheet(isPresented: $viewModel.showUserDetails) {
            // If selectedUser is nil, the EditUserView will be used to add a new user.
            EditUserView(viewModel: viewModel, user: viewModel.selectedUser)
        }
    }
}
