//
//  Attendance_TrackerApp.swift
//  Attendance Tracker
//
//  Created by Pranav Nithesh J on 25/10/24.
//

import SwiftUI
import UserNotifications

@main
struct Attendance_TrackerApp: App {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AttendanceTrackerView()
        }
    }
}
