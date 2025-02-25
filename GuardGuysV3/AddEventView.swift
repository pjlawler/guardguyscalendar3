import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EventsViewModel
    
    // State for the user picker.
    @State private var selectedUserId: Int? = nil
    
    // State properties for the event.
    @State private var eventName: String = ""
    @State private var eventDate: Date
    @State private var eventNotes: String = ""
    @State private var eventDuration: Int64 = 3600  // 1 hour by default.
    @State private var onsite: Bool = false
    
    let eventToEdit: ScheduleEvent?
    
    init(viewModel: EventsViewModel, defaultDate: Date, event: ScheduleEvent? = nil) {
        self.viewModel = viewModel
        self.eventToEdit = event
    
        if let event = event {
            // Editing an existing event: prepopulate the form with its data.
            _eventName = State(initialValue: event.event)
            _eventDate = State(initialValue: event.eventDate ?? defaultDate.nextWholeHour)
            _eventNotes = State(initialValue: event.notes)
            _eventDuration = State(initialValue: event.duration)
            _onsite = State(initialValue: event.onsite)
            _selectedUserId = State(initialValue: event.userId)
        } else {
            // Adding a new event: use the next whole hour relative to the default date.
            _eventDate = State(initialValue: defaultDate.nextWholeHour)
            _eventName = State(initialValue: "")
            _eventNotes = State(initialValue: "")
            _eventDuration = State(initialValue: 900000)
            _onsite = State(initialValue: false)
            _selectedUserId = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Event Info")) {
                    TextField("Event", text: $eventName)
                        .frame(minHeight: 50, maxHeight: .infinity, alignment: .top)
                    DatePicker("Date & Time", selection: $eventDate)
                    Stepper(value: $eventDuration, in: 60_000...8_640_000, step: 60_000) {
                        Text("Duration: \(Int(eventDuration / 60_000)) minutes")
                    }
                    Toggle("Onsite", isOn: $onsite)
                    
                    // Picker for assigning a user.
                    Picker("Assign User", selection: $selectedUserId) {
                        Text("None").tag(nil as Int?)
                        ForEach(viewModel.users, id: \.id) { user in
                            Text(user.username ?? "Unknown").tag(user.id)
                        }
                    }
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $eventNotes)
                        .frame(minHeight: 50, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle(eventToEdit == nil ? "Add Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        
                        if let event = eventToEdit {
                            // Editing an existing event.
                            let updatedEvent = ScheduleEvent(
                                id: event.id,
                                date: eventDate.apiString(),
                                event: eventName,
                                onsite: onsite,
                                notes: eventNotes,
                                duration: Int64(eventDuration),
                                userId: selectedUserId,
                                createdAt: event.createdAt, // Preserve original creation date.
                                updatedAt: Date().apiString(),
                                user: nil
                            )
                            viewModel.updateEvent(updatedEvent)
                        } else {
                            // Creating a new event.
                            let newEvent = ScheduleEvent(
                                id: 0,  // API/backend will assign a proper id.
                                date: eventDate.apiString(),
                                event: eventName,
                                onsite: onsite,
                                notes: eventNotes,
                                duration: Int64(eventDuration),
                                userId: selectedUserId,
                                createdAt: Date().apiString(),
                                updatedAt: Date().apiString(),
                                user: nil
                            )
                            viewModel.addEvent(newEvent)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadUsers()
            }
        }
    }
    
}
