//
//  DateNavigator.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/14/25.
//

import SwiftUI

struct DateNavigator: View {
    
    @ObservedObject var viewModel: EventsViewModel
    let displayModel: DisplayMode
   
    var body: some View {
        HStack {
            Button(action: { updateDateNavigator(-1)}) { Image(systemName: "chevron.left") }
            Spacer()
            DateDisplay(displayMode: displayModel, date: viewModel.selectedDate).font(.headline)
            Spacer()
            Button(action: { updateDateNavigator(1)}) { Image(systemName: "chevron.right") }
        }
        .padding()
    }
   
    private func updateDateNavigator(_ int: Int) {
        let component: Calendar.Component = displayModel == .day ? .day : .weekOfYear
        if let newDate = Calendar.current.date(byAdding: component, value: int, to: viewModel.selectedDate) {
            viewModel.selectedDate = newDate
        }
    }
    
    struct DateDisplay: View {
        
        let displayMode: DisplayMode
        let date: Date
        
        var body: some View {
            ZStack {
                switch displayMode {
                case .day:
                    return Text(date, format: .dateTime
                        .weekday(.abbreviated)
                        .month(.abbreviated)
                        .day()
                        .year())
                        
                case .week:
                    guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return Text("") }
                    return Text("\(weekInterval.start, format: .dateTime.month().day()) - \(weekInterval.end, format: .dateTime.month().day())")
                }
            }
        }
    }
    
    enum DisplayMode {
        case day
        case week
    }
}
