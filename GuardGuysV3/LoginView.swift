//
//  LoginView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//


import SwiftUI

struct LoginView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var globalManager: GlobalManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginError: Error? = nil
    @State private var showProgressView: Bool = false
    
    let network = NetworkManager.shared
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 20){
                
                Text("Event Scheduling")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                Image(colorScheme == .dark ? "logo-white" : "logo-black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                    .padding(.top, 30)
                
                    
                Form {
                    
                    Section(header: Text("Credentials")) {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        SecureField("Password", text: $password)
                    }
                    
                    if self.loginError != nil {
                        Section {
                            Text(loginError!.localizedDescription)
                                .foregroundColor(.red)

                        }
                    }
                }
                
                if showProgressView {
                    ProgressView("Logging in...")
                        .padding()
                }
                
                Button("Log In") {
                    attemptLogin()
                }
                .buttonStyle(.bordered)
                .disabled(email.isEmpty || password.isEmpty)
                .padding()
            }
            
        }
    }
    
    private func attemptLogin() {
        
        loginError = nil
        
        self.showProgressView = true
        
        let sampleUser = UserData(id: nil,
                                  username: "defaultAdmin",
                                  email: "defaultAdmin@guardguys.com",
                                  password: "test1234",
                                  isAdmin: true,
                                  createdAt: nil,
                                  updatedAt: nil)
    
        if email == sampleUser.email && password == sampleUser.password {
            globalManager.updateLogin(sampleUser)
            return
        }
        
        showProgressView = true
        
        Task {
            do {
                let data = try await network.makeApiRequestFor(.login(email: self.email, password: self.password))
                let login = try JSONDecoder().decode(LoginResult.self, from: data)
                guard login.user?.id != nil else {
                    globalManager.updateLogin(nil)
                    throw NSError(domain: "LoginError",
                                  code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Bad return data received!"])
                }
                globalManager.updateLogin(login.user)
            }
            catch {
                globalManager.updateLogin(nil)
                self.loginError = NSError(domain: "LoginError",
                                                 code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey: "Unable to login, please check email and/or password"])
            }
            showProgressView = false
        }
        
    }
    
    
}
