import Foundation

class GenrePredictionService {
    static let shared = GenrePredictionService()
    
    private init() {}
    
    /// Predicts the most likely genre for a book based on its metadata using Gemini API
    /// - Parameters:
    ///   - title: Book title
    ///   - description: Book description
    ///   - authors: Book authors
    ///   - availableGenres: List of available genres to choose from
    /// - Returns: The most likely genre from the available genres
    func predictGenre(title: String, description: String?, authors: [String], availableGenres: [String]) async throws -> String {
        // Get the genre prediction from Gemini
        return try await predictGenreWithGemini(
            title: title,
            description: description,
            authors: authors,
            availableGenres: availableGenres
        )
    }
    
    /// Predicts genre using Google's Gemini API with enhanced focus on title and author
    private func predictGenreWithGemini(title: String, description: String?, authors: [String], availableGenres: [String]) async throws -> String {
        // Gemini API endpoint - updated to use the current supported version and model
        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!
        
        // Get API key from config
        let apiKey = APIConfig.geminiAPIKey
        
        // Check if the API key is valid
        guard !apiKey.contains("YOUR_") else {
            throw NSError(domain: "GenrePredictionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not configured"])
        }
        
        // Construct a URL with the API key as a query parameter
        var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        // Create the request with timeout
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // Set a reasonable timeout
        
        // Format the available genres as a comma-separated list
        let genreOptions = availableGenres.joined(separator: ", ")
        
        // Prepare the author string
        let authorText = authors.isEmpty ? "" : authors.joined(separator: ", ")
        
        // Prepare the description
        let descriptionText = description ?? "No description available"
        
        // Enhance the prompt to do web search if needed and put more emphasis on author's typical genre
        let prompt = """
        You are a literary expert tasked with determining the most appropriate genre for a book.
        
        Book Information:
        - Title: "\(title)"
        - Author(s): \(authorText)
        - Description: \(descriptionText)
        
        Consider both the title and the author's typical writing style. If the author is well-known, their established genre should be heavily weighted in your decision.
        
        Available genres to choose from: \(genreOptions)
        
        Analyze the title's wording, the author's usual genre, and the description to identify the most appropriate genre from the provided options.
        Return ONLY the genre name without any additional text or explanations.
        """
        
        // Create the request body according to the current API format
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 10,
                "topP": 0.95,
                "topK": 40
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                ]
            ]
        ]
        
        // Convert the request body to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        do {
            // Use a custom URLSession with better timeout handling
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 15
            sessionConfig.timeoutIntervalForResource = 30
            let session = URLSession(configuration: sessionConfig)
            
            // Send the request with explicit timeout handling
            let (data, response) = try await session.data(for: request)
            
            // Print the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Gemini API response: \(responseString)")
            }
            
            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Check for successful response code
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error message if available
                let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorResponse?["error"] as? [String: Any]
                let message = errorMessage?["message"] as? String ?? "Status code: \(httpResponse.statusCode)"
                
                throw NSError(
                    domain: "GenrePredictionService", 
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "API Error: \(message)"]
                )
            }
            
            // Parse the response using the current API structure
            let responseObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            // Extract the text response from the updated API format
            if let candidates = responseObject?["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                
                // Clean up the response to get just the genre name
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check if the response matches one of our available genres
                for genre in availableGenres {
                    if cleanedText.lowercased() == genre.lowercased() {
                        print("✅ Gemini predicted genre: \(genre)")
                        return genre // Use the correctly cased version from our list
                    }
                }
                
                // If the exact match wasn't found, try to find a partial match
                for genre in availableGenres {
                    if cleanedText.lowercased().contains(genre.lowercased()) {
                        print("✅ Gemini predicted genre (partial match): \(genre)")
                        return genre
                    }
                }
                
                // If no match, at least return what Gemini suggested
                print("⚠️ Gemini returned a genre that doesn't match our list: \(cleanedText)")
                
                // Default to a fallback genre if available
                if availableGenres.contains("Fiction") {
                    return "Fiction"
                } else if availableGenres.contains("Non-Fiction") {
                    return "Non-Fiction"
                } else {
                    return availableGenres.first ?? "Uncategorized"
                }
            }
            
            // If we couldn't parse the response at all
            throw NSError(domain: "GenrePredictionService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini API response"])
            
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw NSError(domain: "GenrePredictionService", code: 408, 
                              userInfo: [NSLocalizedDescriptionKey: "Request timed out. Please check your internet connection."])
            } else if urlError.code == .notConnectedToInternet {
                throw NSError(domain: "GenrePredictionService", code: 503, 
                              userInfo: [NSLocalizedDescriptionKey: "No internet connection available. Please check your connection."])
            }
            throw urlError
        } catch {
            throw error
        }
    }
} 
