import SwiftUI

struct DayView: View {
    @State private var selectedDate: Date = Date()
    
    @ObservedObject var viewModel: EventsViewModel
    
    @State private var showingAddEvent = false
    @State private var currentWeekStart: Date?
    @State private var selectedEvent: ScheduleEvent? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                dayNavigationControlBar
                eventsList
               .navigationTitle("Day View")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { selectedDate = Date() } label: {
                            Text("Today")
                        }.disabled(selectedDate.toString() == Date().toString())
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingAddEvent.toggle()
                        } label: { Image(systemName: "plus") }
                    }
                }
                .sheet(isPresented: $showingAddEvent) {
                    AddEventView(viewModel: viewModel, defaultDate: selectedDate, event: viewModel.selectedEvent)
                        .onDisappear { viewModel.selectedEvent = nil }
                }
                .onAppear {
                    loadWeekIfNeeded()
                }
                .onChange(of: selectedDate) { _, _ in
                    loadWeekIfNeeded()
                }
            }
        }
    }
    
    private var dayNavigationControlBar: some View {
        HStack {
            Button(action: {
                if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                    selectedDate = newDate
                }
            }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(selectedDate, format: .dateTime
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day()
                .year())
                .font(.headline)

            Spacer()
            Button(action: {
                if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                    selectedDate = newDate
                }
            }) {
                Image(systemName: "chevron.right")
            }
        }.padding()
    }
    private var eventsList: some View {
        
        ZStack {
            
            let dayEvents = viewModel.events(for: selectedDate).sorted(by: {$0.eventDate ?? Date() < $1.eventDate ?? Date()})
            
            ScrollViewReader { proxy in
                
                List {
                    ForEach(dayEvents, id:\.id) { event in
                        EventRowView(event: event) {
                            viewModel.selectedEvent = event
                            self.showingAddEvent = true
                        }.id(event.id)
                    }
                    .onDelete { indexSet in
                        let eventsForDay = viewModel.events(for: selectedDate)
                        indexSet.forEach { index in
                            let event = eventsForDay[index]
                            viewModel.deleteEvent(event)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if dayEvents.isEmpty {
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
                .onChange(of: selectedDate) { _, _ in
                    proxy.scrollTo(dayEvents.first?.id, anchor: .top)
                }
            }
        }
    }
    private func loadWeekIfNeeded() {
        let weekStart = selectedDate.startOfWeek()
        if currentWeekStart == nil || !Calendar.current.isDate(weekStart, inSameDayAs: currentWeekStart!) {
            currentWeekStart = weekStart
            viewModel.loadEventsForWeek(for: weekStart)
        }
    }
}
