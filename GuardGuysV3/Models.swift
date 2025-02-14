//
//  Models.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//

import SwiftUI

// MARK: - Models

public struct ScheduleEvent: Codable, Identifiable {
    // Coding keys map the JSON keys from your API
    enum CodingKeys: String, CodingKey {
        case id, date, event, onsite, notes, duration, createdAt, updatedAt, user
        case userId = "user_id"
    }
    
    // Use the API’s id as the Identifiable property.
    public let id: Int
    public let date: String
    public let event: String
    public let onsite: Bool
    public let notes: String
    public let duration: Int64
    public let userId: Int?
    public let createdAt: String
    public let updatedAt: String
    public let user: UserData?
    
    // Helper: Convert the ISO8601 string to a Date.
    var eventDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: self.date)
    }

    var startDate: String? {
        eventDate?.toString()
    }
    var startTime: String? {
        eventDate?.timeString()
    }
   
    var endTime: String? {
        guard duration > 0 else { return nil }
        return eventDate?.adding(microseconds: duration)?.timeString()
    }
    
}

public struct UserData: Codable {
    public let id: Int?
    public let username: String?
    public let email: String?
    public let password: String?
    public let isAdmin: Bool?
    public let createdAt: String?
    public let updatedAt: String?
}
