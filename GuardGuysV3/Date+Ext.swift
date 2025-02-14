//
//  Date+Ext.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//

import Foundation


public extension Date {
    
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter.string(from: self)
    }
    func timeString() -> String {
        let formatter = DateFormatter()
           formatter.dateFormat = "hh:mm a"  // "HH" for 24-hour format; use "hh" for 12-hour format.
           return formatter.string(from: self)
    }
    func adding(microseconds: Int64) -> Date? {
        let seconds = Int(microseconds / 1000)
        return Calendar.current.date(byAdding: .second, value: seconds, to: self)
        }
    func startOfWeek(using calendar: Calendar = Calendar.current) -> Date {
           var calendar = calendar
           calendar.firstWeekday = 2 // Monday; change this value if needed.
           let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
           return calendar.date(from: components) ?? Date()
       }
    
    var nextWholeHour: Date {
            let calendar = Calendar.current
            // Get the current date’s year, month, day, and hour.
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
            // Create a date at the top of the current hour.
            guard let currentHour = calendar.date(from: components) else { return self }
            // Always add one hour.
            return calendar.date(byAdding: .hour, value: 1, to: currentHour)!
        }
}
