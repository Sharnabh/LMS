//import SwiftUI
//import CoreImage.CIFilterBuiltins
//
//struct QRCodeGeneratorView: View {
//    let context = CIContext()
//    let filter = CIFilter.qrCodeGenerator()
//    let book: Book
//    let memberId: String
//    @Environment(\.presentationMode) var presentationMode
//    
//    @State private var timeRemaining: TimeInterval = 300 // 5 minutes in seconds
//    @State private var qrImage: UIImage?
//    @State private var isExpired = false
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Button(action: {
//                    presentationMode.wrappedValue.dismiss()
//                }) {
//                    Image(systemName: "xmark")
//                        .font(.title2)
//                        .foregroundColor(.black)
//                }
//                .padding()
//                
//                Spacer()
//                
//                Text("Issue QR Code")
//                    .font(.custom("Charter", size: 20))
//                    .bold()
//                
//                Spacer()
//                
//                Color.clear
//                    .frame(width: 44, height: 44)
//            }
//            .background(Color(red: 255/255, green: 239/255, blue: 210/255))
//            
//            Text("Show this QR to Librarian")
//                .font(.custom("Charter", size: 24))
//                .foregroundColor(.black)
//                .padding(.top)
//            
//            if let qrImage = qrImage {
//                ZStack {
//                    Image(uiImage: qrImage)
//                        .interpolation(.none)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 250, height: 250)
//                        .padding()
//                        .opacity(isExpired ? 0.3 : 1.0)
//                    
//                    if isExpired {
//                        Text("EXPIRED")
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.red)
//                            .rotationEffect(.degrees(-45))
//                    }
//                }
//            }
//            
//            VStack(spacing: 8) {
//                Text("Time Remaining")
//                    .font(.custom("Charter", size: 16))
//                Text(formatTime(timeRemaining))
//                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                    .foregroundColor(timeRemaining < 60 ? .red : .black)
//            }
//            .padding()
//            .background(Color.gray.opacity(0.1))
//            .cornerRadius(10)
//        }
//        .padding()
//        .background(Color(red: 255/255, green: 239/255, blue: 210/255))
//        .onAppear {
//            qrImage = generateQRCode()
//        }
//        .onReceive(timer) { _ in
//            if timeRemaining > 0 {
//                timeRemaining -= 1
//                if timeRemaining == 0 {
//                    isExpired = true
//                    qrImage = generateQRCode()
//                }
//            }
//        }
//    }
//    
//    func formatTime(_ timeInterval: TimeInterval) -> String {
//        let minutes = Int(timeInterval) / 60
//        let seconds = Int(timeInterval) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//    
//    func generateQRCode() -> UIImage {
//        let expirationDate = Date().addingTimeInterval(5 * 60)
//        
//        // Create a new BookIssue instance
//        let bookIssue = BookIssue(
//            bookId: book.id,
//            memberId: UUID(uuidString: memberId) ?? UUID()
//        )
//        
//        // Convert BookIssue to JSON data
//        let encoder = JSONEncoder()
//        encoder.dateEncodingStrategy = .iso8601
//        
//        let qrData = """
//        {
//            "bookIssue": \(String(data: try! encoder.encode(bookIssue), encoding: .utf8)!),
//            "expirationDate": "\(expirationDate.timeIntervalSince1970)",
//            "timestamp": "\(Date().timeIntervalSince1970)",
//            "isValid": \(!isExpired)
//        }
//        """
//        
//        let data = Data(qrData.utf8)
//        
//        filter.setValue(data, forKey: "inputMessage")
//        filter.setValue("M", forKey: "inputCorrectionLevel")
//        
//        if let outputImage = filter.outputImage {
//            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
//                return UIImage(cgImage: cgImage)
//            }
//        }
//        
//        return UIImage(systemName: "xmark.circle") ?? UIImage()
//    }
//} 
