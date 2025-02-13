//
//  ContentView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//
import SwiftUI

struct ContentView: View {
    
    @StateObject var eventsViewModel = EventsViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject private var globalManager: GlobalManager
    
    private let network = NetworkManager.shared
   
    var body: some View {
        ZStack {
            switch globalManager.isLoggedIn {
            case false: LoginView()
            case true: tabs
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            switch (oldValue, newValue) {
            case (.inactive, .active):
                print("checking credentials!")
                checkuserCredentials()
            default: break
            }
        }
    }
    
    private var tabs: some View {
        TabView {
            DayView(viewModel: eventsViewModel)
                .tabItem { Label("Day", systemImage: "calendar") }
            WeekView(viewModel: eventsViewModel)
                .tabItem {  Label("Week", systemImage: "calendar.badge.plus") }
            AdminUsersView()
                .tabItem {  Label("Admin", systemImage: "person.crop.circle.badge.checkmark") }
        }
    }
    private func checkuserCredentials() {
        network.makeApiRequestFor(.getMembers) { result in
            switch result {
            case .success(let data):
                let users = try? JSONDecoder().decode([UserData].self, from: data) // gets the saved users from the database
                let currentUser = users?.first(where: { $0.id == globalManager.userId }) // finds the logged in user's credentials
                globalManager.updateLogin(currentUser) // updates their credentials or logs out if not in the database
            case .failure(let error):
                print("Error loading users: \(error)")
            }
        }
    }
}
