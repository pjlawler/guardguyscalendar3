//
//  ContentView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//
import SwiftUI
import PDFKit


struct ContentView: View {
    
    
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject private var globalManager: GlobalManager
    
    @StateObject var eventsViewModel = EventsViewModel()
    @StateObject var usersViewModel = UsersViewModel()
    
    @State var pdfFile: URL?
    @State var showPDF: Bool = false
    @State var pdfDocument: PDFDocument?
    
    let viewer = PDFView()
    
    let downloader = ApproachDownloader()
    let url = URL(string: "https://files.testfile.org/PDF/200MB-TESTFILE.ORG.pdf")!
    
    
    private let network = NetworkManager.shared
   
    var body: some View {
        ZStack {
            switch globalManager.isLoggedIn {
            case false: LoginView()
            case true: tabbedView
            }
        }
        .fullScreenCover(isPresented: $showPDF, content: {
            ApproachPDFViewer(document: $pdfDocument)
        })
        .onChange(of: scenePhase) { oldValue, newValue in
            switch (oldValue, newValue) {
            case (.inactive, .active):
                print("checking credentials!")
                globalManager.checkuserCredentials()
            default: break
            }
        }
        .onAppear {
            
//            downloader.downloadFile(fromURL: url) { amount in
//                print("\(amount)%")
//            } fileLocation: { resut in
//                switch resut {
//                case .success(let url):
//                    do {
//                        let data = try downloader.convertToData()
//                        Task {
//                            DispatchQueue.main.async {
//                                self.pdfDocument = PDFDocument(data: data!)
//                                self.showPDF = true
//                            }
//                        }
//                    }
//                    catch {
//                        print(error)
//                    }
//                case .failure(let err):
//                    print("failed to download file: \(err)")
//                }
//            }
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


struct ApproachPDFViewer: UIViewRepresentable {
    
    @Binding var document: PDFDocument?
    
    func makeUIView(context: Context) -> PDFView {
        return PDFView(frame: .infinite)
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        guard let document = document else { return }
        uiView.document = document
        uiView.autoScales = true
        uiView.displayMode = .singlePageContinuous
    }
    
}
