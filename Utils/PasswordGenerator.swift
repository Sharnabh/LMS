import Foundation

class PasswordGenerator {
    static func generateRandomPassword(length: Int = 10) -> String {
        let upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowerChars = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialChars = "!@#$%^&*()_-+=<>?"
        
        let allChars = upperChars + lowerChars + numbers + specialChars
        var password = ""
        
        // Ensure at least one character from each category
        password += String(upperChars.randomElement()!)
        password += String(lowerChars.randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(specialChars.randomElement()!)
        
        // Fill the rest of the password
        for _ in 4..<length {
            password += String(allChars.randomElement()!)
        }
        
        // Shuffle the password
        return String(password.shuffled())
    }
}