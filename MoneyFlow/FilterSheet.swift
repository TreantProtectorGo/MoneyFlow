//
//  FilterSheet.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//
//  Clean/Soft UI Style Filter Sheet
//  - Off-white background, pure white cards
//  - Diffuse shadows, super ellipse corners
//

import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategories: Set<String>
    @Binding var minAmount: String
    @Binding var maxAmount: String
    @Binding var dateRange: DateRange
    
    let categories = CategoryManager.shared.allCategoryNames
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Off-white background
                Color(red: 0.96, green: 0.96, blue: 0.98)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Categories Section
                        FilterSection(title: "Categories") {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)
                                ],
                                spacing: 10
                            ) {
                                ForEach(categories, id: \.self) { category in
                                    FilterCategoryChip(
                                        category: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Amount Range Section
                        FilterSection(title: "Amount Range") {
                            HStack(spacing: 16) {
                                AmountInputField(
                                    placeholder: "Min",
                                    value: $minAmount
                                )
                                
                                Text("—")
                                    .foregroundColor(.secondary)
                                
                                AmountInputField(
                                    placeholder: "Max",
                                    value: $maxAmount
                                )
                            }
                        }
                        
                        // Date Range Section
                        FilterSection(title: "Date Range") {
                            HStack(spacing: 10) {
                                ForEach(DateRange.allCases, id: \.self) { range in
                                    DateRangeChip(
                                        range: range,
                                        isSelected: dateRange == range
                                    ) {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        dateRange = range
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func resetFilters() {
        selectedCategories.removeAll()
        minAmount = ""
        maxAmount = ""
        dateRange = .all
    }
}

// MARK: - Filter Section Container
struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
                )
        }
    }
}

// MARK: - Filter Category Chip
struct FilterCategoryChip: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var categoryColor: Color {
        CategoryManager.shared.color(for: category)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: CategoryManager.shared.icon(for: category))
                    .font(.system(size: 18, weight: .medium))
                
                Text(category)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? categoryColor : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Amount Input Field
struct AmountInputField: View {
    let placeholder: String
    @Binding var value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text("$")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $value)
                .keyboardType(.decimalPad)
        }
        .font(.system(size: 16))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Date Range Chip
struct DateRangeChip: View {
    let range: DateRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(range.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Range Enum
enum DateRange: String, CaseIterable {
    case all = "all"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

#Preview {
    FilterSheet(
        selectedCategories: .constant(["Food"]),
        minAmount: .constant(""),
        maxAmount: .constant(""),
        dateRange: .constant(.all)
    )
}
