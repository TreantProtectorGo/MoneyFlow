//
//  ExpenseDetailView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let expense: Expense
    let modelContext: ModelContext
    
    @State private var showingEditSheet = false
    
    var categoryIcon: String {
        switch expense.category {
        case "Food": return "🍜"
        case "Transport": return "🚗"
        case "Entertainment": return "🎮"
        case "Shopping": return "🛒"
        case "Travel": return "✈️"
        case "Medical": return "💊"
        default: return "💰"
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 類別圖示
                    Text(categoryIcon)
                        .font(.system(size: 80))
                        .frame(width: 140, height: 140)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        )
                        .padding(.top, 20)
                    
                    // 商家名稱
                    Text(expense.merchant)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // 金額
                    Text("\(expense.currency) $\(expense.amount, specifier: "%.2f")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Detail information
                    VStack(spacing: 16) {
                        DetailRow(icon: "tag.fill", label: "Category", value: expense.category)
                        DetailRow(icon: "calendar", label: "Date", value: expense.date.formatted(date: .long, time: .omitted))
                        DetailRow(icon: "banknote", label: "Currency", value: expense.currency)
                        
                        if let note = expense.note, !note.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    Text("Note")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(note)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Edit button
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Expense")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditExpenseView(expense: expense, modelContext: modelContext)
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ExpenseDetailView(
            expense: Expense(
                amount: 150.0,
                currency: "HKD",
                merchant: "Starbucks",
                category: "Food",
                note: "Breakfast coffee"
            ),
            modelContext: ModelContext(
                try! ModelContainer(for: Expense.self, User.self, Group.self)
            )
        )
    }
}
