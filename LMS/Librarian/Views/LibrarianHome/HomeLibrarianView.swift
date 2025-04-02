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
    @State private var totalMembersCount: Int = 0 // Track total members count
    @State private var isLoadingMembers: Bool = false // Track loading state for members
    @State private var totalCollectedFines: Double = 0 // Track total collected fines
    @State private var isLoadingFines: Bool = false // Track loading state for fines
    
    // For Needs Shelf Location section
    @State private var needsLocationCurrentBookIndex = 0 // Track which book is currently displayed in the needs location section
    @State private var needsLocationDragOffset: CGFloat = 0
    @State private var needsLocationCardRotation: Double = 0
    @State private var needsLocationIsTransitioning = false
    @State private var needsLocationIsAnimating = false
    @State private var needsLocationCardBackgroundMap: [Int: String] = [0: "PurpleCard"]
    @State private var needsLocationNextCardBackground: String = ""
    
    private let cardBackgrounds = ["BlueCard", "GreenCard", "PurpleCard", "BlackCard"]
    
    // random card background
    private func randomCardBackground() -> String {
        return cardBackgrounds.randomElement() ?? "BlueCard"
    }
    @State private var cardBackgroundMap: [Int: String] = [0: "BlueCard"]

    @State private var nextCardBackground: String = ""
    
    // Computed property to get books with empty shelf locations
    private var booksWithEmptyShelfLocation: [LibrarianBook] {
        return bookStore.books.filter { $0.shelfLocation == nil || $0.shelfLocation?.isEmpty == true }
    }

    private func backgroundForBook(at index: Int) -> String {
        if let cached = cardBackgroundMap[index] {
            return cached
        } else {
            let background = randomCardBackground()
            cardBackgroundMap[index] = background
            return background
        }
    }

    // For Needs Shelf Location section
    private func needsLocationBackgroundForBook(at index: Int) -> String {
        if let cached = needsLocationCardBackgroundMap[index] {
            return cached
        } else {
            let background = randomCardBackground()
            needsLocationCardBackgroundMap[index] = background
            return background
        }
    }
    
    // Helper function to get the index of next book for Needs Shelf Location section
    private func getNeedsLocationNextBookIndex() -> Int? {
        // If we're at the last book, we'll return nil
        return needsLocationCurrentBookIndex < booksWithEmptyShelfLocation.count - 1 ? needsLocationCurrentBookIndex + 1 : nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.appBackground.ignoresSafeArea()

                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Quick Stats Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            // Total Books Card
                            HomeCard(
                                title: "Total Books",
                                value: "\(bookStore.books.count)",
                                icon: "book.fill",
                                color: .blue
                            )
                            
                            // Total Members Card
                            HomeCard(
                                title: "Total Members",
                                value: isLoadingMembers ? "Loading..." : "\(totalMembersCount)",
                                icon: "person.3.fill",
                                color: .green
                            )
                            
                            // Issued Books Card
                            HomeCard(
                                title: "Issued Books",
                                value: "\(booksWithEmptyShelfLocation.count)",
                                icon: "book.closed.fill",
                                color: .orange
                            )
                            
                            // Due Collected Card
                            HomeCard(
                                title: "Due Collected",
                                value: isLoadingFines ? "Loading..." : "₹\(String(format: "%.2f", totalCollectedFines))",
                                icon: "indianrupeesign",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        
                        // Divider with more spacing
                        Divider()
                            .padding(.vertical, 20)
                        
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
                                    .foregroundColor(.accentColor)
                                    .imageScale(.medium)
                                    .rotationEffect(showingCardView ? .degrees(180) : .degrees(0))
                            }
                            
                            Spacer()
                            
                            // Add See All button
                            NavigationLink(destination: AllBooksView()) {
                                Text("See all")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                        if showingCardView {
                            // Horizontal scrolling BookCardView list
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(recentBooks) { book in
                                        NavigationLink(destination: BookDetailedView(bookId: book.id)) {
                                            BookCardView(book: book)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 4)
                            .frame(height: 250)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            // Book card with swipe functionality
                            if !recentBooks.isEmpty {
                                tinderCardStack()
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                                    .frame(height: 240)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else {
                                // Empty state when no books are available
                                Text("Add your first book to see it here")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 200)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                            }
                        }

                       // Tiny spacer to create visual separation
                       Spacer().frame(height: 5)
                       
                       // Books with Empty Shelf Location Section
                       if !booksWithEmptyShelfLocation.isEmpty {
                           VStack(alignment: .leading, spacing: 0) {
                               HStack {
                                   Text("Needs Shelf Location")
                                       .font(.title2)
                                       .fontWeight(.bold)
                                       .foregroundColor(.primary)
                                   
                                   Button(action: {
                                       withAnimation(.spring()) {
                                           showingCardView.toggle()
                                       }
                                   }) {
                                       Image(systemName: "arrow.up.arrow.down")
                                           .foregroundColor(.accentColor)
                                           .imageScale(.medium)
                                           .rotationEffect(showingCardView ? .degrees(180) : .degrees(0))
                                   }
                                   
                                   Spacer()
                                   
                                   NavigationLink(destination: AllBooksWithoutShelfLocationView()) {
                                       Text("See all")
                                           .font(.subheadline)
                                           .foregroundColor(.accentColor)
                                   }
                               }
                               .frame(maxWidth: .infinity, alignment: .leading)
                               .padding(.horizontal, 16)
                               .padding(.top, 20)
                               .padding(.bottom, 8)
                               
                               if showingCardView {
                                   // Horizontal scrolling list of books without shelf location
                                   ScrollView(.horizontal, showsIndicators: false) {
                                       LazyHStack(spacing: 16) {
                                           ForEach(booksWithEmptyShelfLocation.prefix(10)) { book in
                                               NavigationLink(destination: BookDetailedView(bookId: book.id)) {
                                                   BookCardView(book: book)
                                               }
                                               .buttonStyle(PlainButtonStyle())
                                           }
                                       }
                                       .padding(.horizontal, 16)
                                   }
                                   .padding(.top, 8)
                                   .frame(height: 240)
                                   .transition(.move(edge: .top).combined(with: .opacity))
                               } else {
                                   // Use Tinder-style card stack for empty shelf location books
                                   if !booksWithEmptyShelfLocation.isEmpty {
                                       needsLocationTinderCardStack()
                                           .padding(.horizontal, 20)
                                           .padding(.top, 8)
                                           .frame(height: 240)
                                           .transition(.move(edge: .bottom).combined(with: .opacity))
                                   } else {
                                       // Empty state 
                                       Text("No books need a shelf location")
                                           .foregroundColor(.secondary)
                                           .italic()
                                           .frame(maxWidth: .infinity, alignment: .center)
                                           .frame(height: 200)
                                           .padding(.horizontal, 20)
                                           .padding(.top, 8)
                                   }
                               }
                           }
                       }
                    }
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: NotificationView()) {
                            UnreadAnnouncementIcon()
                                .simultaneousGesture(TapGesture().onEnded {
                                    // Mark announcements as seen when navigating to the view
                                    // This ensures the badge updates immediately
                                    let activeAnnouncements = getActiveLibrarianAnnouncements()
                                    AnnouncementTracker.shared.markAllAsSeen(activeAnnouncements)
                                })
                        }
                        
                        NavigationLink {
                            LibrarianProfileView()
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshBooks()
            
            // Reset current book index to show newest book
            currentBookIndex = 0
            
            // Initialize the Next Card Background if empty
            if needsLocationNextCardBackground.isEmpty {
                needsLocationNextCardBackground = randomCardBackground()
            }
            
            // Reset indices if they're out of bounds
            if needsLocationCurrentBookIndex >= booksWithEmptyShelfLocation.count && !booksWithEmptyShelfLocation.isEmpty {
                needsLocationCurrentBookIndex = 0
            }
            
            // Load members count and collected fines
            Task {
                await loadMembersCount()
                await loadCollectedFines()
            }
        }
        .onReceive(bookStore.objectWillChange) { _ in
            // Reset to show newest book when books array changes
            currentBookIndex = 0
        }
    }

    // Helper method to get active librarian announcements
    private func getActiveLibrarianAnnouncements() -> [AnnouncementModel] {
        let announcementStore = AnnouncementStore()
        let now = Date()
        
        // Load announcements synchronously (this is just for the badge)
        Task {
            await announcementStore.loadAnnouncements()
        }
        
        // Filter to get only relevant, active announcements for librarians
        return announcementStore.activeAnnouncements.filter { announcement in
            (announcement.type == .librarian || announcement.type == .all) &&
            announcement.isActive &&
            !announcement.isArchived &&
            announcement.startDate <= now &&
            announcement.expiryDate > now
        }
    }

    // Computed property to get recent books
    private var recentBooks: [LibrarianBook] {
        return bookStore.getRecentlyAddedBooks(limit: 5) // Show only 5 recent books
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
                    .offset(y: -10) // Changed from 10 to -10 to position it above
                    .scaleEffect(0.9) // Make it slightly smaller
                    .opacity(0.7) // Slightly dimmed
                    .zIndex(0) // Always at the back
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentBookIndex) // Add animation for smooth background card appearance
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            } else if currentBookIndex == recentBooks.count - 1 {
                // Last book - we'll still show an empty background card to maintain consistent appearance
                grayCardView(backgroundName: nextCardBackground)
                    .padding(.horizontal, 2)
                    .offset(y: -10) // Changed from 10 to -10
                    .scaleEffect(0.9)
                    .opacity(0.7)
                    .zIndex(0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentBookIndex) // Add animation
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            } else {
                // Empty gray card if no next book
                grayCardView(backgroundName: nextCardBackground)
                    .padding(.horizontal, 25)
                    .offset(y: -10) // Changed from 10 to -10
                    .scaleEffect(0.9)
                    .opacity(0.5)
                    .zIndex(0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentBookIndex) // Add animation
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            }
            
            // Current book (middle/active card)
            if let currentBook = recentBooks[safe: currentBookIndex] {
                // Get current card background
                let currentBackground = backgroundForBook(at: currentBookIndex)
                
                // Show either gray card or blue card based on transition state
                if isTransitioning {
                    // Show gray card with current book details when transitioned
                    ZStack {
                        // This handles the gestures
                        grayCardView(book: currentBook, backgroundName: currentBackground)
                            .padding(.horizontal, isTransitioning ? 0 : 25)
                            .offset(y: isTransitioning ? 20 : 0) // Adjusted offset
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
                                                        cardBackgroundMap[currentBookIndex - 1] = nextCardBackground
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
                        
                        // This is for navigation - transparent overlay that only triggers on tap
                        NavigationLink(destination: BookDetailedView(bookId: currentBook.id)) {
                            Color.clear
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // Show blue card with current book details when not in transition
                    ZStack {
                        // This handles the gestures
                        foregroundCardView(book: currentBook, backgroundName: currentBackground)
                            .offset(y: 20) // Add vertical positioning
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
                                                        cardBackgroundMap[currentBookIndex - 1] = nextCardBackground
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
                        
                        // This is for navigation - transparent overlay that only triggers on tap
                        NavigationLink(destination: BookDetailedView(bookId: currentBook.id)) {
                            Color.clear
                        }
                        .buttonStyle(PlainButtonStyle())
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
            if book != nil {
                Image(backgroundName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200) // Adjusted height
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
                    .frame(height: 200) // Adjusted height
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
                        .frame(width: 165, height: 160) // Adjusted height
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
                if let imageURL = book.imageLink, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 170) // Adjusted height
                                .clipped()
                                .offset(x: -85) // Position from center to left
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                                .zIndex(2)
                        case .failure:
                            defaultBookCover()
                                .frame(width: 140, height: 170) // Adjusted height
                                .offset(x: -85)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                                .zIndex(2)
                        case .empty:
                            ProgressView()
                                .frame(width: 140, height: 170) // Adjusted height
                                .offset(x: -85)
                                .zIndex(2)
                        @unknown default:
                            defaultBookCover()
                                .frame(width: 140, height: 170) // Adjusted height
                                .offset(x: -85)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                                .zIndex(2)
                        }
                    }
                } else {
                    defaultBookCover()
                        .frame(width: 140, height: 170) // Adjusted height
                        .offset(x: -85)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                        .zIndex(2)
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
                .frame(height: 200) // Adjusted height
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
                    .frame(width: 165, height: 160) // Adjusted height
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
            if let imageURL = book.imageLink, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 170) // Adjusted height
                            .clipped()
                            .offset(x: -85) // Position from center to left
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                            .zIndex(2)
                    case .failure:
                        defaultBookCover()
                            .frame(width: 140, height: 170) // Adjusted height
                            .offset(x: -85)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                            .zIndex(2)
                    case .empty:
                        ProgressView()
                            .frame(width: 140, height: 170) // Adjusted height
                            .offset(x: -85)
                            .zIndex(2)
                    @unknown default:
                        defaultBookCover()
                            .frame(width: 140, height: 170) // Adjusted height
                            .offset(x: -85)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                            .zIndex(2)
                    }
                }
            } else {
                defaultBookCover()
                    .frame(width: 140, height: 170) // Adjusted height
                    .offset(x: -85)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 10, y: 0)
                    .zIndex(2)
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
            .background(Color.yellow)
    }

    // Add refresh function
    private func refreshBooks() {
        isRefreshing = true
        Task {
            await bookStore.loadBooks()
            await loadMembersCount() // Add this line to load members count
            await loadCollectedFines() // Add this line to load collected fines
            await MainActor.run {
                isRefreshing = false
                currentBookIndex = 0 // Reset to show newest book
            }
        }
    }

    // Add function to load members count
    private func loadMembersCount() async {
        isLoadingMembers = true
        do {
            totalMembersCount = try await MemberService.shared.getTotalMembersCount()
        } catch {
            print("Error loading members count: \(error)")
        }
        isLoadingMembers = false
    }

    // Add function to load collected fines
    private func loadCollectedFines() async {
        isLoadingFines = true
        do {
            totalCollectedFines = try await AnalyticsService.shared.getTotalRevenue()
        } catch {
            print("Error loading collected fines: \(error)")
        }
        isLoadingFines = false
    }

    // Tinder-style card stack for books that need a shelf location
    private func needsLocationTinderCardStack() -> some View {
        ZStack {
            // Choose a next background color if we don't have one ready
            if needsLocationNextCardBackground.isEmpty {
                // This is invisible, just triggers the background selection
                Color.clear.onAppear {
                    needsLocationNextCardBackground = randomCardBackground()
                }
            }
            
            // Next book (background card) - shows book that will come up after swiping
            if let nextIndex = getNeedsLocationNextBookIndex(), let nextBook = booksWithEmptyShelfLocation[safe: nextIndex] {
                // We have a next book to show
                grayCardView(book: nextBook, backgroundName: needsLocationNextCardBackground)
                    .padding(.horizontal, 2)
                    .offset(y: -10) // Changed from 10 to -10 to position it above
                    .scaleEffect(0.9) // Make it slightly smaller
                    .opacity(0.7) // Slightly dimmed
                    .zIndex(0) // Always at the back
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: needsLocationCurrentBookIndex) // Add animation
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            } else if needsLocationCurrentBookIndex == booksWithEmptyShelfLocation.count - 1 {
                // Last book - we'll still show an empty background card to maintain consistent appearance
                grayCardView(backgroundName: needsLocationNextCardBackground)
                    .padding(.horizontal, 2)
                    .offset(y: -10) // Changed from 10 to -10
                    .scaleEffect(0.9)
                    .opacity(0.7)
                    .zIndex(0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: needsLocationCurrentBookIndex) // Add animation
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            } else {
                // Empty gray card if no next book
                grayCardView(backgroundName: needsLocationNextCardBackground)
                    .padding(.horizontal, 25)
                    .offset(y: -10) // Changed from 10 to -10
                    .scaleEffect(0.9)
                    .opacity(0.5)
                    .zIndex(0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: needsLocationCurrentBookIndex) // Add animation
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
            }
            
            // Current book (middle/active card)
            if let currentBook = booksWithEmptyShelfLocation[safe: needsLocationCurrentBookIndex] {
                // Get current card background
                let currentBackground = needsLocationBackgroundForBook(at: needsLocationCurrentBookIndex)
                
                // Show either gray card or blue card based on transition state
                if needsLocationIsTransitioning {
                    // Show gray card with current book details when transitioned
                    ZStack {
                        // This handles the gestures
                        grayCardView(book: currentBook, backgroundName: currentBackground)
                            .padding(.horizontal, needsLocationIsTransitioning ? 0 : 25)
                            .offset(y: needsLocationIsTransitioning ? 20 : 0) // Adjusted offset
                            .offset(x: needsLocationDragOffset) // Add x offset for swiping
                            .rotationEffect(.degrees(needsLocationCardRotation), anchor: .bottom) // Add rotation for swiping
                            .scaleEffect(needsLocationIsTransitioning ? 1.0 : 0.95)
                            .zIndex(1)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Only update if not currently animating
                                        if !needsLocationIsAnimating {
                                            // Update drag offset and rotation based on drag distance
                                            self.needsLocationDragOffset = value.translation.width
                                            
                                            // Add slight rotation effect based on drag direction
                                            self.needsLocationCardRotation = Double(value.translation.width / 20)
                                        }
                                    }
                                    .onEnded { value in
                                        // Only handle if not already animating
                                        if !needsLocationIsAnimating {
                                            // Calculate if we should swipe the card
                                            let threshold: CGFloat = 100
                                            let swipeDistance = value.translation.width
                                            
                                            if abs(swipeDistance) > threshold {
                                                // User swiped far enough to change card
                                                let direction = swipeDistance > 0 ? 1 : -1
                                                let targetDouble: Double = Double(direction)
                                                let targetX = targetDouble * 1000.0 // Swipe card off screen
                                                
                                                // Set animating flag
                                                needsLocationIsAnimating = true
                                                
                                                // Animate the card off screen
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    self.needsLocationDragOffset = targetX
                                                    let directionDouble: Double = Double(direction)
                                                    self.needsLocationCardRotation = directionDouble * 15.0
                                                }
                                                
                                                // Update card indices after animation
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    // Set transitioning state to true to show gray card
                                                    self.needsLocationIsTransitioning = true
                                                    
                                                    // Reset position for next animation
                                                    self.needsLocationDragOffset = 0
                                                    self.needsLocationCardRotation = 0
                                                    
                                                    // Swiping right (older books)
                                                    if direction > 0 && needsLocationCurrentBookIndex < booksWithEmptyShelfLocation.count - 1 {
                                                        // Update the card map with the new position
                                                        needsLocationCardBackgroundMap[needsLocationCurrentBookIndex + 1] = needsLocationNextCardBackground
                                                        
                                                        // Apply scaling animation to the background card as it becomes active
                                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                            needsLocationCurrentBookIndex += 1
                                                        }
                                                        // Generate a new background for the next card
                                                        needsLocationNextCardBackground = randomCardBackground()
                                                    }
                                                    // Swiping left (newer books)
                                                    else if direction < 0 && needsLocationCurrentBookIndex > 0 {
                                                        // Update the card map with the new position
                                                        needsLocationCardBackgroundMap[needsLocationCurrentBookIndex - 1] = needsLocationCardBackgroundMap[needsLocationCurrentBookIndex - 1] ?? needsLocationNextCardBackground
                                                        
                                                        // Apply scaling animation to the background card as it becomes active
                                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                            needsLocationCurrentBookIndex -= 1
                                                        }
                                                        // Generate a new background for the next card
                                                        needsLocationNextCardBackground = randomCardBackground()
                                                    } else {
                                                        // We hit either the first or last book - bounce back
                                                        withAnimation(.spring()) {
                                                            self.needsLocationDragOffset = 0
                                                            self.needsLocationCardRotation = 0
                                                            self.needsLocationIsTransitioning = false
                                                        }
                                                    }
                                                    
                                                    // Reset animating flag
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                        needsLocationIsAnimating = false
                                                    }
                                                }
                                            } else {
                                                // Not swiped far enough, reset position with animation
                                                withAnimation(.spring()) {
                                                    self.needsLocationDragOffset = 0
                                                    self.needsLocationCardRotation = 0
                                                }
                                            }
                                        }
                                    }
                            )
                        
                        // This is for navigation - transparent overlay that only triggers on tap
                        NavigationLink(destination: BookDetailedView(bookId: currentBook.id)) {
                            Color.clear
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // Show blue card with current book details when not in transition
                    ZStack {
                        // This handles the gestures
                        foregroundCardView(book: currentBook, backgroundName: currentBackground)
                            .offset(y: 20) // Add vertical positioning
                            .offset(x: needsLocationDragOffset)
                            .rotationEffect(.degrees(needsLocationCardRotation), anchor: .bottom)
                            .zIndex(1)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Only update if not currently animating
                                        if !needsLocationIsAnimating {
                                            // Update drag offset and rotation based on drag distance
                                            self.needsLocationDragOffset = value.translation.width
                                            
                                            // Add slight rotation effect based on drag direction
                                            self.needsLocationCardRotation = Double(value.translation.width / 20)
                                        }
                                    }
                                    .onEnded { value in
                                        // Only handle if not already animating
                                        if !needsLocationIsAnimating {
                                            // Calculate if we should swipe the card
                                            let threshold: CGFloat = 100
                                            let swipeDistance = value.translation.width
                                            
                                            if abs(swipeDistance) > threshold {
                                                // User swiped far enough to change card
                                                let direction = swipeDistance > 0 ? 1 : -1
                                                let targetDouble: Double = Double(direction)
                                                let targetX = targetDouble * 1000.0 // Swipe card off screen
                                                
                                                // Set animating flag
                                                needsLocationIsAnimating = true
                                                
                                                // Animate the card off screen
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    self.needsLocationDragOffset = targetX
                                                    let directionDouble: Double = Double(direction)
                                                    self.needsLocationCardRotation = directionDouble * 15.0
                                                }
                                                
                                                // Update card indices after animation
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    // Set transitioning state to true to show gray card
                                                    self.needsLocationIsTransitioning = true
                                                    
                                                    // Reset position for next animation
                                                    self.needsLocationDragOffset = 0
                                                    self.needsLocationCardRotation = 0
                                                    
                                                    // Swiping right (older books)
                                                    if direction > 0 && needsLocationCurrentBookIndex < booksWithEmptyShelfLocation.count - 1 {
                                                        // Update the card map with the new position
                                                        needsLocationCardBackgroundMap[needsLocationCurrentBookIndex + 1] = needsLocationNextCardBackground
                                                        
                                                        // Apply scaling animation to the background card as it becomes active
                                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                            needsLocationCurrentBookIndex += 1
                                                        }
                                                        // Generate a new background for the next card
                                                        needsLocationNextCardBackground = randomCardBackground()
                                                    }
                                                    // Swiping left (newer books)
                                                    else if direction < 0 && needsLocationCurrentBookIndex > 0 {
                                                        // Update the card map with the new position
                                                        needsLocationCardBackgroundMap[needsLocationCurrentBookIndex - 1] = needsLocationCardBackgroundMap[needsLocationCurrentBookIndex - 1] ?? needsLocationNextCardBackground
                                                        
                                                        // Apply scaling animation to the background card as it becomes active
                                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                            needsLocationCurrentBookIndex -= 1
                                                        }
                                                        // Generate a new background for the next card
                                                        needsLocationNextCardBackground = randomCardBackground()
                                                    } else {
                                                        // We hit either the first or last book - bounce back
                                                        withAnimation(.spring()) {
                                                            self.needsLocationDragOffset = 0
                                                            self.needsLocationCardRotation = 0
                                                            self.needsLocationIsTransitioning = false
                                                        }
                                                    }
                                                    
                                                    // Reset animating flag
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                        needsLocationIsAnimating = false
                                                    }
                                                }
                                            } else {
                                                // Not swiped far enough, reset position with animation
                                                withAnimation(.spring()) {
                                                    self.needsLocationDragOffset = 0
                                                    self.needsLocationCardRotation = 0
                                                }
                                            }
                                        }
                                    }
                            )
                        
                        // This is for navigation - transparent overlay that only triggers on tap
                        NavigationLink(destination: BookDetailedView(bookId: currentBook.id)) {
                            Color.clear
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: needsLocationIsTransitioning)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: needsLocationCurrentBookIndex) // Add animation for the entire stack
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
