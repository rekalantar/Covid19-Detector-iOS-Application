//
//  ThirdViewController.swift
//  CovidCXR
//
//  Created by Reza Kalantar on 29/05/2020.
//  Copyright © 2020 Reza Kalantar. All rights reserved.
//

import UIKit

class ThirdViewController: UIViewController {

    @IBOutlet weak var disclaimerTextView: UITextView!
    
    private let disclaimerLabelText = "This application was developed for informational, educational and research purpose only. It is not intended for direct use in clinical diagnosis, or in the cure, mitigation, treatment, or prevention of disease. The underlaying classification model in this app was not evaluated clinically, hence users must exercise their own clinical judgement when using this application for patient care. Detection performance using this application may be significantly affected by the quality of uploaded images. In particular, when using the device camera to take images for detection, users must pay attention to the lighting conditions."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disclaimerTextView.text = self.disclaimerLabelText
    }
 
}
