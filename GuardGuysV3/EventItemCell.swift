//
//  EventItemCell.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//


import SwiftUI

struct EventItemCell: View {
    
    var event: ScheduleEvent
    var tapHandler: (()->())?
    
    var body: some View {
        
        VStack(spacing: 10) {
            // Display the time range.
            HStack {
                eventTimes
                if event.onsite { onSiteLabel }
                Spacer()
                assignedToLabel
            }
            .frame(height: 20)
            .lineLimit(1)
            .font(.footnote)
            
            eventTitle
            eventNotes
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { self.tapHandler?() }
    }
    
    var eventTimes: some View {
        ZStack {
            switch (event.startTime, event.endTime) {
            case let (start?, end?): Text("\(start) - \(end)")
            case let (start?, _): Text("\(start)")
            default: EmptyView()
            }
        }
    }
    var onSiteLabel: some View {
        Text("On-Site").foregroundColor(.green)
            .frame(maxHeight: .infinity, alignment: .center)
            .bold()
    }
    var assignedToLabel: some View {
        ZStack {
            if let assigned = event.user?.username { Text(assigned).foregroundColor(.blue).bold() }
            else { Text("Unassigned").foregroundColor(.red).bold().italic(true) }
        }
    }
    var eventTitle: some View {
        Text("\(event.event)")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .lineSpacing(8)
            .bold()
    }
    var eventNotes: some View {
        Text("\(event.notes)")
            .font(.caption2)
            .italic(true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .lineSpacing(4)
    }
}
