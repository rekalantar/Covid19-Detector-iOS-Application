//
//  ViewController.swift
//  CovidCXR
//
//  Created by Reza Kalantar on 29/05/2020.
//  Copyright © 2020 Reza Kalantar. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
//import Firebase
import FirebaseCore
import FirebaseStorage
import FirebaseDatabase

class ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    //Properties
    @IBOutlet weak var classPredictionLabel: UILabel!
    @IBOutlet weak var scorePredictionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var defaultLabelViewContainer: UIView!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var detectButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    
    
    // Instances
    private var modelDataHandler: ModelDataHandler?
    private let ref = Database.database().reference()
    
    // Booleans
    private var drawMode:Bool = false
    private var imageSelected:Bool = false // flag to show when an image is selected
    private var usingCompactDevice:Bool = false
    
    //Images
    private var originalUserImage:UIImage?
    private let defaultImage = UIImage(named: "logo")
    private let inactiveDrawButton = UIImage(named: "InactiveDrawButton")
    private let activeDrawButton = UIImage(named: "ActiveDrawButton")
    
    // Labels
     private let defaultLabelText = "Load Patient Scan for Detection"
     private let uploadToDatabaseMessage = "Upload Patient Scan to Database"
     private let defaultClassLabel = "-"
     private let defaultScorelabel = "0.0 %"
     private var selectedImageURLString = ""
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = defaultImage
        imageView.isUserInteractionEnabled = true
        
//        drawButton.isHidden = true
        drawButton.isEnabled = false
        
//        if defaultLabelViewContainer.frame.size.height < 60 {
//            self.defaultLabel.alpha = 0.0
//            self.usingCompactDevice = true
//        }
       

        configureView(traitCollection.verticalSizeClass) // Don't show default label if height device in configureView is compact
        self.defaultLabel.text = self.defaultLabelText
        
        uploadButton.layer.cornerRadius = 5
        detectButton.layer.cornerRadius = 5
        resetButton.layer.cornerRadius = 5        
    }
    
    override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Send selected image over to pop up
        if segue.identifier == "toUploadPopover" {
            let popover = segue.destination as! PopoverUploadViewController
            popover.selectedImagePopover = self.originalUserImage // Send image across for presentation
            popover.selectedImageURL = self.selectedImageURLString // Send URL across for upload to database
        }
    }
    
    // MARK: Drawing Pad
    // attributes for the information inserted in the drawing pad
    private var lastPoint = CGPoint.zero
    private var color = UIColor.red
    private var brushWidth: CGFloat = 3.0
    private var opacity: CGFloat = 1.0
    private var swiped = false
    
    // Functions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else {
                return
            }
        self.swiped = false
        self.lastPoint = touch.location(in: imageView)
        }
        
    private func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        // only allow drawing when an image is loaded to the view and draw mode is ON
        if self.imageSelected && self.drawMode {
            UIGraphicsBeginImageContextWithOptions((imageView?.frame.size)!, imageView.isOpaque, 1.0)
//            UIGraphicsBeginImageContext((imageView?.frame.size)!)
            defer { UIGraphicsEndImageContext() }
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }
            let imageRect:CGRect = AVMakeRect(aspectRatio: self.imageView.image!.size, insideRect: imageView.bounds)
            imageView!.image?.draw(in: imageRect)
            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            context.setLineCap(.round)
            context.setBlendMode(.normal)
            context.setLineWidth(self.brushWidth)
            context.setStrokeColor(self.color.cgColor)
            context.strokePath()
            
            // Returns an image based on the contents of the current bitmap-based graphics context
            imageView!.image = UIGraphicsGetImageFromCurrentImageContext()
//            imageView!.alpha = opacity
//            UIGraphicsEndImageContext()
        }
    }
    
    // whilst the UIImageView is touched, draw the line in that location
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        self.swiped = true
        // disable drawing action when popover is open
        if self.drawMode {
            let currentPoint = touch.location(in: imageView!)
            self.drawLine(from: self.lastPoint, to: currentPoint)
            self.lastPoint = currentPoint
        }
    }
    
    // when the UIImageView is not touched anymore..
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.swiped {
            self.drawLine(from: self.lastPoint, to: lastPoint)
        }
        
        if self.drawMode {
            UIGraphicsBeginImageContext(imageView!.frame.size)
            imageView!.image?.draw(in: imageView!.bounds, blendMode: .normal, alpha: self.opacity)
            imageView!.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }
    
    
    //MARK: Functions UIImagePickerControllerDelegate
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // only if no image was selected previously, buttons return to inactive state
            if !self.imageSelected {
                uploadButton.backgroundColor = customVariables.inactiveButtonColor
            }
            // Dismiss the picker if the user canceled.
            dismiss(animated: true, completion: nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // The info dictionary may contain multiple representations of the image. You want to use the original for detection and editted for presentation
            self.originalUserImage = info[.originalImage] as? UIImage
            if let edittedImage = info[.editedImage] as? UIImage {
                imageView.image = edittedImage
                print("editted image size", edittedImage.size)
            } else if let originalImage = info[.originalImage] as? UIImage {
                imageView.image = originalImage
                print("original image size", originalImage.size)
            }
            
            if let url = info[.imageURL] as? URL {
                self.selectedImageURLString = url.absoluteString
            }
            
            self.imageSelected = true
            
            if !self.usingCompactDevice {
                self.defaultLabel.text = uploadToDatabaseMessage
            }
            
            uploadButton.isEnabled = true
            uploadButton.backgroundColor = customVariables.activeButtonColor
            uploadButton.setTitleColor(.black, for: UIControl.State.normal)
            detectButton.isEnabled = true
        detectButton.setTitleColor(customVariables.activeButtonColor, for: UIControl.State.normal)
            resetButton.isEnabled = true
            resetButton.setTitleColor(.black, for: UIControl.State.normal)
            drawButton.isHidden = false
            drawButton.isEnabled = true
            drawButton.setImage(inactiveDrawButton, for: UIControl.State.normal)
            dismiss(animated: true, completion: nil) // Dismiss the picker
        }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved successfully!", message: "The image has been saved in your photos.", preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
        }
    }
    
    
    override func willTransition(to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator) {
      super.willTransition(to: newCollection, with: coordinator)
      configureView(newCollection.verticalSizeClass)
    }
    
    private func configureView(_ verticalSizeClass: UIUserInterfaceSizeClass) {
        guard self.defaultLabel != nil else {
        print("Default label is nil")
        return
      }
        self.defaultLabel.isHidden = (verticalSizeClass == .compact) // Hide default label if device height is compact
    }
    
    //MARK: Actions
    @IBAction func drawModeButtonTapped(_ sender: UIButton) {
            print("Draw button tapped")
            
            if !self.drawMode {
                drawButton.setImage(activeDrawButton, for: .normal)
                self.drawMode = true
            } else {
                drawButton.setImage(inactiveDrawButton, for: .normal)
                self.drawMode = false
            }
        }


    @IBAction func takePhotoFromCamera(_ sender: UITapGestureRecognizer) {
        print("Take Photo From Camera")
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
        self.imageSelected = true
    }
    
    @IBAction func loadPhotoFromLibrary(_ sender: UITapGestureRecognizer) {
        print("Load button tapped")
            // UIImagePickerController is a view controller that lets a user pick media from their photo library.
               let imagePickerController = UIImagePickerController()

               // Only allow photos to be picked, not taken.
               imagePickerController.sourceType = .photoLibrary
               imagePickerController.allowsEditing = true

               // Make sure ViewController is notified when the user picks an image.
               imagePickerController.delegate = self
               present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func savePhotoToLibrary(_ sender: UITapGestureRecognizer) {
        print("Save Photo To Gallery")
        UIImageWriteToSavedPhotosAlbum(imageView!.image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func detectButtonTapped(_ sender: Any) {
        print("Detect button tapped")
        if self.imageSelected {
            modelDataHandler = ModelDataHandler(modelFileInfo: CovidNet.covidModeInfo)
            
            // make predictions from the model
            let modelResult = modelDataHandler!.runModel(with: originalUserImage)
            guard let predictedClass = modelResult.predictedDigit else {return}
            guard let probability = modelResult.probability else {return}
            classPredictionLabel.text = "\(predictedClass)"
            scorePredictionLabel.text = "\(Int(probability * 100)) %"
        }
        else {
            let warningText = "No image selected!"
            print(warningText)
        }
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        print("Reset button tapped")
        self.imageSelected = false
        imageView.image = defaultImage // reset image to default
        classPredictionLabel.text = self.defaultClassLabel
        scorePredictionLabel.text = self.defaultScorelabel
        
        if !self.usingCompactDevice {
            self.defaultLabel.text = defaultLabelText
        }
        
        drawButton.isEnabled = false
        uploadButton.isEnabled = false
        detectButton.isEnabled = false
        resetButton.isEnabled = false
//        drawButton.isHidden = true
        drawButton.isEnabled = false
        drawButton.setImage(inactiveDrawButton, for: UIControl.State.normal)
        uploadButton.backgroundColor = customVariables.inactiveButtonColor
        detectButton.titleLabel?.textColor = customVariables.inactiveLabelColor
    }
    
    @IBAction func uploadButtonTapped(_ sender: Any) {
        if self.imageSelected {
            print("Upload Button Tapped")
            self.drawMode = false
        }
    }
    
}

