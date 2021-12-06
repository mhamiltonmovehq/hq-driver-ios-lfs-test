//
//  ImagePickerAdapter.swift
//  Survey
//
//  Created by Jason Gorringe on 1/23/18.
//

import Foundation
import UIKit
import ImagePicker

@objc class ImagePickerAdapterController : ImagePickerController {
    @objc func setDelegate (_ delegate:ImagePickerDelegate) {
        self.delegate = delegate
    }
}


