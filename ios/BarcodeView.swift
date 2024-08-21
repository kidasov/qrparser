//
//  BarcodeView.swift
//  qrparser
//
//  Created by Bulat on 8/21/24.
//

import Foundation
import AVFoundation
import UIKit
import Vision

class BarcodeView: UIView, BackgroundListenerDelegate {
  func onBackgroundMove() {
    stopCameraLiveView()
  }

  func onForegroundMove() {
    setupCameraLiveView()
  }
  
  var cameraManager: BarcodeCameraManager?
  var barcodeDetector: BarcodeDetector?
  var aspectRatio = 1.0
  var frameHeight = 0.0
  var frameWidth = 0.0
  override var bounds: CGRect {
    didSet {
      barcodeDetector?.setFrameSize(frameWidth: Double(self.frame.width), frameHeight: Double(self.frame.height))
    }
  }
  var backCamera: AVCaptureDevice?
  var captureVideoOutput: AVCaptureVideoDataOutput?
  private var videoConnection: AVCaptureConnection!
  @objc var onBarcodeRead: RCTDirectEventBlock?
  
  // to see the preview uncomment this code
  let photoImageView: UIImageView = {
    let imageView = UIImageView(frame: .zero)
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private lazy var cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
    let l = AVCaptureVideoPreviewLayer(session: captureSession)
    l.videoGravity = .resizeAspectFill
    return l
  }()
  
  
  private lazy var captureSession: AVCaptureSession = {
    let s = AVCaptureSession()
    s.sessionPreset = .hd1920x1080
    return s
  }()
  
  
  private let captureDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    // Set up the camera session.
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.backgroundListenerDelegate = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    if (newSuperview != nil) {
      setupCameraLiveView()
    } else {
      stopCameraLiveView()
    }
  }
  
  private func detectBarcode(sampleBuffer: CMSampleBuffer) {
    let barcodeDetector = self.barcodeDetector
    if (barcodeDetector != nil) {
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
      let ciImage = CIImage(cvPixelBuffer: imageBuffer)
      barcodeDetector!.detectBarcodeFromImage(image: ciImage)
    }
  }
  
  private func setupCameraLiveView() {
    barcodeDetector = BarcodeDetector(onPreview: {
      (ciImage) -> Void in
            self._DebugSetPhotoImagePreview(ciImage: ciImage)
    }, onBarcodeRead: {
      (params) -> Void in
      self.onBarcodeRead!(params)
    }, onShowError: { (title, message) in
      self.showErrorMessage(title: title, message: message)
    })
    cameraManager = BarcodeCameraManager(onCaptureOutput: {
      (sampleBuffer) -> Void in
      self.detectBarcode(sampleBuffer: sampleBuffer)
    }, onShowError: { (title, message) in
      self.showErrorMessage(title: title, message: message)
    })
    barcodeDetector?.setFrameSize(frameWidth: Double(self.frame.width), frameHeight: Double(self.frame.height))
    contentMode = .scaleAspectFill
    layer.masksToBounds = true
    layer.addSublayer(cameraManager!.cameraPreviewLayer)
  }
  
  private func stopCameraLiveView() {
    barcodeDetector = nil
    backCamera = nil
    cameraManager = nil
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    cameraManager?.cameraPreviewLayer.frame = bounds
        _DebugAddPhotoImagePreview()
  }
  
  private func showErrorMessage(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.window.rootViewController!.present(alertController, animated: true)
  }
  
  private func _DebugAddPhotoImagePreview() {
    let size = 80
    
    photoImageView.frame = CGRect(x: 30, y: 90, width: size, height: size)
    photoImageView.layer.borderColor = UIColor.white.cgColor
    photoImageView.layer.borderWidth = 4
    
    self.addSubview(photoImageView)
  }
  
  private func _DebugSetPhotoImagePreview(ciImage: CIImage) {
    let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent)!
    let photoImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
    DispatchQueue.main.async {
      self.photoImageView.image = photoImage
    }
  }
}
