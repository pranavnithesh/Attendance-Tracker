//
//  AttendanceTrackerView.swift
//  Attendance Tracker
//
//  Created by Pranav Nithesh J on 25/10/24.
//

import Foundation
import SwiftUI

/// View to display the attendance tracker calendar and related UI elements
struct AttendanceTrackerView: View {
    
    @ObservedObject var viewModel = AttendanceTrackerViewModel()
    @State private var showingDialog = false
    @State private var selectedAttendanceDate: Date? = nil
    @State private var showSummary = false
    
    var body: some View {
        VStack {
            Text("Attendance Tracker")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)
                .padding(.bottom)
            headerView
            weekdayHeader
            calendarGrid
            attendancePercentageView
            Text("Days needed this week to maintain 60%: \(viewModel.requiredDays)")
                .foregroundColor(.purple)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .confirmationDialog("Select Attendance", isPresented: $showingDialog, titleVisibility: .visible) {
            Button("Office") {
                viewModel.updateAttendance(for: selectedAttendanceDate!, with: .office)
            }
            Button("Leave") {
                viewModel.updateAttendance(for: selectedAttendanceDate!, with: .leave)
            }
            Button("Holiday") {
                viewModel.updateAttendance(for: selectedAttendanceDate!, with: .holiday)
            }
            Button("WFH") {
                viewModel.updateAttendance(for: selectedAttendanceDate!, with: .wfh)
            }
            Button("No Selection") {
                viewModel.updateAttendance(for: selectedAttendanceDate!, with: .noSelection)
            }
            Button("Cancel", role: .cancel) { }
        }
        .padding()
    }
    
    private var summaryView: some View {
        let statuses = AttendanceStatus.allCases
        let (stsrtDate, endDate) = viewModel.getFirstAndLastDay()
        return HStack {
            VStack(alignment: .leading) {
                Text("Summary")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(.bottom)
                Text("Attendance recorded from \(stsrtDate) to \(endDate)")
                    .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                    .font(.headline)
                    .foregroundColor(.red)
                ForEach(statuses) { status in
                    if status != .noSelection {
                        HStack {
                            Rectangle()
                                .fill(status.color)
                                .frame(width: 15, height: 15)
                            Text("\(status.rawValue) - \(viewModel.getNumberOfDays(for: status)) Day(s)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.bottom)
            .padding(.leading)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                if let previousMonth = viewModel.calendar.date(byAdding: .month, value: -1, to: viewModel.currentDate) {
                    viewModel.currentDate = previousMonth
                }
            }) {
                Text("<")
                    .font(.title)
                    .padding()
            }
            
            Spacer()
            
            Text("\(viewModel.currentDate, formatter: viewModel.monthFormatter)")
                .font(.title)
                .bold()
            
            Spacer()
            
            Button(action: {
                if let nextMonth = viewModel.calendar.date(byAdding: .month, value: 1, to: viewModel.currentDate) {
                    viewModel.currentDate = nextMonth
                }
            }) {
                Text(">")
                    .font(.title)
                    .padding()
            }
        }
        .padding(.vertical)
    }

    private var calendarGrid: some View {
        let days = viewModel.daysInMonth()
        let startingIndex = viewModel.startingWeekday()
        let last12WeeksRange = viewModel.getLast12WeeksRange()

        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            // Empty spaces for days before the first of the month
            ForEach(0..<startingIndex, id: \.self) { _ in
                Color.clear
                    .frame(height: 40)
            }

            // Days of the month
            ForEach(days, id: \.self) { date in
                let isToday = viewModel.isToday(date: date)
                let status = viewModel.getStatus(for: date)
                let day = viewModel.getCurrentDay(date: date)
                
                Text("\(day)")
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(isToday ? Color.yellow : status?.color)
                    .foregroundColor((status == .noSelection || status == nil) ? Color.black : Color.white)
                    .cornerRadius(8)
                    .disabled(true)
                    .onTapGesture {
                        if last12WeeksRange.contains(date) {
                            // This is where you handle the tap on valid dates
                            viewModel.selectedDate = date
                            selectAttendance(for: date)
                        }
                    }
                    .opacity((last12WeeksRange.contains(date) && viewModel.isWeekday(date)) ? 1.0 : 0.5) // Visually disable by reducing opacity
                    .allowsHitTesting(last12WeeksRange.contains(date) && viewModel.isWeekday(date)) // Disable tap on out-of-range dates
            }
        }
        .padding(.top, 10)
    }
    
    private var weekdayHeader: some View {
        let weekdayNames = Calendar.current.shortWeekdaySymbols
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdayNames, id: \.self) { weekday in
                Text(weekday)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.purple)
            }
        }
        .padding(.bottom, 10) // Add some space between weekday names and the calendar grid
    }
    
    private var attendancePercentageView: some View {
        let color: Color = viewModel.attendancePercentage > 59 ? .green : (viewModel.attendancePercentage > 56 ? .orange : .red)
        return HStack {
            Text("Attendance Percentage: \(viewModel.attendancePercentage, specifier: "%.2f")%")
                .font(.title2)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(color)
            
            // Information Icon
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .onTapGesture {
                    showSummary.toggle() // Toggle the popover
                }
                .popover(isPresented: $showSummary) {
                    summaryView
                        .cornerRadius(20) // Rounded corners
                        .presentationDetents([.fraction(0.40)]) // Set height fraction
                        .presentationDragIndicator(.visible) // Optional drag indicator
                }
        }
    }
    
    private func selectAttendance(for date: Date) {
        selectedAttendanceDate = date
        showingDialog = true
    }
}
