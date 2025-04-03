import SwiftUI

struct ExpandableText: View {
    let text: String
    let font: Font
    let lineLimit: Int
    
    @State private var isExpanded = false
    
    init(_ text: String, font: Font = .body, lineLimit: Int = 5) {
        self.text = text
        self.font = font
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(font)
                .lineLimit(isExpanded ? nil : lineLimit)
                .animation(.easeInOut, value: isExpanded)
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                Text(isExpanded ? "Read Less" : "Read More")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        Text("Sample Text")
            .font(.headline)
        
        ExpandableText(
            "This is a long description that will be truncated to a few lines initially. " +
            "It contains information about something interesting that the user might want to read. " +
            "By default, this text will be truncated to just a few lines, but the user can tap " +
            "the Read More button to see the entire description. This makes the UI cleaner while " +
            "still giving users access to all the information if they want it. Lorem ipsum dolor sit amet, " +
            "consectetur adipiscing elit. Nulla facilisi. Sed ut imperdiet nisi, in auctor nunc. " +
            "Suspendisse potenti."
        )
    }
    .padding()
} 
