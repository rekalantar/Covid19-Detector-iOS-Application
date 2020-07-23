//
//  SecondViewController.swift
//  CovidCXR
//
//  Created by Reza Kalantar on 29/05/2020.
//  Copyright © 2020 Reza Kalantar. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMLVision
import SafariServices

let GitHubUrl = URL(string: "https://github.com/rekalantar/covid19_detector")
class SecondViewController: UIViewController {
    
    
    let svc = SFSafariViewController(url: GitHubUrl!)

    @IBOutlet weak var developerTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        developerTextView.text = "This iOS application was developed by Reza Kalantar, PhD student in applied machine learning and artificial intelligence for clinical oncology at the institute of cancer research, London, United Kingdom. This project was supervised by Professor Mu-Dow Koh, Dr Christina Messiou, Dr Matthew Blackledge and Dr Jessica Winfield and it was undertaken in colaboration with Professor Giovanni Morana and Dr Nicholas Landini at the Radiology Institute, Treviso University Hospital, Italy. To train the model, publicly-available and anonymised frontal chest X-ray scans of patients were used. The app also enables users to upload scans to database. All texts on patient scans are automatically blocked before uploading to database."

    }
    
   override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func modelReadMoreButtonTapped(_ sender: Any) {
        print("Model read more button tapped")
        present(svc, animated: true)
    }
}
