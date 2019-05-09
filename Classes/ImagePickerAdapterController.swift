//
//  ImagePickerAdapter.swift
//  Survey
//
//  Created by Jason Gorringe on 1/23/18.
//

import Foundation
import UIKit
import ImagePicker
import Lightbox

@objc class ImagePickerAdapterController : UIViewController {
    var goBackToMenu = false
    @objc var callingController : ImagePickerDelegate?
    
    @objc func setCallingController (controller:ImagePickerDelegate) {
        callingController = controller;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()
        
        if(goBackToMenu) {
            // Have returned from the camera view
            dismiss(animated: true, completion: nil)
        } else {
            // Create controller
            let imagePickerController = ImagePickerController()
            imagePickerController.delegate = callingController
            
            // Instruct this placeholder controller to exit the next time it is shown
            goBackToMenu = true
            
            // Present the controller
            present(imagePickerController, animated: true, completion: nil)
        }
    }
}


