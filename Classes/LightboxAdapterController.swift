//
//  LightboxAdapterController.swift
//  Survey
//
//  Created by Jason Gorringe on 2/1/18.
//

import Foundation
import UIKit
import ImagePicker
import Lightbox

@objc class LightboxAdapterController : NSObject {
    @objc func showLightbox(images:[UIImage], imagePicker:ImagePickerController) {
        // Shows an image gallery of the images taken so far using the Lightbox module
        guard images.count > 0 else { return }
        
        let lightboxImages = images.map {
            return LightboxImage(image: $0)
        }
        
        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
        imagePicker.present(lightbox, animated: true, completion: nil)
    }
}
