//
//  ModelDataHandler.swift
//  Covid19Detector
//
//  Created by Reza Kalantar on 28/05/2020.
//  Copyright © 2020 Reza Kalantar. All rights reserved.
//

import UIKit
import CoreImage
import Foundation
import Accelerate
import TensorFlowLite

typealias FileInfo = (name: String, extension: String)

extension UIImage {
    func renderResizedImage (targetSize: CGSize) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let image = renderer.image { (context) in
            self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: targetSize))
        }
        return image
    }
}

extension Data {
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
}

extension Array {
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        #if swift(>=5.0)
        self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
        #else
        self = unsafeData.withUnsafeBytes {
            .init(UnsafeBufferPointer<Element>(
                start: $0,
                count: unsafeData.count / MemoryLayout<Element>.stride
            ))
        }
        #endif  // swift(>=5.0)
    }
}


final class ModelDataHandler {

    // MARK: - Model Parameters


    let batchSize = 1
    let inputChannels = 3
    let inputWidth = 224
    let inputHeight = 224

    /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
    private var interpreter: Interpreter

    init?(modelFileInfo: FileInfo) {
        let modelFilename = modelFileInfo.name
        print("Model Name: ", modelFilename) // covid19_detector trained model
        
        // Construct the path to the model file.
        guard let modelPath = Bundle.main.path(
            forResource: modelFilename,
            ofType: modelFileInfo.extension
            ) else {
                print("Failed to load the model file with name: \(modelFilename).")
                return nil
        }

        do {
            interpreter = try Interpreter(modelPath: modelPath) // perform inference on the covid19_detector model
            try interpreter.allocateTensors()
        } catch let error {
            print("Failed to create the interpreter with error: \(error.localizedDescription)")
            return nil
        }

    }

    // MARK: - Run Model
    internal func runModel(with imageView: UIImage?) -> (predictedDigit: String?, probability: Float?) {

        guard let image = imageView else {return (nil, nil)}
        
        let resizedImage = image.renderResizedImage(targetSize: ImageForInfering.size)
        print("image resized to: ", resizedImage.size)
        
        // change from 64 bit image to 32 bit
        guard let greyImage = convertToGrayScale(image: resizedImage) else {return (nil, nil)}
        
        let bufferImage = buffer(from: greyImage)
        
        let outputTensor: Tensor
        
        do {
          let inputTensor = try interpreter.input(at: 0)

          // Remove the alpha component from the image buffer to get the RGB data.
          guard let rgbData = rgbDataFromBuffer(
            bufferImage!,
            byteCount: 602112, // byte count expected from the model trainied on (224,224,3)
            isModelQuantized: inputTensor.dataType == .uInt8
          ) else {
            print("Failed to convert the image buffer to RGB data.")
            return (nil,nil)
          }

          // Copy the RGB data to the input `Tensor`.
          try interpreter.copy(rgbData, toInputAt: 0)

          // Run inference by invoking the `Interpreter`.
          try interpreter.invoke()
          print("Tensorflow Lite Interpreter Invoked")
            
          // Get the output `Tensor` to process the inference results.
          outputTensor = try interpreter.output(at: 0)
        } catch let error {
          print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
          return (nil,nil)
        }

        // Make model predictions
        let results = [Float32](unsafeData: outputTensor.data) ?? []
        print("Prediction Results",results)
        guard let maxProbability = results.max() else {return (nil, nil)}
        guard let predictedIndex = results.firstIndex(of: maxProbability) else {return (nil, nil)}
        let predictedClass = customVariables.labelsArray[predictedIndex]
        return (predictedClass, maxProbability)
    }


    private func convertToGrayScale(image: UIImage) -> UIImage? {

//        let colorSpace = CGColorSpaceCreateDeviceGray()
        let colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        
        let width = image.size.width // width: 224
        let height = image.size.height // height: 224
        let imageRect:CGRect = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))

        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue), let cgImage = image.cgImage?.copy() {
                    context.setFillColor(gray: 0, alpha: 1)
                    context.fill(imageRect)
                    context.draw(cgImage, in: imageRect)

                    if let imageRef = context.makeImage() {
                        let newImage = UIImage(cgImage: imageRef)
                        return newImage
                    }
        }
        return nil
    }

    private func buffer(from image: UIImage) -> CVPixelBuffer? {
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
            return nil
    }

            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: image.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }
    private func rgbDataFromBuffer(
        _ buffer: CVPixelBuffer,
        byteCount: Int,
        isModelQuantized: Bool
      ) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer {
          CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
          return nil
        }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width
        
        var sourceBuffer = vImage_Buffer(data: sourceData,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: sourceBytesPerRow)
        
        guard let destinationData = malloc(height * destinationBytesPerRow) else {
          print("Error: out of memory")
          return nil
        }
        
        defer {
            free(destinationData)
        }

        var destinationBuffer = vImage_Buffer(data: destinationData,
                                              height: vImagePixelCount(height),
                                              width: vImagePixelCount(width),
                                              rowBytes: destinationBytesPerRow)

        let pixelBufferFormat = CVPixelBufferGetPixelFormatType(buffer)

        switch (pixelBufferFormat) {
        case kCVPixelFormatType_32BGRA:
            vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        case kCVPixelFormatType_32ARGB:
            vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        case kCVPixelFormatType_32RGBA:
            vImageConvert_RGBA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        default:
            // Unknown pixel format.
            return nil
        }

        let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
        if isModelQuantized {
            return byteData
        }

        // Not quantized, convert to floats
        let bytes = Array<UInt8>(unsafeData: byteData)!
        var floats = [Float]()
        for i in 0..<bytes.count {
            floats.append(Float(bytes[i]) / 255.0)
        }
        return Data(copyingBufferOf: floats)
      }
}

