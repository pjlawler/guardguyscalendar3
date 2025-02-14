import SwiftUI

struct WeekView: View {
    
    @ObservedObject var viewModel: EventsViewModel
    @State var showingAddEvent = false
    
    var body: some View {
        NavigationStack {
            VStack {
                DateNavigator(viewModel: viewModel, displayModel: .week)
                eventsList
                    .navigationTitle("Events for Week")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { viewModel.selectedDate = Date().startOfWeek() } label: {
                                Text("Current Week")
                            }.disabled(viewModel.selectedDate == Date().startOfWeek())
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { self.showingAddEvent.toggle() } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddEvent) {
                        AddEventView(viewModel: viewModel, defaultDate: viewModel.selectedDate, event: viewModel.selectedEvent)
                            .onDisappear { viewModel.selectedEvent = nil }
                    }
                    .onAppear {
                        viewModel.loadWeekIfNeeded()
                    }
                    .onChange(of: viewModel.selectedDate) { _, _ in
                        viewModel.loadWeekIfNeeded()
                    }
                    .refreshable {
                        viewModel.loadEventsForWeek(for: viewModel.selectedDate)
                    }
            }
            
        }
    }
    
    private var eventsList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(viewModel.sortedDates, id: \.self) { date in
                    Section(header: Text(date, format: .dateTime.weekday(.abbreviated).month().day())) {
                        // Sort events for this date by their start time.
                        let eventsForDate = viewModel.groupedEvents[date]?.sorted(by: {
                            guard let s1 = $0.startDate, let s2 = $1.startDate else { return false }
                            return s1 < s2
                        }) ?? []
                        
                        ForEach(eventsForDate) { event in
                            EventItemCell(event: event) { self.handleItemTapped(event: event) }
                        }
                        .onDelete { viewModel.deleteItems(indexSet: $0) }
                    }
                }.id("top")
            }
            .overlay(alignment: .top) {
                if viewModel.eventsForWeek.isEmpty {
                    Text("No Events Scheduled")
                        .font(.headline)
                        .padding(.top, 30)
                }
                if viewModel.isLoading {
                    ZStack {
                        Color.clear
                        ProgressView()
                    }.background(.ultraThinMaterial)
                }
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }
    
    func handleItemTapped(event: ScheduleEvent) {
        viewModel.selectedEvent = event
        self.showingAddEvent = true
    }
}
