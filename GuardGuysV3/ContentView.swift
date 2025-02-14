//
//  ContentView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//
import SwiftUI

struct ContentView: View {
    
    
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject private var globalManager: GlobalManager
    
    @StateObject var eventsViewModel = EventsViewModel()
    @StateObject var usersViewModel = UsersViewModel()
    
    private let network = NetworkManager.shared
   
    var body: some View {
        ZStack {
            switch globalManager.isLoggedIn {
            case false: LoginView()
            case true: tabbedView
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            switch (oldValue, newValue) {
            case (.inactive, .active):
                print("checking credentials!")
                globalManager.checkuserCredentials()
            default: break
            }
        }
    }
    
    private var tabbedView: some View {
        TabView {
            DayView(viewModel: eventsViewModel)
                .tabItem { Label("Day", systemImage: "calendar") }
            WeekView(viewModel: eventsViewModel)
                .tabItem {  Label("Week", systemImage: "calendar.badge.plus") }
            AdminUsersView(viewModel: usersViewModel)
                .tabItem {  Label("\(globalManager.isAdmin ? "Users" : "User")", systemImage: "person.crop.circle.badge.checkmark") }
        }
    }
    
}
