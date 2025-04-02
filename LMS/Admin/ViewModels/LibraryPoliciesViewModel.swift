//
//  LibraryPoliciesViewModel.swift
//  LMS
//
//  Created on 27/03/25.
//

import Foundation
import SwiftUI

class LibraryPoliciesViewModel: ObservableObject, @unchecked Sendable {
    @Published var borrowingLimit: Int = 5
    @Published var returnPeriod: Int = 14
    @Published var fineAmount: Int = 5
    @Published var lostBookFine: Int = 500
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var dataController = SupabaseDataController()
    
    // Fetch policies from Supabase
    func fetchPolicies() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let policies = try await dataController.fetchLibraryPolicies()
            
            DispatchQueue.main.async {
                self.borrowingLimit = policies.borrowingLimit
                self.returnPeriod = policies.returnPeriod
                self.fineAmount = policies.fineAmount
                self.lostBookFine = policies.lostBookFine
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load policies: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Update policies in Supabase
    func updatePolicies() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await dataController.updateLibraryPolicies(
                borrowingLimit: borrowingLimit,
                returnPeriod: returnPeriod,
                fineAmount: fineAmount,
                lostBookFine: lostBookFine
            )
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update policies: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Validate input values
    func validateInput() -> Bool {
        // Basic validation - you can add more specific rules as needed
        return borrowingLimit > 0 && 
               returnPeriod > 0 && 
               fineAmount >= 0 && 
               lostBookFine >= 0
    }
} 
