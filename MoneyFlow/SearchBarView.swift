//
//  SearchBarView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//
//  Clean/Soft UI Style Search Bar
//  - Capsule button that expands on tap
//  - Diffuse shadows, rounded corners
//  - High brightness aesthetic
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isExpanded {
                // Expanded Search Field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search expenses...", text: $searchText)
                        .font(.system(size: 16))
                        .focused($isFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                )
                
                // Cancel Button
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded = false
                        searchText = ""
                        isFocused = false
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else {
                // Collapsed Capsule Button
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Search")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
                    )
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}

#Preview {
    ZStack {
        Color(red: 0.96, green: 0.96, blue: 0.98)
            .ignoresSafeArea()
        
        VStack {
            SearchBarView(searchText: .constant(""), isExpanded: .constant(false))
            SearchBarView(searchText: .constant("Coffee"), isExpanded: .constant(true))
        }
        .padding()
    }
}
