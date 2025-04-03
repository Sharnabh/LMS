//
//  PoliciesView.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 19/03/25.
//

import Foundation
import SwiftUI
import Supabase

struct PoliciesView: View {
    @StateObject private var viewModel = LibraryPoliciesViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 11) {
                    // Divider line between Navigation Title and Content
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .padding(.bottom, 8)
                    
                    // Librarian Policies Section
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Librarian Policies")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 11) {
                            NavigationLink(destination: BooksManagementPolicyView()) {
//                                PolicyCard(
//                                    title: "Books Management",
//                                    description: "Guidelines for managing library resources and inventory",
//                                    icon: "books.vertical.fill",
//                                    color: .blue
//                                )
                            }
                            
                            NavigationLink(destination: IssuingRulesView()) {
                                PolicyCard(
                                    title: "Issuing Rules",
                                    description: "Guidelines for issuing books and resources",
                                    icon: "text.book.closed.fill",
                                    color: .orange
                                )
                            }
                            
                            NavigationLink(destination: LibraryTimingsView()) {
                                PolicyCard(
                                    title: "Library Timings",
                                    description: "Working hours and special timings",
                                    icon: "clock.fill",
                                    color: .cyan
                                )
                            }
                            
                            NavigationLink(destination: LateFinesView()) {
                                PolicyCard(
                                    title: "Late Fines",
                                    description: "Manage late return charges and penalties",
                                    icon: "indianrupeesign",
                                    color: .red
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Member Policies Section
                    VStack(alignment: .leading, spacing: 11) {
                        Text("Member Policies")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 11) {
                            NavigationLink(destination: MemberBorrowingRulesView(
                                borrowingLimit: viewModel.borrowingLimit,
                                returnPeriod: viewModel.returnPeriod,
                                reissuePeriod: 7 // Default value since this is no longer in our table
                            )) {
                                PolicyCard(
                                    title: "Borrowing Rules",
                                    description: "Guidelines for borrowing books and resources",
                                    icon: "text.book.closed.fill",
                                    color: .orange
                                )
                            }
                            
                            NavigationLink(destination: MemberLibraryTimingsView()) {
                                PolicyCard(
                                    title: "Library Timings",
                                    description: "Working hours and special timings",
                                    icon: "clock.fill",
                                    color: .cyan
                                )
                            }
                            
                            NavigationLink(destination: MemberLateFinesView(
                                fineAmount: viewModel.fineAmount,
                                gracePeriod: 3, 
                                maxFine: viewModel.lostBookFine
                            )) {
                                PolicyCard(
                                    title: "Late Fees",
                                    description: "Information about late return charges",
                                    icon: "indianrupeesign",
                                    color: .red
                                )
                            }
                            
//                            PolicyCard(
//                                title: "Resource Usage",
//                                description: "Rules for using library resources",
//                                icon: "doc.text.fill",
//                                color: .cyan
//                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom)
            }
            .navigationTitle("Policies")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.fetchPolicies()
                }
            }
        }
    }
}

struct PolicyPoint: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct PolicyCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 64, height: 64)
                .background(color.opacity(0.15))
                .cornerRadius(16)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Circle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

struct MemberBorrowingRulesView: View {
    let borrowingLimit: Int
    let returnPeriod: Int
    let reissuePeriod: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Policy Cards
                VStack(spacing: 16) {
                    // Borrowing Limit Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Borrowing Limit")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Number of books allowed:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(borrowingLimit) books")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Graduate and Post graduate students are entitled to borrow \(borrowingLimit) books at a time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Return Period Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Return Period")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Return period:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(returnPeriod) days")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Returning period not exceeds \(returnPeriod) days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Reissue Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Reissue")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reissue period:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(reissuePeriod) days")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Reissue can be extended for a period of \(reissuePeriod) days provided the said books are not reserved by others")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Borrowing Rules")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

struct MemberLateFinesView: View {
    let fineAmount: Int
    let gracePeriod: Int
    let maxFine: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Policy Cards
                VStack(spacing: 16) {
                    // Fine Amount Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Fine Amount")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Daily fine amount:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("₹\(fineAmount)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Fine of ₹\(fineAmount) per day for late returns")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                   
                    
                    // Maximum Fine Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Lost Book Fines")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Maximum fine amount:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("₹\(maxFine)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Maximum fine capped at ₹\(maxFine) per book")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Late Fees")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PoliciesView()
}

