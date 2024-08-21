//
//  BarcodeDetector.swift
//  qrparser
//
//  Created by Bulat on 8/21/24.
//

import Foundation
import Vision
import UIKit

class BarcodeDetector {
  var frameHeight = 0.0
  var frameWidth = 0.0
  var aspectRatio = 0.0
  var onPreview: (_ ciImage: CIImage) -> Void
  var onBarcodeRead: ([String : Any]) -> Void
  var onShowError: (_ title: String, _ message: String) -> Void
  var imageOffsetX = 28.0
  var imageOffsetY = 56.0
  let imageSize = 80.0
  
  init(onPreview: @escaping (_ ciImage: CIImage) -> Void, onBarcodeRead: @escaping ([String : Any]) -> Void, onShowError: @escaping (_ title: String, _ message: String) -> Void) {
    self.onPreview = onPreview
    self.onBarcodeRead = onBarcodeRead
    self.onShowError = onShowError
  }
  
  func detectBarcodeFromImage(image: CIImage) {
    if (frameWidth == 0 || frameHeight == 0) {
      return
    }
    
    var imageScale = 1.0
    let imageWidth = Double(image.extent.height) // 1080
    let imageHeight = Double(image.extent.width) // 1920
    let imageAspectRatio = imageWidth / imageHeight
    
    if (imageAspectRatio > aspectRatio) {
      imageScale = imageHeight / frameHeight // image height / screen height
    } else {
      imageScale =  imageWidth / frameWidth
    }
    
    let centerX = Int(image.extent.minX + image.extent.maxX) / 2 + Int(imageOffsetX * imageScale)
    let centerY = Int(image.extent.minY + image.extent.maxY) / 2 - Int(imageOffsetY * imageScale)
    let size = Int(imageSize * imageScale)
    
    let croppedImage = image.cropped(to:  CGRect(x: centerX - size / 2, y: centerY - size / 2, width: size, height: size))
    let enhancedImage = croppedImage.monochrome()
    let invertedEnhancedImage = enhancedImage.invert()
    
    self.onPreview(enhancedImage)
    
    if (detectBarcode(ciImage: enhancedImage, imageType: "grayscale")) {
      return
    }
    
    if (detectBarcode(ciImage: invertedEnhancedImage, imageType: "grayscale invert")) {
      return
    }
    
    if (detectBarcode(ciImage: enhancedImage.oriented(.right), imageType: "right")) {
      return
    }
    
    if (detectBarcode(ciImage: invertedEnhancedImage.oriented(.right), imageType: "right invert")) {
      return
    }
    
    if (detectBarcode(ciImage: enhancedImage.oriented(.left), imageType: "left")) {
      return
    }
    
    if (detectBarcode(ciImage: invertedEnhancedImage.oriented(.left), imageType: "left invert")) {
      return
    }
    
    if (detectBarcode(ciImage: enhancedImage.oriented(.up), imageType: "up")) {
      return
    }
    
    if (detectBarcode(ciImage: invertedEnhancedImage.oriented(.up), imageType: "up invert")) {
      return
    }
    
    if (detectBarcode(ciImage: enhancedImage.oriented(.down), imageType: "down")) {
      return
    }
    
    if (detectBarcode(ciImage: invertedEnhancedImage.oriented(.down), imageType: "down invert")) {
      return
    }
  }
  
  private func detectBarcode(ciImage: CIImage, imageType: String) -> Bool {
    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation.up, options: [:])
    var success = false
    
    let detectBarcodeRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
      guard error == nil else {
        print("Barcode error", error!.localizedDescription)
        return
      }
      
      if let bestResult = request.results?.first as? VNBarcodeObservation,
         let payload = bestResult.payloadStringValue {
        success = true
        let params: [String : Any] = ["code": payload, "imageType": imageType]
        //          print("Success", imageType, "Payload", payload)
        print("success", imageType)
        DispatchQueue.main.async {
          self.onBarcodeRead(params)
        }
      }
    })
    
    do {
      try handler.perform([detectBarcodeRequest])
    } catch {
      self.onShowError("Error", error.localizedDescription)
    }
    
    return success
  }
  
  func setFrameSize(frameWidth: Double, frameHeight: Double) {
    self.frameWidth = frameWidth
    self.frameHeight = frameHeight
    self.aspectRatio = frameWidth / frameHeight
  }
}

extension CIImage {
  func invert() -> CIImage {
    let rVector = CIVector(x: -1, y: 0, z: 0, w: 0)
    let gVector = CIVector(x: 0, y: -1, z: 0, w: 0)
    let bVector = CIVector(x: 0, y: 0, z: -1, w: 0)
    
    let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
    let biasVector = CIVector(x: 1, y: 1, z: 1, w: 0)
    
    dynamic let colorMatrix = CIFilter(name: "CIColorMatrix")
    
    if colorMatrix != nil {
      colorMatrix?.setDefaults()
      colorMatrix?.setValue(self, forKey: kCIInputImageKey)
      colorMatrix?.setValue(rVector, forKey: "inputRVector")
      colorMatrix?.setValue(gVector, forKey: "inputGVector")
      colorMatrix?.setValue(bVector, forKey: "inputBVector")
      colorMatrix?.setValue(aVector, forKey: "inputAVector")
      colorMatrix?.setValue(biasVector, forKey: "inputBiasVector")
      
      return colorMatrix!.outputImage!
    }
    return self
  }
  
  func monochrome() -> CIImage {
    dynamic let colorControls = CIFilter(name: "CIColorControls")
    
    if colorControls != nil {
      colorControls?.setValue(self, forKey: kCIInputImageKey)
      colorControls?.setValue(0.0, forKey: "inputBrightness")
      colorControls?.setValue(1.1, forKey: "inputContrast")
      colorControls?.setValue(0.0, forKey: "inputSaturation")
      let blackAndWhite = colorControls?.outputImage
      
      dynamic let exposureAdjust = CIFilter(name: "CIExposureAdjust")
      
      if exposureAdjust != nil {
        exposureAdjust?.setValue(blackAndWhite, forKey: kCIInputImageKey)
        exposureAdjust?.setValue(0.7, forKey: "inputEV")
        return (exposureAdjust?.outputImage)!
      }
      
      return self
    }
    
    return self
  }
}

extension UIImage {
  /// Return a new image cropped to a rectangle.
  /// - parameter rect:
  /// The rectangle to crop.
  public func cropped(to rect: CGRect) -> UIImage {
    // a UIImage is either initialized using a CGImage, a CIImage, or nothing
    if let cgImage = self.cgImage {
      // CGImage.cropping(to:) is magnitudes faster than UIImage.draw(at:)
      if let cgCroppedImage = cgImage.cropping(to: rect) {
        return UIImage(cgImage: cgCroppedImage, scale: self.scale, orientation: self.imageOrientation)
      } else {
        return UIImage()
      }
    }
    return self
  }
}
