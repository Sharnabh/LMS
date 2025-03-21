import SwiftUI
import AVFoundation
import UIKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = context.coordinator
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func didFind(code: String) {
            parent.scannedCode = code
            parent.dismiss()
        }
        
        func didCancel() {
            parent.dismiss()
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(code: String)
    func didCancel()
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let overlayView = UIView()
    private let scannerOverlay = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupUI()
    }
    
    private func setupUI() {
        // Setup overlay view with transparent square in the middle
        overlayView.backgroundColor = UIColor.clear
        view.addSubview(overlayView)
        overlayView.frame = view.bounds
        
        // Create the scanning square size
        let scanningAreaSize: CGFloat = 250
        let scanningAreaX = (view.bounds.width - scanningAreaSize) / 2
        let scanningAreaY = (view.bounds.height - scanningAreaSize) / 2 - 100  // Moved up by 100 points
        let cornerRadius: CGFloat = 15 // Add corner radius
        
        // Add text label above the scanning area
        let label = UILabel()
        label.text = "Add books using\nBarcode"
        label.numberOfLines = 2
        label.textAlignment = .left
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        // Calculate label size and position
        let labelSize = label.sizeThatFits(CGSize(width: view.bounds.width - 40, height: 200))
        label.frame = CGRect(
            x: (view.bounds.width - labelSize.width) / 3.5,
            y: scanningAreaY - labelSize.height - 15, // 20 points padding
            width: labelSize.width,
            height: labelSize.height
        )
        view.addSubview(label)
        
        // Create path for the overlay
        let path = UIBezierPath(rect: view.bounds)
        
        // Create the transparent rectangle in the middle with rounded corners
        let transparentPath = UIBezierPath(
            roundedRect: CGRect(
                x: scanningAreaX,
                y: scanningAreaY,
                width: scanningAreaSize,
                height: scanningAreaSize
            ),
            cornerRadius: cornerRadius
        )
        
        path.append(transparentPath.reversing())
        
        // Create shape layer for the overlay
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        overlayView.layer.addSublayer(shapeLayer)
        
        // Add corner guides to the scanning area
        let cornerLength: CGFloat = 30
        let cornerWidth: CGFloat = 3
        let cornerColor = UIColor.white
        
        // Top left corner
        addCornerGuide(at: CGPoint(x: scanningAreaX + cornerRadius/2, y: scanningAreaY + cornerRadius/2),
                      horizontal: cornerLength, vertical: cornerLength,
                      width: cornerWidth, color: cornerColor, orientation: 0)
        
        // Top right corner
        addCornerGuide(at: CGPoint(x: scanningAreaX + scanningAreaSize - cornerRadius/2, y: scanningAreaY + cornerRadius/2),
                      horizontal: cornerLength, vertical: cornerLength,
                      width: cornerWidth, color: cornerColor, orientation: 1)
        
        // Bottom left corner
        addCornerGuide(at: CGPoint(x: scanningAreaX + cornerRadius/2, y: scanningAreaY + scanningAreaSize - cornerRadius/2),
                      horizontal: cornerLength, vertical: cornerLength,
                      width: cornerWidth, color: cornerColor, orientation: 2)
        
        // Bottom right corner
        addCornerGuide(at: CGPoint(x: scanningAreaX + scanningAreaSize - cornerRadius/2, y: scanningAreaY + scanningAreaSize - cornerRadius/2),
                      horizontal: cornerLength, vertical: cornerLength,
                      width: cornerWidth, color: cornerColor, orientation: 3)
        
        // Bring UI elements to front
        view.bringSubviewToFront(overlayView)
        view.bringSubviewToFront(label)
    }
    
    private func addCornerGuide(at point: CGPoint, horizontal: CGFloat, vertical: CGFloat, width: CGFloat, color: UIColor, orientation: Int = 0) {
        // Horizontal line
        let horizontalLine = UIView()
        horizontalLine.backgroundColor = color
        
        // Vertical line
        let verticalLine = UIView()
        verticalLine.backgroundColor = color
        
        switch orientation {
        case 0: // Top left (default)
            horizontalLine.frame = CGRect(x: point.x, y: point.y, width: horizontal, height: width)
            verticalLine.frame = CGRect(x: point.x, y: point.y, width: width, height: vertical)
        case 1: // Top right
            horizontalLine.frame = CGRect(x: point.x - horizontal + width, y: point.y, width: horizontal, height: width)
            verticalLine.frame = CGRect(x: point.x, y: point.y, width: width, height: vertical)
        case 2: // Bottom left
            horizontalLine.frame = CGRect(x: point.x, y: point.y, width: horizontal, height: width)
            verticalLine.frame = CGRect(x: point.x, y: point.y - vertical + width, width: width, height: vertical)
        case 3: // Bottom right
            horizontalLine.frame = CGRect(x: point.x - horizontal + width, y: point.y, width: horizontal, height: width)
            verticalLine.frame = CGRect(x: point.x, y: point.y - vertical + width, width: width, height: vertical)
        default:
            break
        }
        
        view.addSubview(horizontalLine)
        view.addSubview(verticalLine)
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            failed()
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .code39, .code128]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Start capture session in background
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func failed() {
        let ac = UIAlertController(
            title: "Scanning not supported",
            message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFind(code: stringValue)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
} 
