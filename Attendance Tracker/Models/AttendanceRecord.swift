//
//  AttendanceRecord.swift
//  Attendance Tracker
//
//  Created by Pranav Nithesh J on 25/10/24.
//

import Foundation
import SwiftUI

/// Represents an attendance record for a specific date with a status
struct AttendanceRecord: Codable {
    let date: Date
    var status: AttendanceStatus?
}

/// Enum to define the attendance status for a particular day
enum AttendanceStatus: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    
    case office = "Office"
    case wfh = "WFH"
    case leave = "Leave"
    case holiday = "Holiday"
    case noSelection = "No Selection"
        
    var color: Color {
        switch self {
        case .office:
            return Color.green
        case .wfh:
            return Color.blue
        case .leave:
            return Color.purple
        case .holiday:
            return Color.orange
        case .noSelection:
            return Color.clear
        }
    }
}
