//
//  LibraryTimingsViewModel.swift
//  LMS
//
//  Created by Sharnabh on 27/03/25.
//

import Foundation

class LibraryTimingsViewModel: ObservableObject {
    @Published var libraryTimings: LibraryTiming?
    @Published var isLoading = false
    @Published var error: Error?
    private var dataController: SupabaseDataController = SupabaseDataController()
    
    func fetchLibraryTimings() async {
        isLoading = true
        do {
            let query = dataController.client
                .from("library_timings")
                .select()
                .limit(1)
                .single()
            
            let response: LibraryTiming = try await query.execute().value
            await MainActor.run {
                self.libraryTimings = response
                self.isLoading = false
            }
        } catch {
            print("Error fetching library timings: \(error.localizedDescription)")
            
            // If no data exists yet, create default timings
            if self.libraryTimings == nil {
                let defaultTimings = LibraryTiming()
                await createDefaultLibraryTimings(defaultTimings)
            } else {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func createDefaultLibraryTimings(_ timings: LibraryTiming) async {
        do {
            let query = try dataController.client
                .from("library_timings")
                .insert(timings)
                .single()
            
            let response: LibraryTiming = try await query.execute().value
            await MainActor.run {
                self.libraryTimings = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func updateLibraryTimings(_ timings: LibraryTiming) async {
        isLoading = true
        do {
            // Create a copy with updated timestamp
            var updatedTimings = timings
            updatedTimings.lastUpdated = Date()
            
            let query = try dataController.client
                .from("library_timings")
                .update(updatedTimings)
                .eq("id", value: timings.id)
                .single()
            
            let response: LibraryTiming = try await query.execute().value
            await MainActor.run {
                self.libraryTimings = response
                self.isLoading = false
            }
        } catch {
            print("Error updating library timings: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
