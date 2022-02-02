//
//  HubActivation.swift
//  HubActivationDemo
//
//  Created by Matthew Hamilton on 11/19/20.
//  Copyright © 2020 mhamilton. All rights reserved.
//

import UIKit

@objc(HubActivationResponseProtocol) protocol HubActivationWrapperProtocol {
    func hubActivationCompleted (result: HubActivationWrapperResult)
}

@objc class HubResultObjc: NSObject {
    @objc var pricingVersion: Int
    @objc var milesVersion: Int
    @objc var pricingFileLocation: String
    @objc var milesFileLocation: String
    @objc var licenseProduct: String
    @objc var carrierId: Int
    
    override init() {
        pricingVersion = 0
        milesVersion = 0
        pricingFileLocation = ""
        milesFileLocation = ""
        licenseProduct = ""
        carrierId = 0
    }
    
    init(hubresult: HubActivationRecord) {
        pricingVersion = hubresult.tariff_version
        milesVersion = hubresult.mile_file_version
        pricingFileLocation = hubresult.tariff_file_location
        milesFileLocation = hubresult.mile_file_location
        licenseProduct = hubresult.license_product
        carrierId = hubresult.carrier_id
    }
}

@objc class HubActivationWrapperResult: NSObject {
    
    @objc var errorMessage: String
    @objc var success: Bool
    @objc var hubResult: HubResultObjc?
    
    override init() {
        errorMessage = ""
        success = false
        hubResult = nil
    }

}

@objc class HubActivationWrapper: NSObject {
    
    @objc var caller: HubActivationWrapperProtocol?
    
    @objc func activate (caller: HubActivationWrapperProtocol) {
        
        self.caller = caller
        
        let username = Prefs.username() ?? ""
        let password = Prefs.password() ?? ""
        let udid = OpenUDID.value() ?? ""
        let appName = "Driver"
        let deviceType = UIDevice.current.model
        let deviceVersion = UIDevice.current.systemVersion
        let softwareVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        

        HubActivationService.shared.activate(username: username, password: password, udid: udid, appName: appName, deviceType: deviceType, deviceVersion: deviceVersion, softwareVersion: softwareVersion, completion: authenticateCompleted)
    }
    
    func authenticateCompleted(result: RestResult<HubActivationRecord>) {
        switch (result) {
        case .Success(let data):
            let result = HubActivationWrapperResult()
            result.hubResult = HubResultObjc(hubresult: data)
            result.success = true
            caller?.hubActivationCompleted(result: result)
        case .Error(let message):
            let result = HubActivationWrapperResult()
            result.success = false
            result.errorMessage = message
            caller?.hubActivationCompleted(result: result)
        }
    }
}

class HubActivationService {
    
    let del = UIApplication.shared.delegate as? SurveyAppDelegate

    static let shared = HubActivationService()
    
    private init() {}
    
    func activate (username: String, password: String, udid: String, appName: String, deviceType: String,
                   deviceVersion: String, softwareVersion: String, completion: @escaping (RestResult<HubActivationRecord>) -> Void) {
        
        // Create claims for JWT token
        let sInfo = SessionInfo(user: username, password: password, app_name: appName, device_id: udid, device_type: deviceType, device_version: deviceVersion, device_software_version: softwareVersion)
        let tokenService = TokenService()
       
        do {
            try tokenService._getToken(info: sInfo){ result in
                switch (result) {
                case .Error(let message):
                    completion(.Error(message))
                case .Success(_):
                    do {
                        try self._getHubActivationRecord(jwt: (self.del?.session.access_token)!, info: sInfo) { result in
                            switch (result) {
                                case .Error(let message):
                                    completion(.Error(message))
                                case .Success(let activationRecord):
                                    completion(.Success(activationRecord))
                            }
                        }
                    }
                    catch let error {
                        completion(.Error(error.localizedDescription))
                    }
                }
            }
        }
        catch let error {
            completion(.Error(error.localizedDescription))
        }
    }
    
    func _getHubActivationRecord (jwt: String, info: SessionInfo, completion: @escaping (RestResult<HubActivationRecord>) -> Void) throws {
        
        var activationRecord: HubActivationRecord? = nil
        let del = UIApplication.shared.delegate as? SurveyAppDelegate
        
        
        // Before this point, check username and password are entered correctly
        // Also check UUID
        // Check if last open is greater than today
        
        // Call to Hub
        let headerValues = ["Authorization" : "Bearer " + jwt]
        
        let request = RestSyncRequest()
        request.scheme = "https://"
        request.host = HubEnvironment.environmentURL()
        request.basePath = "/api/mobile"
        request.methodPath = "/login"
        
        let params = ["app_name"                : info.app_name,
                      "device_id"               : info.device_id,
                      "device_type"             : info.device_type,
                      "device_version"          : info.device_version,
                      "device_software_version" : info.device_software_version]
        
        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        do {
            try request.executeHttpRequest(httpMethod: "POST", queryParameters: nil, bodyData: body, headerData: headerValues) {result in
                
                switch (result) {
                case .Error(let message):
                    completion(.Error(message))
                case .Success(let response):
                    let jsonData = Data(response.utf8)
                    let decoder = JSONDecoder()
                    do {
                        activationRecord = try decoder.decode(HubActivationRecord.self, from: jsonData)
                    }
                    catch {
                        completion(.Error("Failed to process activation response"))
                    }
                    
                    guard let activationRecord = activationRecord else {
                        completion(.Error("No activation record found"))
                        return
                    }
                    completion(.Success(activationRecord))
                }
            }
        }
        catch let error {
            throw error
        }
    }
}
    

// Used to be a lot more here, I cleaned it out for Local Driver
struct HubActivationRecord: Codable {
    
    private enum CodingKeys : String, CodingKey {
        case tariff_version
        case mile_file_version
        case mile_file_location
        case tariff_file_location
        case license_product
        case carrier_id
    }
    
    let tariff_version: Int
    let mile_file_version: Int
    let mile_file_location: String
    let tariff_file_location: String
    let license_product: String
    let carrier_id: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tariff_version_string = try container.decode(String.self, forKey: .tariff_version)
        let mile_file_version_string = try container.decode(String.self, forKey: .mile_file_version)
        let carrier_id_string = try container.decode(String.self, forKey: .carrier_id)
        
        tariff_version = Int(tariff_version_string)!
        mile_file_version = Int(mile_file_version_string)!
        mile_file_location = try container.decode(String.self, forKey: .mile_file_location)
        tariff_file_location = try container.decode(String.self, forKey: .tariff_file_location)
        license_product = try container.decode(String.self, forKey: .license_product)
        carrier_id = Int(carrier_id_string)!
        
    }
}

struct SessionInfo {
    let user: String
    let password: String
    let app_name: String
    let device_id: String
    let device_type: String
    let device_version: String
    let device_software_version: String
}




