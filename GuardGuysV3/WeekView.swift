import SwiftUI

struct WeekView: View {
    @State private var selectedDate: Date = Date() // Determines the current week.
    @ObservedObject var viewModel: EventsViewModel
    @State private var showingAddEvent = false
    @State private var currentWeekStart: Date?
    
    /// Groups events by their start day.
    var groupedEvents: [Date: [ScheduleEvent]] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: viewModel.eventsForWeek) { event in
            guard let eventDate = event.eventDate else { return Date.distantPast }
            return calendar.startOfDay(for: eventDate)
        }
        return groups
    }
    
    /// Sorted keys (dates) for display order.
    var sortedDates: [Date] {
        groupedEvents.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header with previous/next week buttons.
                HStack {
                    Button(action: {
                        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    if let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) {
                        Text("\(weekInterval.start, format: .dateTime.month().day()) - \(weekInterval.end, format: .dateTime.month().day())")
                            .font(.headline)
                    }
                    Spacer()
                    Button(action: {
                        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                
                // List grouped events by date.
                ScrollViewReader { proxy in
                    List {
                        ForEach(sortedDates, id: \.self) { date in
                            Section(header: Text(date, format: .dateTime.weekday(.abbreviated).month().day())) {
                                // Sort events for this date by their start time.
                                let eventsForDate = groupedEvents[date]?.sorted(by: {
                                    guard let s1 = $0.startDate, let s2 = $1.startDate else { return false }
                                    return s1 < s2
                                }) ?? []
                                
                                ForEach(eventsForDate) { event in
                                    EventRowView(event: event) {
                                        viewModel.selectedEvent = event
                                        self.showingAddEvent.toggle()
                                    }
                                }
                                .onDelete { indexSet in
                                    // When deleting, find the proper event from the sorted list.
                                    let sortedEvents = eventsForDate
                                    indexSet.forEach { index in
                                        let event = sortedEvents[index]
                                        viewModel.deleteEvent(event)
                                    }
                                }
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
                    .onChange(of: self.selectedDate) { _, _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .navigationTitle("Week View")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { selectedDate = Date().startOfWeek() } label: {
                        Text("Current Week")
                    }.disabled(selectedDate == Date().startOfWeek())
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddEvent.toggle() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(viewModel: viewModel, defaultDate: selectedDate, event: viewModel.selectedEvent)
                    .onDisappear {
                        viewModel.selectedEvent = nil
                    }
            }
            .onAppear {
                loadWeekIfNeeded()
            }
            .onChange(of: selectedDate) { _, _ in
                loadWeekIfNeeded()
            }
        }
    }
    
    /// Checks if the week has changed; if so, loads events for the new week.
    private func loadWeekIfNeeded() {
        let weekStart = selectedDate.startOfWeek()
        if currentWeekStart == nil || !Calendar.current.isDate(weekStart, inSameDayAs: currentWeekStart!) {
            currentWeekStart = weekStart
            viewModel.loadEventsForWeek(for: selectedDate)
        }
    }
}
