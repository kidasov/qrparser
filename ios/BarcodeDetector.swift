import Foundation
import Vision
import UIKit

class BarcodeDetector {
    
    // MARK: - Properties
    private var frameHeight: Double = 0.0
    private var frameWidth: Double = 0.0
    private var aspectRatio: Double = 0.0
    private let imageOffsetX: Double = 28.0
    private let imageOffsetY: Double = 56.0
    private let imageSize: Double = 80.0
    
    var onPreview: (_ ciImage: CIImage) -> Void
    var onBarcodeRead: ([String : Any]) -> Void
    var onShowError: (_ title: String, _ message: String) -> Void
    
    // MARK: - Initializer
    init(onPreview: @escaping (_ ciImage: CIImage) -> Void,
         onBarcodeRead: @escaping ([String : Any]) -> Void,
         onShowError: @escaping (_ title: String, _ message: String) -> Void) {
        self.onPreview = onPreview
        self.onBarcodeRead = onBarcodeRead
        self.onShowError = onShowError
    }
    
    // MARK: - Public Methods
    func setFrameSize(frameWidth: Double, frameHeight: Double) {
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.aspectRatio = frameWidth / frameHeight
    }
    
    func detectBarcodeFromImage(image: CIImage) {
        guard frameWidth != 0, frameHeight != 0 else { return }
        
        let imageScale = calculateImageScale(for: image)
        let croppedImage = cropImage(image, scale: imageScale)
        let enhancedImage = croppedImage.monochrome()
        let invertedEnhancedImage = enhancedImage.invert()
        
        onPreview(enhancedImage)
        
        let orientations: [CGImagePropertyOrientation] = [.up, .right, .left, .down]
        let imagesToCheck = [
            (enhancedImage, "grayscale"),
            (invertedEnhancedImage, "grayscale invert")
        ]
        
        for orientation in orientations {
            for (image, type) in imagesToCheck {
                if detectBarcode(ciImage: image.oriented(orientation), imageType: "\(type) \(orientation)") {
                    return
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func calculateImageScale(for image: CIImage) -> Double {
        let imageWidth = Double(image.extent.height) // 1080
        let imageHeight = Double(image.extent.width) // 1920
        let imageAspectRatio = imageWidth / imageHeight
        
        return imageAspectRatio > aspectRatio ? imageHeight / frameHeight : imageWidth / frameWidth
    }
    
    private func cropImage(_ image: CIImage, scale: Double) -> CIImage {
        let centerX = Int(image.extent.midX + imageOffsetX * scale)
        let centerY = Int(image.extent.midY - imageOffsetY * scale)
        let size = Int(imageSize * scale)
        
        let cropRect = CGRect(x: centerX - size / 2, y: centerY - size / 2, width: size, height: size)
        return image.cropped(to: cropRect)
    }
    
    private func detectBarcode(ciImage: CIImage, imageType: String) -> Bool {
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up, options: [:])
        var success = false
        
        let detectBarcodeRequest = VNDetectBarcodesRequest { (request, error) in
            if let error = error {
                self.onShowError("Barcode Error", error.localizedDescription)
                return
            }
            
            if let bestResult = request.results?.first as? VNBarcodeObservation,
               let payload = bestResult.payloadStringValue {
                success = true
                let params: [String: Any] = ["code": payload, "imageType": imageType]
                DispatchQueue.main.async {
                    self.onBarcodeRead(params)
                }
            }
        }
        
        do {
            try handler.perform([detectBarcodeRequest])
        } catch {
            self.onShowError("Error", error.localizedDescription)
        }
        
        return success
    }
}

// MARK: - CIImage Extension
extension CIImage {
    func invert() -> CIImage {
        let rVector = CIVector(x: -1, y: 0, z: 0, w: 0)
        let gVector = CIVector(x: 0, y: -1, z: 0, w: 0)
        let bVector = CIVector(x: 0, y: 0, z: -1, w: 0)
        let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        let biasVector = CIVector(x: 1, y: 1, z: 1, w: 0)
        
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setDefaults()
        colorMatrix.setValue(self, forKey: kCIInputImageKey)
        colorMatrix.setValue(rVector, forKey: "inputRVector")
        colorMatrix.setValue(gVector, forKey: "inputGVector")
        colorMatrix.setValue(bVector, forKey: "inputBVector")
        colorMatrix.setValue(aVector, forKey: "inputAVector")
        colorMatrix.setValue(biasVector, forKey: "inputBiasVector")
        
        return colorMatrix.outputImage!
    }
    
    func monochrome() -> CIImage {
        let colorControls = CIFilter(name: "CIColorControls")!
        colorControls.setValue(self, forKey: kCIInputImageKey)
        colorControls.setValue(0.0, forKey: "inputBrightness")
        colorControls.setValue(1.1, forKey: "inputContrast")
        colorControls.setValue(0.0, forKey: "inputSaturation")
        
        let blackAndWhite = colorControls.outputImage!
        
        let exposureAdjust = CIFilter(name: "CIExposureAdjust")!
        exposureAdjust.setValue(blackAndWhite, forKey: kCIInputImageKey)
        exposureAdjust.setValue(0.7, forKey: "inputEV")
        
        return exposureAdjust.outputImage!
    }
}
