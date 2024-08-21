//
//  BarcodeCameraManager.swift
//  qrparser
//
//  Created by Bulat on 8/21/24.
//

import Foundation
import AVFoundation

class BarcodeCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  var backCamera: AVCaptureDevice?
  var captureVideoOutput: AVCaptureVideoDataOutput?
  var videoConnection: AVCaptureConnection?
  var detector: BarcodeDetector?
  var onCaptureOutput: (_ sampleBuffer: CMSampleBuffer) -> Void
  var onShowError: (_ title: String, _ message: String) -> Void
  
  lazy var cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
    let l = AVCaptureVideoPreviewLayer(session: captureSession)
    l.videoGravity = .resizeAspectFill
    return l
  }()
    
  lazy var captureSession: AVCaptureSession = {
    let s = AVCaptureSession()
    s.sessionPreset = .hd1920x1080
    return s
  }()
  
  let captureDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
  
  init(onCaptureOutput: @escaping (_ sampleBuffer: CMSampleBuffer) -> Void, onShowError: @escaping (_ title: String, _ message: String) -> Void ) {
    self.onCaptureOutput = onCaptureOutput
    self.onShowError = onShowError
    super.init()
    setupCamera()
  }
  
  private func setupCamera() {
    do {
      try captureDevice!.lockForConfiguration()
      captureDevice?.autoFocusRangeRestriction = .near
      captureDevice!.unlockForConfiguration()
    } catch {
      print("Can't set camera focus restriction")
      self.onShowError("Error", "Can't set camera focus restriction")
      return;
    }
    
    // Set up the video device.
    let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                  mediaType: AVMediaType.video,
                                                                  position: .back)
    let devices = deviceDiscoverySession.devices
    for device in devices {
      if device.position == AVCaptureDevice.Position.back {
        backCamera = device
      }
    }
    
    // Make sure the actually is a back camera on this particular iPhone.
    guard let backCamera = backCamera else {
      print("There seems to be no camera on your device")
      self.onShowError("Error", "There seems to be no camera on your device")
      return
    }
    
    // Set up the input and output stream.
    do {
      let captureDeviceInput = try AVCaptureDeviceInput(device: backCamera)
      captureSession.addInput(captureDeviceInput)
    } catch {
      print("Your camera can't be used as an input device.")
      self.onShowError("Error", "Your camera can't be used as an input device.")
      return
    }
    
    captureVideoOutput = AVCaptureVideoDataOutput()
    captureVideoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
    captureVideoOutput!.alwaysDiscardsLateVideoFrames = true
    let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
    captureVideoOutput!.setSampleBufferDelegate(self, queue: sampleBufferQueue)
    captureSession.addOutput(captureVideoOutput!)
    videoConnection = captureVideoOutput!.connection(with: .video)!
    
    // Start the capture session.
    captureSession.startRunning()
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    self.onCaptureOutput(sampleBuffer)
  }
}
