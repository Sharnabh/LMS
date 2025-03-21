import SwiftUI

struct HomeLibrarianView: View {
    @EnvironmentObject var bookStore: BookStore
    @State private var selectedBook: LibrarianBook? = nil
    @State private var showBookDetails = false
    @State private var currentBookIndex = 0 // Track which book is currently displayed
    @State private var dragOffset: CGFloat = 0
    @State private var cardRotation: Double = 0 // For rotating the card during swipe
    @State private var previousBookIndex: Int? = nil // Track the previous book
    @State private var isTransitioning = false // Track if we're in transition between cards
    @State private var isAnimating = false // Track if cards are currently animating
    @State private var showingCardView = false // Track which view mode to show
    @State private var isRefreshing = false // Track refresh state
    
    private let cardBackgrounds = ["BlueCard", "GreenCard", "PurpleCard", "BlackCard"]
    
    // random card background
    private func randomCardBackground() -> String {
        return cardBackgrounds.randomElement() ?? "BlueCard"
    }
        @State private var cardBackgroundMap: [Int: String] = [0: "BlueCard"]

    @State private var nextCardBackground: String = ""
    private func backgroundForBook(at index: Int) -> String {
        if let cached = cardBackgroundMap[index] {
            return cached
        } else {
            let background = randomCardBackground()
            cardBackgroundMap[index] = background
            return background
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.appBackground.ignoresSafeArea()

                // Content area
                VStack(alignment: .leading, spacing: 50) {
                    HStack {
                        Text("Recently Added")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showingCardView.toggle()
                            }
                        }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                                .imageScale(.medium)
                                .rotationEffect(showingCardView ? .degrees(180) : .degrees(0))
                        }
                        
                        Spacer()
                        
                        // Add See All button
                        NavigationLink(destination: AllBooksView()) {
                            Text("See all")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top)

                    if showingCardView {
                        // Horizontal scrolling BookCardView list
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(recentBooks) { book in
                                    BookCardView(book: book)
                                        .onTapGesture {
                                            selectedBook = book
                                            showBookDetails = true
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, -40)
                        .frame(height: 210)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        // Book card with swipe functionality
                        if !recentBooks.isEmpty {
                            tinderCardStack()
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            // Empty state when no books are available
                            Text("Add your first book to see it here")
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 20)
                        }
                    }

                   Spacer()
                }

                // Use navigationDestination instead of NavigationLink
                .navigationDestination(isPresented: $showBookDetails) {
                    if let book = selectedBook {
                        BookDetailedView(bookId: book.id)
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                refreshBooks()
            }
        }
    }

    // Computed property to get recent books
    private var recentBooks: [LibrarianBook] {
        return bookStore.getRecentlyAddedBooks(limit: 5).reversed() // Show only 5 recent books
    }

    // Tinder-style card stack
    private func tinderCardStack() -> some View {
        ZStack {
            // Choose a next background color if we don't have one ready
            if nextCardBackground.isEmpty {
                // This is invisible, just triggers the background selection
                Color.clear.onAppear {
                    nextCardBackground = randomCardBackground()
                }
            }
            
            // Next book (background card) - shows book that will come up after swiping
            if let nextIndex = getNextBookIndex(), let nextBook = recentBooks[safe: nextIndex] {
                // We have a next book to show
                grayCardView(book: nextBook, backgroundName: nextCardBackground)
                    .padding(.horizontal, 2)
                    .offset(y: -40) // Position it further back initially
                    .scaleEffect(0.9) // Make it slightly smaller
                    .opacity(0.7) // Slightly dimmed
                    .zIndex(0) // Always at the back
            } else if currentBookIndex == recentBooks.count - 1 {
                // Last book - we'll still show an empty background card to maintain consistent appearance
                grayCardView(backgroundName: nextCardBackground)
                    .padding(.horizontal, 2)
                    .offset(y: -40)
                    .scaleEffect(0.9)
                    .opacity(0.7)
                    .zIndex(0)
            } else {
                // Empty gray card if no next book
                grayCardView(backgroundName: nextCardBackground)
                    .padding(.horizontal, 25)
                    .offset(y: -40)
                    .scaleEffect(0.9)
                    .opacity(0.5)
                    .zIndex(0)
            }
            
            // Current book (middle/active card)
            if let currentBook = recentBooks[safe: currentBookIndex] {
                // Get current card background
                let currentBackground = backgroundForBook(at: currentBookIndex)
                
                // Show either gray card or blue card based on transition state
                if isTransitioning {
                    // Show gray card with current book details when transitioned
                    grayCardView(book: currentBook, backgroundName: currentBackground)
                        .padding(.horizontal, isTransitioning ? 0 : 25)
                        .offset(y: isTransitioning ? 0 : -30)
                        .offset(x: dragOffset) // Add x offset for swiping
                        .rotationEffect(.degrees(cardRotation), anchor: .bottom) // Add rotation for swiping
                        .scaleEffect(isTransitioning ? 1.0 : 0.95)
                        .zIndex(1)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only update if not currently animating
                                    if !isAnimating {
                                        // Update drag offset and rotation based on drag distance
                                        self.dragOffset = value.translation.width
                                        
                                        // Add slight rotation effect based on drag direction
                                        self.cardRotation = Double(value.translation.width / 20)
                                    }
                                }
                                .onEnded { value in
                                    // Only handle if not already animating
                                    if !isAnimating {
                                        // Calculate if we should swipe the card
                                        let threshold: CGFloat = 100
                                        let swipeDistance = value.translation.width
                                        
                                        if abs(swipeDistance) > threshold {
                                            // User swiped far enough to change card
                                            let direction = swipeDistance > 0 ? 1 : -1
                                            let targetDouble: Double = Double(direction)
                                            let targetX = targetDouble * 1000.0 // Swipe card off screen
                                            
                                            // Set animating flag
                                            isAnimating = true
                                            
                                            // Animate the card off screen
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                self.dragOffset = targetX
                                                let directionDouble: Double = Double(direction)
                                                self.cardRotation = directionDouble * 15.0
                                            }
                                            
                                            // Update card indices after animation
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                // Set transitioning state to true to show gray card
                                                self.isTransitioning = true
                                                
                                                // Reset position for next animation
                                                self.dragOffset = 0
                                                self.cardRotation = 0
                                                
                                                // Swiping right (older books)
                                                if direction > 0 && currentBookIndex < recentBooks.count - 1 {
                                                    // Update the card map with the new position
                                                    cardBackgroundMap[currentBookIndex + 1] = nextCardBackground
                                                    currentBookIndex += 1
                                                    // Generate a new background for the next card
                                                    nextCardBackground = randomCardBackground()
                                                }
                                                // Swiping left (newer books)
                                                else if direction < 0 && currentBookIndex > 0 {
                                                    // Update the card map with the new position 
                                                    cardBackgroundMap[currentBookIndex - 1] = cardBackgroundMap[currentBookIndex - 1] ?? nextCardBackground
                                                    currentBookIndex -= 1
                                                    // Generate a new background for the next card
                                                    nextCardBackground = randomCardBackground()
                                                } else {
                                                    // We hit either the first or last book - bounce back
                                                    withAnimation(.spring()) {
                                                        self.dragOffset = 0
                                                        self.cardRotation = 0
                                                        self.isTransitioning = false
                                                    }
                                                }
                                                
                                                // Reset animating flag
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    isAnimating = false
                                                }
                                            }
                                        } else {
                                            // Not swiped far enough, reset position with animation
                                            withAnimation(.spring()) {
                                                self.dragOffset = 0
                                                self.cardRotation = 0
                                            }
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            selectedBook = currentBook
                            showBookDetails = true
                        }
                } else {
                    // Show blue card with current book details when not in transition
                    foregroundCardView(book: currentBook, backgroundName: currentBackground)
                        .offset(x: dragOffset)
                        .rotationEffect(.degrees(cardRotation), anchor: .bottom)
                        .zIndex(1)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only update if not currently animating
                                    if !isAnimating {
                                        // Update drag offset and rotation based on drag distance
                                        self.dragOffset = value.translation.width
                                        
                                        // Add slight rotation effect based on drag direction
                                        self.cardRotation = Double(value.translation.width / 20)
                                    }
                                }
                                .onEnded { value in
                                    // Only handle if not already animating
                                    if !isAnimating {
                                        // Calculate if we should swipe the card
                                        let threshold: CGFloat = 100
                                        let swipeDistance = value.translation.width
                                        
                                        if abs(swipeDistance) > threshold {
                                            // User swiped far enough to change card
                                            let direction = swipeDistance > 0 ? 1 : -1
                                            let targetDouble: Double = Double(direction)
                                            let targetX = targetDouble * 1000.0 // Swipe card off screen
                                            
                                            // Set animating flag
                                            isAnimating = true
                                            
                                            // Animate the card off screen
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                self.dragOffset = targetX
                                                let directionDouble: Double = Double(direction)
                                                self.cardRotation = directionDouble * 15.0
                                            }
                                            
                                            // Update card indices after animation
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                // Set transitioning state to true to show gray card
                                                self.isTransitioning = true
                                                
                                                // Reset position for next animation
                                                self.dragOffset = 0
                                                self.cardRotation = 0
                                                
                                                // Swiping right (older books)
                                                if direction > 0 && currentBookIndex < recentBooks.count - 1 {
                                                    // Update the card map with the new position
                                                    cardBackgroundMap[currentBookIndex + 1] = nextCardBackground
                                                    currentBookIndex += 1
                                                    // Generate a new background for the next card
                                                    nextCardBackground = randomCardBackground()
                                                }
                                                // Swiping left (newer books)
                                                else if direction < 0 && currentBookIndex > 0 {
                                                    // Update the card map with the new position 
                                                    cardBackgroundMap[currentBookIndex - 1] = cardBackgroundMap[currentBookIndex - 1] ?? nextCardBackground
                                                    currentBookIndex -= 1
                                                    // Generate a new background for the next card
                                                    nextCardBackground = randomCardBackground()
                                                } else {
                                                    // We hit either the first or last book - bounce back
                                                    withAnimation(.spring()) {
                                                        self.dragOffset = 0
                                                        self.cardRotation = 0
                                                        self.isTransitioning = false
                                                    }
                                                }
                                                
                                                // Reset animating flag
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    isAnimating = false
                                                }
                                            }
                                        } else {
                                            // Not swiped far enough, reset position with animation
                                            withAnimation(.spring()) {
                                                self.dragOffset = 0
                                                self.cardRotation = 0
                                            }
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            selectedBook = currentBook
                            showBookDetails = true
                        }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isTransitioning)
    }

    // Helper function to get the index of next book to show behind current card
    private func getNextBookIndex() -> Int? {
        // If we're at the last book, we'll return nil,
        // but we'll handle this case specially in the view to maintain UI consistency
        return currentBookIndex < recentBooks.count - 1 ? currentBookIndex + 1 : nil
    }

    // Gray card view with book details (used for both active and background cards)
    private func grayCardView(book: LibrarianBook? = nil, backgroundName: String) -> some View {
        // Foreground card with book cover in the same layout as blue card
        ZStack {
            // Card background with image
            if let book = book {
                Image(backgroundName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(
                        RoundedCorners(
                            topLeft: 16,
                            topRight: 16,
                            bottomLeft: 16,
                            bottomRight: 16
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            } else {
                // Default background for empty card
                Image(backgroundName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(
                        RoundedCorners(
                            topLeft: 16,
                            topRight: 16,
                            bottomLeft: 16,
                            bottomRight: 16
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Only show book content if a book is provided
            if let book = book {
                // Dark info rectangle (same layout as blue card)
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.6)) // Transparent dark overlay for info
                        .frame(width: 165, height: 170)
                        .clipShape(
                            RoundedCorners(
                                topLeft: 0,
                                topRight: 10,
                                bottomLeft: 0,
                                bottomRight: 10)
                        )
                    
                    // Book information
                    VStack(alignment: .leading, spacing: 8) {
                        // Book title
                        Text(trimText(book.title, maxLength: 10).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Author name
                        Text(trimText(book.author.joined(separator: ", "), maxLength: 15).uppercased())
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .padding(.bottom, 25)
                        
                        // Bottom indicators section
                        HStack(spacing: 0) {
                            // Quantity indicator
                            VStack(spacing: 2) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("\(book.totalCopies)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 70)
                            
                            // Vertical divider
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 1, height: 40)
                            
                            // Location indicator
                            VStack(spacing: 2) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text(trimText(book.shelfLocation ?? "", maxLength: 4))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.leading, 15)
                    .padding(.trailing, 10)
                    .padding(.vertical, 12)
                }
                .offset(x: 70) // Position from center to right
                .zIndex(1)
                
                // Book cover image with shadow
                AsyncImage(url: URL(string: book.imageLink ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 180)
                            .clipped()
                            .offset(x: -85) // Position from center to left
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                            .zIndex(2)
                    case .failure, .empty:
                        defaultBookCover()
                            .offset(x: -85)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                            .zIndex(2)
                    @unknown default:
                        defaultBookCover()
                            .offset(x: -85)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                            .zIndex(2)
                    }
                }
            }
        }
        .contentShape(Rectangle()) // Make the entire card tappable
    }

    // Foreground blue card view with book details
    private func foregroundCardView(book: LibrarianBook, backgroundName: String) -> some View {
        // Foreground card with book cover
        ZStack {
            // Card background with image
            Image(backgroundName)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipShape(
                    RoundedCorners(
                        topLeft: 16,
                        topRight: 16,
                        bottomLeft: 16,
                        bottomRight: 16
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: -10)

            // Dark info rectangle
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.6)) // Transparent dark overlay for info
                    .frame(width: 165, height: 170)
                    .clipShape(
                        RoundedCorners(
                            topLeft: 0,
                            topRight: 10,
                            bottomLeft: 0,
                            bottomRight: 10)
                    )

                // Book information
                VStack(alignment: .leading, spacing: 8) {
                    // Book title
                    Text(trimText(book.title, maxLength: 10).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Author name
                    Text(trimText(book.author.joined(separator: ", "), maxLength: 15).uppercased())
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .padding(.bottom, 25)

                    // Bottom indicators section
                    HStack(spacing: 0) {
                        // Quantity indicator
                        VStack(spacing: 2) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)

                            Text("\(book.totalCopies)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 70)

                        // Vertical divider
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: 40)

                        // Location indicator
                        VStack(spacing: 2) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 22))
                                .foregroundColor(.white)

                            Text(trimText(book.shelfLocation ?? "", maxLength: 4))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 70)
                    }
                    .padding(.top, 10)
                }
                .padding(.leading, 15)
                .padding(.trailing, 10)
                .padding(.vertical, 12)
            }
            .offset(x: 70) // Position from center to right
            .zIndex(1)

            // Book cover image with shadow
            AsyncImage(url: URL(string: book.imageLink ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 180)
                        .clipped()
                        .offset(x: -85) // Position from center to left
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                        .zIndex(2)
                case .failure, .empty:
                    defaultBookCover()
                        .offset(x: -85)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                        .zIndex(2)
                @unknown default:
                    defaultBookCover()
                        .offset(x: -85)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                        .zIndex(2)
                }
            }
        }
        .contentShape(Rectangle()) // Make the entire card tappable
    }

    // Helper function to trim text if it's too long
    private func trimText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        } else {
            let index = text.index(text.startIndex, offsetBy: maxLength - 3)
            return String(text[..<index]) + "..."
        }
    }

    private func defaultBookCover() -> some View {
        Image(systemName: "book.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 180)
            .background(Color.yellow)
    }

    // Add refresh function
    private func refreshBooks() {
        isRefreshing = true
        Task {
            await bookStore.loadBooks()
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// Custom shape for rounded specific corners
struct RoundedCorners: Shape {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        // Top left corner
        path.move(to: CGPoint(x: 0, y: topLeft))
        path.addArc(center: CGPoint(x: topLeft, y: topLeft),
                    radius: topLeft,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 270),
                    clockwise: false)

        // Top right corner
        path.addLine(to: CGPoint(x: width - topRight, y: 0))
        path.addArc(center: CGPoint(x: width - topRight, y: topRight),
                    radius: topRight,
                    startAngle: Angle(degrees: 270),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)

        // Bottom right corner
        path.addLine(to: CGPoint(x: width, y: height - bottomRight))
        path.addArc(center: CGPoint(x: width - bottomRight, y: height - bottomRight),
                    radius: bottomRight,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)

        // Bottom left corner
        path.addLine(to: CGPoint(x: bottomLeft, y: height))
        path.addArc(center: CGPoint(x: bottomLeft, y: height - bottomLeft),
                    radius: bottomLeft,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)

        path.closeSubpath()

        return path
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HomeLibrarianView()
        .environmentObject(BookStore())
}
