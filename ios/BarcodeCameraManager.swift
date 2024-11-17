import Foundation
import AVFoundation

class BarcodeCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Properties
    private var backCamera: AVCaptureDevice?
    private var captureVideoOutput: AVCaptureVideoDataOutput?
    private let captureSession = AVCaptureSession()
    
    var onCaptureOutput: (_ sampleBuffer: CMSampleBuffer) -> Void
    var onShowError: (_ title: String, _ message: String) -> Void
    
    lazy var cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }()
    
    // MARK: - Initializer
    init(onCaptureOutput: @escaping (_ sampleBuffer: CMSampleBuffer) -> Void, onShowError: @escaping (_ title: String, _ message: String) -> Void) {
        self.onCaptureOutput = onCaptureOutput
        self.onShowError = onShowError
        super.init()
        setupCamera()
    }
    
    // MARK: - Private Methods
    private func setupCamera() {
        captureSession.sessionPreset = .hd1920x1080
        configureBackCamera()
        configureCaptureSessionInput()
        configureCaptureSessionOutput()
        startCaptureSession()
    }
    
    private func configureBackCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        
        if let camera = discoverySession.devices.first {
            backCamera = camera
        } else {
            showError("Error", "No back camera available on this device.")
        }
    }
    
    private func configureCaptureSessionInput() {
        guard let backCamera = backCamera else { return }
        
        do {
            try backCamera.lockForConfiguration()
            backCamera.autoFocusRangeRestriction = .near
            backCamera.unlockForConfiguration()
            
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            showError("Error", "Unable to set up back camera input.")
        }
    }
    
    private func configureCaptureSessionOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            captureVideoOutput = videoOutput
        } else {
            showError("Error", "Unable to add video output.")
        }
    }
    
    private func startCaptureSession() {
        captureSession.startRunning()
    }
    
    private func showError(_ title: String, _ message: String) {
        print("\(title): \(message)")
        onShowError(title, message)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onCaptureOutput(sampleBuffer)
    }
}
