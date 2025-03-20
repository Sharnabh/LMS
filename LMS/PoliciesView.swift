//
//  PoliciesView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI

struct PoliciesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Library Policies")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Important guidelines and rules")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Policy Categories
                    VStack(spacing: 15) {
                        PolicyCard(
                            title: "Borrowing Rules",
                            description: "Guidelines for borrowing books and resources",
                            icon: "arrow.right.circle.fill"
                        )
                        
                        PolicyCard(
                            title: "Membership",
                            description: "Membership requirements and benefits",
                            icon: "person.crop.circle.fill"
                        )
                        
                        PolicyCard(
                            title: "Late Fees",
                            description: "Information about late return charges",
                            icon: "dollarsign.circle.fill"
                        )
                        
                        PolicyCard(
                            title: "Resource Usage",
                            description: "Rules for using library resources",
                            icon: "doc.text.fill"
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Policies")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PolicyCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.purple)
                .frame(width: 60, height: 60)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    PoliciesView()
}
