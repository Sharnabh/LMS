//
//  ResourcesView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI

struct ResourcesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Library Resources")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Access and manage library resources")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Resource Categories
                    VStack(spacing: 15) {
                        ResourceCard(
                            title: "Digital Books",
                            description: "Access our collection of e-books",
                            icon: "book.fill",
                            count: "1,234"
                        )
                        
                        ResourceCard(
                            title: "Audio Books",
                            description: "Listen to audiobooks",
                            icon: "headphones",
                            count: "567"
                        )
                        
                        ResourceCard(
                            title: "Research Papers",
                            description: "Access academic papers and journals",
                            icon: "doc.text.fill",
                            count: "890"
                        )
                        
                        ResourceCard(
                            title: "Video Content",
                            description: "Educational videos and lectures",
                            icon: "play.circle.fill",
                            count: "123"
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Resources")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ResourceCard: View {
    let title: String
    let description: String
    let icon: String
    let count: String
    
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
                
                Text("\(count) items")
                    .font(.caption)
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
    ResourcesView()
}
