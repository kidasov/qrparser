import Foundation
import AVFoundation
import UIKit
import Vision

class BarcodeView: UIView, BackgroundListenerDelegate {

    // MARK: - Properties
    var cameraManager: BarcodeCameraManager?
    var barcodeDetector: BarcodeDetector?
    private var backCamera: AVCaptureDevice?
    private var captureVideoOutput: AVCaptureVideoDataOutput?
    private var videoConnection: AVCaptureConnection!
    @objc var onBarcodeRead: RCTDirectEventBlock?
    
    private var aspectRatio = 1.0
    private var frameHeight = 0.0
    private var frameWidth = 0.0

    private lazy var cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .hd1920x1080
        return session
    }()
    
    private let captureDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    
    // To see the preview uncomment this code
    private let photoImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDelegate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Overrides
    override var bounds: CGRect {
        didSet {
            updateFrameSize()
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            setupCameraLiveView()
        } else {
            stopCameraLiveView()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager?.cameraPreviewLayer.frame = bounds
        _DebugAddPhotoImagePreview()
    }
    
    // MARK: - BackgroundListenerDelegate
    func onBackgroundMove() {
        stopCameraLiveView()
    }

    func onForegroundMove() {
        setupCameraLiveView()
    }

    // MARK: - Private Methods
    private func setupDelegate() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.backgroundListenerDelegate = self
        }
    }
    
    private func updateFrameSize() {
        frameWidth = Double(self.frame.width)
        frameHeight = Double(self.frame.height)
        barcodeDetector?.setFrameSize(frameWidth: frameWidth, frameHeight: frameHeight)
    }
    
    private func setupCameraLiveView() {
        barcodeDetector = BarcodeDetector(
            onPreview: { [weak self] ciImage in
                self?._DebugSetPhotoImagePreview(ciImage: ciImage)
            },
            onBarcodeRead: { [weak self] params in
                self?.onBarcodeRead?(params)
            },
            onShowError: { [weak self] title, message in
                self?.showErrorMessage(title: title, message: message)
            }
        )
        
        cameraManager = BarcodeCameraManager(
            onCaptureOutput: { [weak self] sampleBuffer in
                self?.detectBarcode(sampleBuffer: sampleBuffer)
            },
            onShowError: { [weak self] title, message in
                self?.showErrorMessage(title: title, message: message)
            }
        )
        
        updateFrameSize()
        contentMode = .scaleAspectFill
        layer.masksToBounds = true
        if let cameraPreviewLayer = cameraManager?.cameraPreviewLayer {
            layer.addSublayer(cameraPreviewLayer)
        }
    }
    
    private func stopCameraLiveView() {
        barcodeDetector = nil
        backCamera = nil
        cameraManager = nil
    }
    
    private func detectBarcode(sampleBuffer: CMSampleBuffer) {
        guard let barcodeDetector = barcodeDetector,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        barcodeDetector.detectBarcodeFromImage(image: ciImage)
    }
    
    private func showErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            rootViewController.present(alertController, animated: true)
        }
    }
    
    // MARK: - Debug Methods
    private func _DebugAddPhotoImagePreview() {
        let size: CGFloat = 80
        photoImageView.frame = CGRect(x: 30, y: 90, width: size, height: size)
        photoImageView.layer.borderColor = UIColor.white.cgColor
        photoImageView.layer.borderWidth = 4
        addSubview(photoImageView)
    }
    
    private func _DebugSetPhotoImagePreview(ciImage: CIImage) {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else { return }
        let photoImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        DispatchQueue.main.async { [weak self] in
            self?.photoImageView.image = photoImage
        }
    }
}
