import Foundation
import Combine

final class EventsViewModel: ObservableObject {
    
    @Published var eventsForWeek: [ScheduleEvent] = []
    @Published var isLoading: Bool = false
    @Published var users: [UserData] = []
    
    let network = NetworkManager.shared
    
    var selectedEvent: ScheduleEvent? = nil
    
    func loadEventsForWeek(for weekOf: Date) {
        self.isLoading = true
        network.makeApiRequestFor(.getEvents(date: weekOf.startOfWeek())) { result in
            self.isLoading = true
            switch result {
            case .success(let data):
                self.isLoading = false
                guard let events = try? JSONDecoder().decode([ScheduleEvent].self, from: data) else {
                    self.eventsForWeek = []
                    return
                }
                self.eventsForWeek = events
            case .failure(let error):
                print("Error loading events for week: \(error)")
                self.eventsForWeek = []
            }
        }
    }
    func events(for day: Date) -> [ScheduleEvent] {
        let calendar = Calendar.current
        return eventsForWeek.filter { event in
            guard let startDate = event.eventDate else { return false }
            return calendar.isDate(startDate, inSameDayAs: day)
        }
    }
    func loadUsers() {
        self.isLoading = true
        network.makeApiRequestFor(.getMembers) { result in
            switch result {
            case .success(let data):
                self.isLoading = false
                if let users = try? JSONDecoder().decode([UserData].self, from: data) {
                    self.users = users
                }
                else {
                    self.users = []
                }
                
            case .failure(let error):
                self.isLoading = false
                self.users = []
                print("Error loading users: \(error)")
            }
        }
    }
    
    // MARK: - CRUD Methods (unchanged)
    func addEvent(_ event: ScheduleEvent) {
        
        let currentDate = event.eventDate ?? Date()
        
        let addItem = SubmitEvent(event: event.event,
                                  date: event.date,
                                  duration: event.duration,
                                  onsite: event.onsite,
                                  userId: event.userId ?? -1,
                                  notes: event.notes)
        
        self.isLoading = true
        
        network.makeApiRequestFor(.addEvent(data: addItem)) { result in
            switch result {
            case .success(let data):
                self.loadEventsForWeek(for: currentDate)
                data.consolePrintAsJson()
            case .failure(let error):
                self.isLoading = false
                print("Error loading events for week: \(error)")
            }
        }
    }
    func updateEvent(_ event: ScheduleEvent) {
        
        let currentDate = event.eventDate ?? Date()
        
        let editItem = SubmitEvent(event: event.event,
                                  date: event.date,
                                  duration: event.duration,
                                  onsite: event.onsite,
                                  userId: event.userId ?? -1,
                                  notes: event.notes)
        
        self.isLoading = true
        
        network.makeApiRequestFor(.editEvent(id: event.id, data: editItem)) { result in
            switch result {
            case .success(let data):
                self.loadEventsForWeek(for: currentDate)
                data.consolePrintAsJson()
            case .failure(let error):
                self.isLoading = false
                print("Error loading events for week: \(error)")
            }
        }
    }
    func deleteEvent(_ event: ScheduleEvent) {
        
        let currentDate = event.eventDate ?? Date()
        
        self.isLoading = true
        
        network.makeApiRequestFor(.deleteEvent(id: event.id)) { result in
            switch result {
            case .success(let data):
                self.loadEventsForWeek(for: currentDate)
                data.consolePrintAsJson()
            case .failure(let error):
                self.isLoading = false
                print("Error loading events for week: \(error)")
            }
        }
    }
}
