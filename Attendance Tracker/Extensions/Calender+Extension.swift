//
//  Calender+Extension.swift
//  Attendance Tracker
//
//  Created by Pranav Nithesh J on 25/10/24.
//

import Foundation

//Extension to generate dates for a given range
extension Calendar {
   
   func generateDates(of monthDate: Date) -> [Date] {
       let timeZone = TimeZone(identifier: "Asia/Kolkata")! // Set to UTC+5:30
       var calendar = Calendar.current
       calendar.timeZone = timeZone

       // Get the range of days in the month of the given date
       let monthRange = calendar.range(of: .day, in: .month, for: monthDate)!
       
       // Extract the year and month from the given date
       let components = calendar.dateComponents([.year, .month], from: monthDate)

       // Generate all dates in that month
       var dates: [Date] = []
       for day in monthRange {
           var dayComponents = DateComponents()
           dayComponents.year = components.year
           dayComponents.month = components.month
           dayComponents.day = day
           if let date = calendar.date(from: dayComponents) {
               dates.append(date)
           }
       }
       return dates
   }
}
