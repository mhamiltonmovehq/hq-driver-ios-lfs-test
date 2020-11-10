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
    @objc var callingController : ImagePickerDelegate?
    
    @objc func setCallingController (controller:ImagePickerDelegate) {
        callingController = controller;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Create controller
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = callingController
        
        // Present the controller and dismiss the adapter
        dismiss(animated: false, completion: nil)
        present(imagePickerController, animated: true, completion: nil)
        
    }
}


