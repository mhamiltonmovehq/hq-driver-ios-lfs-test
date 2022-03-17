//
//  KeyChain.swift
//  HQ Survey
//
//  Created by Clinton Sexton on 2/24/22.
//

import Foundation
import SwiftKeychainWrapper

@objc class KeyChainAdapter : NSObject {

    @objc class public func setJwt(jwt: String, key: String) -> Void {
        setValue(value: jwt, key: key)
    }
    @objc class public func setValue(value: String, key: String) -> Void {
        KeychainWrapper.standard.set(value, forKey: key)
    }
    @objc class public func setDataValue(value: Data, key: String) -> Void {
        KeychainWrapper.standard.set(value, forKey: key)
    }
    
    @objc class public func getJwt(label: String) -> String {
        getValue(forKey: label)
    }
    @objc class public func getValue(forKey: String) -> String {
        return KeychainWrapper.standard.string(forKey: forKey) ?? ""
    }
    @objc class public func getDataValue(forKey: String) -> Data {
        return KeychainWrapper.standard.data(forKey: forKey) ?? Data()
    }
    override init() {}
}
    
