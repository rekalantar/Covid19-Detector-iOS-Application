//
//  Utilities.swift
//  CovidCXR
//
//  Created by Reza Kalantar on 28/05/2020.
//  Copyright © 2020 Reza Kalantar. All rights reserved.
//

import UIKit
import Foundation
import FirebaseStorage
import FirebaseDatabase

// Global variables available to all ViewControllers
enum customVariables {
    
    // Custom colors
    static var activeButtonColor = UIColor(red: 216.0/255.0, green: 173.0/255.0, blue: 127.0/255.0, alpha: 1.0)
    static var inactiveLabelColor = UIColor(red: 171.0/255.0, green: 137.0/255.0, blue: 96.0/255.0, alpha: 1.0)
    static var inactiveButtonColor = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    
    // Text Recognizer Constant
    static let labelConfidenceThreshold: Float = 0.75
    static let lineWidth: CGFloat = 3.0
    static let lineColor = UIColor.yellow.cgColor
    static let fillColor = UIColor.red.cgColor
    
    // Instances
    static let ref = Database.database().reference()
    
    //Labels
    static let labelsArray = ["Normal","Pneumonia","Covid-19"]
    static let countriesArray = [""]
    static let findingsArray = ["Normal", "Covid-19 Penumonia", "Bacterial Pneumonia", "Viral Pneumonia"]
    static let genederArray = ["Not specified", "Female", "Male"]
    static let survivalArray = ["Not specified", "Yes", "No"]
}

// TensorFlow Lite helper functions and variables
enum CovidNet {
    static let covidModeInfo: FileInfo = (name: "covid19_detector", extension: "tflite")
}


// dimensions of the target image to be fed into the classifier
enum ImageForInfering {
    static let size = CGSize(width: 224, height: 224)
}

enum customFunctions {
    static func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, frameSublayer: CALayer) {
        print("Frame: \(featureFrame).")
        
        let viewSize = viewFrame.size
        
        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height
        
        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)
        
        drawFrame(featureRectScaled, frameSublayer: frameSublayer)
    }
    
    static func drawFrame(_ rect: CGRect, frameSublayer: CALayer) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = customVariables.lineColor
        rectLayer.fillColor = customVariables.fillColor
        rectLayer.lineWidth = customVariables.lineWidth
        frameSublayer.addSublayer(rectLayer)
    }
}
