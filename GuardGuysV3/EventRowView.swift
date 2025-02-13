//
//  EventRowView.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//


import SwiftUI

struct EventRowView: View {
    
    var event: ScheduleEvent
    var tapHandler: (()->())?
    
    var body: some View {
        
        VStack(spacing: 10) {
            // Display the time range.
            HStack(alignment: .top) {
                switch (event.startTime, event.endTime) {
                case let (start?, end?): Text("\(start) - \(end)")
                case let (start?, _): Text("\(start)")
                default: EmptyView()
                }
                if event.onsite {
                    Text("On-Site").foregroundColor(.green).bold().italic(true)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
                Spacer()
                if let assigned = event.user?.username {
                    Text(assigned).foregroundColor(.blue).bold()
                }
                else { Text("Unassigned").foregroundColor(.red).bold().italic(true) }
                
            }
            .frame(height: 20)
            .lineLimit(1)
            .font(.callout)
            
            Text("\(event.event)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineSpacing(8)
           
            Text("\(event.notes)")
                .font(.footnote)
                .italic(true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            self.tapHandler?()
        }
        
    }
    
    
}
