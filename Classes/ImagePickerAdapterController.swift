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

@objc class ImagePickerAdapterController : ImagePickerController {
    @objc var callingController : ImagePickerDelegate?
    
    @objc func setCallingController (controller:ImagePickerDelegate) {
        self.delegate = controller
    }
}


