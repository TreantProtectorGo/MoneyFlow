//
//  MonthPickerView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//

import SwiftUI

struct MonthPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    let months = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"]
    
    let years: [Int]
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedDate.wrappedValue)
        self._selectedMonth = State(initialValue: (components.month ?? 1) - 1)
        self._selectedYear = State(initialValue: components.year ?? 2026)
        
        // Generate years from 2020 to current year
        let currentYear = calendar.component(.year, from: Date())
        self.years = Array(2020...currentYear)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    // Month Picker
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(0..<months.count, id: \.self) { index in
                            Text(months[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    // Year Picker
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .labelsHidden()
                .padding()
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        updateSelectedDate()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func updateSelectedDate() {
        var components = Calendar.current.dateComponents([.day, .month, .year], from: selectedDate)
        components.month = selectedMonth + 1
        components.year = selectedYear
        
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
        }
    }
}

#Preview {
    MonthPickerView(selectedDate: .constant(Date()))
}
