//
//  NotificationService.swift
//  Attendance Tracker
//
//  Created by Pranav Nithesh J on 25/10/24.
//

import UserNotifications

/// Service responsible for scheduling notifications
class NotificationService {
    
    static func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Attendance Reminder"
        content.body = "Please mark your attendance for today."
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 17
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "AttendanceReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
