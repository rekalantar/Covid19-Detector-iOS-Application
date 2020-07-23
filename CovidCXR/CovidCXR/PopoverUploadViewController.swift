//
//  PopoverUploadViewController.swift
//  CovidCXR
//
//  Created by Reza Kalantar on 29/05/2020.
//  Copyright © 2020 Reza Kalantar. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseMLVision

class PopoverUploadViewController: UIViewController {
    
    var textRecognizer:VisionTextRecognizer!
    var frameSublayer:CALayer!
    var selectedImagePopover:UIImage!
    var selectedImageURL:String!
    var tempURL:String!
    var IMAGE:UIImage!
    
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var popoverSelectedImageView: UIImageView!
    @IBOutlet weak var popoverCountryTextField: UITextField!
    @IBOutlet weak var popoverGenderTextField: UITextField!
    @IBOutlet weak var popoverPathologicalConfirmationLabel: UILabel!
    @IBOutlet weak var popoverPathologicalConfirmationTextField: UITextField!
    @IBOutlet weak var popoverFindingLabel: UILabel!
    @IBOutlet weak var popoverFindingTextField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vision = Vision.vision()
        
        textRecognizer = vision.onDeviceTextRecognizer()
        popoverSelectedImageView.backgroundColor = .black
        popoverSelectedImageView.image = selectedImagePopover
        
        print("selectedImageURL: " + selectedImageURL)

        createAndSetupPickerView()
        dismissAndClosePickerView()
        
        runTextRecognition(with: selectedImagePopover!)
    }
    
    //MARK: Text Recognition
    func runTextRecognition(with image: UIImage){
        let visionImage = VisionImage(image: image)
        textRecognizer.process(visionImage) {(features, error) in
            self.processResult(from: features, error: error)
        }
    }
    
    func processResult(from text: VisionText?, error: Error?) {
        guard let features = text else {return}
        
       let myLayer = CALayer()
       let myImage = selectedImagePopover
       myLayer.frame = popoverSelectedImageView.bounds
       myLayer.contents = myImage
        popoverSelectedImageView.layer.addSublayer(myLayer) // add sublayer content image
       
        let count = popoverSelectedImageView.layer.sublayers?.count
       print("PREVIOUS COUNT: ", count!)
        
        for block in features.blocks {
            for line in block.lines {
                for element in line.elements {
                    self.addFrameView(featureFrame: element.frame, imageSize: popoverSelectedImageView.image!.size, viewFrame: popoverSelectedImageView.frame, frameSublayer: popoverSelectedImageView.layer)
                    print("Text found: " + element.text)
                }
            }
        }
       
       UIGraphicsBeginImageContextWithOptions(popoverSelectedImageView.bounds.size, false, 0)
        
       popoverSelectedImageView.layer.render(in: UIGraphicsGetCurrentContext()!)

       let contextImage = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()
    
        popoverSelectedImageView.image = contextImage
        IMAGE = contextImage

        
        // Create a URL in the /tmp directory
        guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempImage.png") else {
            return
        }

        // save image to URL
        do {
            try contextImage!.pngData()?.write(to: imageURL)
            tempURL = imageURL.absoluteString
            print("IMAGE URL: \(imageURL)")
        } catch { }
    }
    
    func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, frameSublayer: CALayer) {
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
        
        self.drawFrame(featureRectScaled, frameSublayer: frameSublayer)
    }
    
    func drawFrame(_ rect: CGRect, frameSublayer: CALayer) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
//        rectLayer.strokeColor = customVariables.lineColor
        rectLayer.strokeColor = CGColor.init(srgbRed: 0, green: 0, blue: 0, alpha: 1)
//        rectLayer.fillColor = customVariables.fillColor
        rectLayer.fillColor = CGColor.init(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        rectLayer.lineWidth = customVariables.lineWidth
        frameSublayer.addSublayer(rectLayer)
//        rectLayer.isHidden = true
        
        let count = frameSublayer.sublayers?.count
        print("COUNT: ", count!)
    }
    
    //MARK: Image Picker View
    private func createAndSetupPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        self.popoverFindingTextField.inputView = pickerView
    }
    
    private func dismissAndClosePickerView(){
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.dismissAction))
        
        toolbar.setItems([button], animated: true)
        toolbar.isUserInteractionEnabled = true

        self.popoverFindingTextField.inputAccessoryView = toolbar
    }
    
    @objc func dismissAction() {
        self.view.endEditing(true)
    }
    
    
    //MARK: Upload to Database
    private func uploadToStorage(fileURL:URL) {
        let uniqueIdentifier = UUID() // generate a unique ID for photo name
        let storageRef = Storage.storage().reference().child("CXRs").child("\(uniqueIdentifier).jpeg")
        if let uploadData = IMAGE!.jpegData(compressionQuality: 1.0) {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata, error) in
                
                if error != nil {
                    print("Error: ", error as Any)
                    return
                }
                
                storageRef.downloadURL { (url, error) in
                    if let downloadURL = url?.absoluteString {
                        
                        let values = ["ImageURL": downloadURL, "Country": self.popoverCountryTextField.text!, "Gender": self.popoverGenderTextField.text!,
                            "Finding": self.popoverFindingTextField.text!,
                            "Pathological Confirmation": self.popoverPathologicalConfirmationTextField.text!,] as [String : Any]
                        
                        self.registerDataToDatabase(values: values)
                        
                    } else {
                        print("Download URL error")
                        return
                    }
                }
            })
        }
    }
    
    
    private func registerDataToDatabase(values:[String: Any]) {
        let ref = Database.database().reference().childByAutoId()
        ref.updateChildValues(values, withCompletionBlock: {
            (error, ref) in
        
            if error != nil {
            print(error as Any)
                return
            }
            self.dismiss(animated: true, completion: nil)
        })
    }
    

    //MARK: Actions
    @IBAction func uploadButtonPopoverTapped(_ sender: UIButton) {
    // if image finding and pathological confirmation not entered, don't push to database
        if popoverFindingTextField.text != "" && popoverPathologicalConfirmationTextField.text != "" {
            print("Finding entered")
            print("popover text: ", popoverFindingTextField.text as Any)
            
//            let fileUrl = URL(string: self.selectedImageURL)
            let fileUrl = URL(string: tempURL) // Get url of selected image with blocked text
            uploadToStorage(fileURL: fileUrl!)
            
            let ac = UIAlertController(title: "Uploaded Successfully", message: "The image has been added to the database.", preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
            popoverFindingLabel.textColor = .black
            popoverPathologicalConfirmationLabel.textColor = .black
        }
        
        else {
            if popoverFindingTextField.text == "" {
                print("No finding was entered!")
                popoverFindingLabel.textColor = .red
                
                if popoverPathologicalConfirmationTextField.text == "" {
                    print("No pathological confirmation of finding was entered!")
                    popoverPathologicalConfirmationLabel.textColor = .red
                }
                else {
                    popoverPathologicalConfirmationLabel.textColor = .black
                }
                
            }
            else if popoverPathologicalConfirmationTextField.text == "" {
            print("No pathological confirmation of finding was entered!")
            popoverPathologicalConfirmationLabel.textColor = .red
            
            if popoverFindingTextField.text != "" {
                popoverFindingLabel.textColor = .black
                }
            }
        }
        
    }
    
    
    @IBAction func dismissButton(_ sender: UIButton) {
        print("Popover dismiss button pressed")
        self.dismiss(animated: true, completion: nil)
    }
}

extension PopoverUploadViewController: UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return customVariables.findingsArray.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return customVariables.findingsArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.popoverFindingTextField.text = customVariables.findingsArray[row]

    }
 }
