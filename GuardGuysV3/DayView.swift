import SwiftUI

struct DayView: View {
   
    @ObservedObject var viewModel: EventsViewModel
    @State var showingAddEvent = false
    
    var body: some View {
        NavigationStack {
            VStack {
                DateNavigator(viewModel: viewModel, displayModel: .day)
                eventsList
               .navigationTitle("Events for Day")
               .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { viewModel.selectedDate = Date() } label: {
                            Text("Today")
                        }.disabled(viewModel.selectedDate.toString() == Date().toString())
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { self.showingAddEvent.toggle()
                        } label: { Image(systemName: "plus") }
                    }
                }
                .sheet(isPresented:$showingAddEvent) {
                    AddEventView(viewModel: viewModel, defaultDate: viewModel.selectedDate, event: viewModel.selectedEvent)
                        .onDisappear { viewModel.selectedEvent = nil }
                }
                .onAppear {
                    viewModel.loadWeekIfNeeded()
                }
                .onChange(of: viewModel.selectedDate) { _, _ in
                    viewModel.loadWeekIfNeeded()
                }
            }
        }
    }
    
    func handleItemTapped(event: ScheduleEvent) {
        viewModel.selectedEvent = event
        self.showingAddEvent = true
    }
    

    private var eventsList: some View {
        
        ZStack {
            
            let dayEvents = viewModel.events(for: viewModel.selectedDate).sorted(by: {$0.eventDate ?? Date() < $1.eventDate ?? Date()})
            
            ScrollViewReader { proxy in
                List {
                    ForEach(dayEvents, id:\.id) { event in
                        EventItemCell(event: event) { self.handleItemTapped(event: event) }.id(event.id)
                    }
                    .onDelete { viewModel.deleteItems(indexSet: $0) }
                }
                .overlay(alignment: .top) {
                    if dayEvents.isEmpty { emptyState }
                    if viewModel.isLoading { loadingScreen }
                }
                .onChange(of: viewModel.selectedDate) { _, _ in
                    proxy.scrollTo(dayEvents.first?.id, anchor: .top)
                }
            }
        }
    }
    private var emptyState: some View {
        Text("No Events Scheduled")
            .font(.headline)
            .padding(.top, 30)
    }
    private var loadingScreen: some View {
        ZStack {
            Color.clear
            ProgressView()
        }.background(.ultraThinMaterial)
    }
   
}
