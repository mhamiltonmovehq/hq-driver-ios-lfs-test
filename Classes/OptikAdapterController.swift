//
//  LightboxAdapterController.swift
//  Survey
//
//  Created by Jason Gorringe on 2/1/18.
//

import Foundation
import UIKit
import ImagePicker
import Optik

@objc class OptikAdapterController : NSObject {
    @objc func showOptik(images:[UIImage], imagePicker:ImagePickerController) {
        let imageView = Optik.imageViewer(withImages: images)
        imagePicker.present(imageView, animated: true, completion: nil)
    }
}
