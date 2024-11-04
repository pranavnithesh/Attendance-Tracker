//
//  AttendanceTrackerViewModel.swift
//  Attendance Tracker
//
//  Created by Pranav Nithesh J on 25/10/24.
//

import SwiftUI
import Foundation
import UserNotifications

/// ViewModel for AttendanceTrackerView, handling state and business logic
class AttendanceTrackerViewModel: ObservableObject {
    
    @Published var currentDate = Date()
    @Published var records: [AttendanceRecord] = []
    @Published var attendancePercentage: Double = 0.0
    @Published var requiredDays: Int = 0
    @Published var selectedDate: Date? = nil
    
    @Published var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")! // UTC+5:30
        calendar.locale = Locale(identifier: "en_IN")
        return calendar
    }()
    
    // DateFormatter for displaying the month
    @Published var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    init() {
        loadAttendanceRecords()
        calculateAttendancePercentage()
        NotificationService.scheduleDailyNotification()
    }
    
    /// Function to store dates in UserDefaults
    func storeDatesInUserDefaults(dates: [AttendanceRecord]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(dates)
            UserDefaults.standard.set(data, forKey: "attendanceRecords")
        } catch {
            print("Failed to encode and store records: \(error)")
        }
    }
    
    func formattedDate(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy" // Format: day month year
        return dateFormatter.string(from: date)
    }
    
    /// Function to retrieve dates from UserDefaults
    func retrieveDatesFromUserDefaults() -> [AttendanceRecord] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = UserDefaults.standard.data(forKey: "attendanceRecords") else {
            return []
        }
        do {
            return try decoder.decode([AttendanceRecord].self, from: data)
        } catch {
            print("Failed to decode records: \(error)")
            return []
        }
    }
    
    func getNumberOfDays(for status: AttendanceStatus) -> Int {
        let lastWeeksRange = getLastWeeksRange()
        return records.filter { $0.status == status && lastWeeksRange.contains(formatDate($0.date))}.count
    }
    
    func calculateAttendancePercentage() {
        let lastWeeksRange = getLastWeeksRange()
        let totalDays = records.filter { record in
            let weekday = calendar.component(.weekday, from: record.date)
            return weekday != 1 && weekday != 7 && record.status != .wfh && lastWeeksRange.contains(formatDate(record.date))
        }.count
        let attendedDays = records.filter { ($0.status == .office || $0.status == .leave || $0.status == .holiday) && lastWeeksRange.contains(formatDate($0.date)) }.count
        attendancePercentage = totalDays > 0 ? Double(attendedDays) / Double(totalDays) * 100 : 0
        requiredDays = calculateRequiredDays()
    }
    
    /// Function to calculate required days to maintain 60% attendance
    private func calculateRequiredDays() -> Int {
        let days = getLastWeeksRangeForRequiredDays()
        let totalDays = records.filter { record in
            let weekday = calendar.component(.weekday, from: record.date)
            return weekday != 1 && weekday != 7 && record.status != .wfh && days.contains(formatDate(record.date))
        }.count
        
        let minimumAttendedDays = Int(ceil(Double(totalDays) * 0.6))
        let attendedDays = records.filter { ($0.status == .office || $0.status == .leave || $0.status == .holiday) && days.contains(formatDate($0.date))}.count
        return max(minimumAttendedDays - attendedDays, 0)
    }
    
    func loadAttendanceRecords() {
        let today = Date()
        records = retrieveDatesFromUserDefaults()
        let lastFriday = getFriday(from: today)
        let firstFriday = calendar.date(byAdding: .weekOfYear, value: -13, to: lastFriday)!
        let startDate = calendar.date(byAdding: .day, value: 3, to: firstFriday)!
        getAllDatesBetween(startDate: startDate, endDate: lastFriday)
    }
    
    /// Function to generate a range for the last 12 weeks
    func getLastWeeksRange() -> [String] {
        let today = Date()
        let lastFriday = getLastFriday(from: today)
        let firstFriday = calendar.date(byAdding: .weekOfYear, value: -12, to: lastFriday)!
        let startDate = calendar.date(byAdding: .day, value: 2, to: firstFriday)!
        var dates: [String] = []
        var currentDate = startDate
        while currentDate <= lastFriday {
            dates.append(formatDate(currentDate))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
    
    func getFirstAndLastDay() -> (String, String) {
        let today = Date()
        let endDate = getLastFriday(from: today)
        let firstFriday = calendar.date(byAdding: .weekOfYear, value: -12, to: endDate)!
        let startDate = calendar.date(byAdding: .day, value: 3, to: firstFriday)!
        let formattedStartDate = formattedDate(from: startDate)
        let formattedEndDate = formattedDate(from: endDate)
        return (formattedStartDate, formattedEndDate)
    }
    
    func daysInMonth() -> [Date] {
        return calendar.generateDates(of: currentDate)
    }
    
    func startingWeekday() -> Int {
        let firstDay = firstDayOfMonth()
        return calendar.component(.weekday, from: firstDay) - 1
    }
    
    // Function to calculate the range of dates for the last 12 weeks
    func getLast12WeeksRange() -> [String] {
        let today = Date()
        let lastFriday = getFriday(from: today)
        let firstFriday = calendar.date(byAdding: .weekOfYear, value: -13, to: lastFriday)!
        let startDate = calendar.date(byAdding: .day, value: 2, to: firstFriday)!
        var dates: [String] = []
        var currentDate = startDate
            while currentDate <= lastFriday {
                dates.append(formatDate(currentDate))
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            return dates
    }
    
    func formatDate(_ date: Date, format: String = "dd MMM yyyy") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone =  TimeZone(identifier: "Asia/Kolkata")
        dateFormatter.locale = Locale(identifier: "en_IN")
        return dateFormatter.string(from: date)
    }
    
    func getLastWeeksRangeForRequiredDays() -> [String] {
        let today = Date()
        let lastFriday = getFriday(from: today)
        let firstFriday = calendar.date(byAdding: .weekOfYear, value: -12, to: lastFriday)!
        let startDate = calendar.date(byAdding: .day, value: 3, to: firstFriday)!
        var dates: [String] = []
        
        var currentDate = startDate
            while currentDate <= lastFriday {
                dates.append(formatDate(currentDate))
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }

            return dates
    }
    
    func isToday(date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    func getCurrentDay(date: Date) -> Int {
        return calendar.component(.day, from: date)
    }
    
    func getStatus(for date: Date) -> AttendanceStatus? {
        return records.first(where: { calendar.isDate($0.date, inSameDayAs: date) })?.status
    }
    
    func isWeekday(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        // 1 = Sunday, 2 = Monday, ..., 6 = Friday, 7 = Saturday
        return weekday >= 2 && weekday <= 6
    }
    
    func getFriday(from date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        var daysToLastFriday = 0
        switch weekday {
        case 2: // Monday
            daysToLastFriday = 4
        case 3: // Tuesday
            daysToLastFriday = 3
        case 4: // Wednesday
            daysToLastFriday = 2
        case 5: // Thursday
            daysToLastFriday = 1
        case 6: // Friday
            daysToLastFriday = 0
        case 7: // Saturday
            daysToLastFriday = -1
        case 1: // Sunday
            daysToLastFriday = -2
        default:
            daysToLastFriday = 0 // Fallback
        }
        return calendar.date(byAdding: .day, value: daysToLastFriday, to: date)!
    }
    
    func getAllDatesBetween(startDate: Date, endDate: Date) {
        var dates: [AttendanceRecord] = []
        
        // Make sure startDate is before endDate
        var currentDate = startDate
        
        while currentDate <= endDate {
            if let index = records.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }) {
                dates.append(AttendanceRecord(date: currentDate, status: records[index].status))
            } else {
                dates.append(AttendanceRecord(date: currentDate, status: nil))
            }
            // Move to the next day
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            }
        }
        records = dates
        storeDatesInUserDefaults(dates: dates)
    }
    
    func getLastFriday(from date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        var daysToLastFriday = 0
        switch weekday {
        case 2: // Monday
            daysToLastFriday = 3
        case 3: // Tuesday
            daysToLastFriday = 4
        case 4: // Wednesday
            daysToLastFriday = 5
        case 5: // Thursday
            daysToLastFriday = 6
        case 6: // Friday
            daysToLastFriday = 7
        case 7: // Saturday
            daysToLastFriday = 8
        case 1: // Sunday
            daysToLastFriday = 9
        default:
            daysToLastFriday = 0 // Fallback
        }
        return calendar.date(byAdding: .day, value: -daysToLastFriday, to: date)!
    }
    
    func firstDayOfMonth() -> Date {
        return calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
    }
    
    func updateAttendance(for date: Date, with status: AttendanceStatus) {
        if let index = records.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            records[index].status = status
            calculateAttendancePercentage()
            storeDatesInUserDefaults(dates: records)
        }
    }
}
