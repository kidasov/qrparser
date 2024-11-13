import Foundation
import AVFoundation

class BarcodeCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Properties
    private var backCamera: AVCaptureDevice?
    private var captureVideoOutput: AVCaptureVideoDataOutput?
    
    var onCaptureOutput: (_ sampleBuffer: CMSampleBuffer) -> Void
    var onShowError: (_ title: String, _ message: String) -> Void
    
    lazy var cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .hd1920x1080
        return session
    }()
    
    private let captureDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    
    // MARK: - Initializer
    init(onCaptureOutput: @escaping (_ sampleBuffer: CMSampleBuffer) -> Void, onShowError: @escaping (_ title: String, _ message: String) -> Void) {
        self.onCaptureOutput = onCaptureOutput
        self.onShowError = onShowError
        super.init()
        setupCamera()
    }
    
    // MARK: - Private Methods
    private func setupCamera() {
        configureCaptureDevice()
        setupBackCamera()
        setupCaptureSession()
        startCaptureSession()
    }
    
    private func configureCaptureDevice() {
        guard let captureDevice = captureDevice else {
            showError("Error", "Unable to access capture device.")
            return
        }
        
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            showError("Error", "Can't set camera focus restriction.")
            return
        }
    }
    
    private func setupBackCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        
        backCamera = deviceDiscoverySession.devices.first { $0.position == .back }
        
        guard backCamera != nil else {
            showError("Error", "There seems to be no camera on your device.")
            return
        }
    }
    
    private func setupCaptureSession() {
        guard let backCamera = backCamera else { return }
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(captureDeviceInput)
        } catch {
            showError("Error", "Your camera can't be used as an input device.")
            return
        }
        
        captureVideoOutput = AVCaptureVideoDataOutput()
        captureVideoOutput?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        captureVideoOutput?.alwaysDiscardsLateVideoFrames = true
        
        let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
        captureVideoOutput?.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        
        if let captureVideoOutput = captureVideoOutput {
            captureSession.addOutput(captureVideoOutput)
        }
    }
    
    private func startCaptureSession() {
        captureSession.startRunning()
    }
    
    private func showError(_ title: String, _ message: String) {
        print("\(title): \(message)")
        self.onShowError(title, message)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onCaptureOutput(sampleBuffer)
    }
}
