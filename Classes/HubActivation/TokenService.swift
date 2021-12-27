//
//  TokenService.swift
//  Survey HHG
//
//  Created by Clinton Sexton on 11/16/21.
//

import Foundation
import UIKit

@objc(TokenResponseProtocol) protocol TokenWrapperProtocol {
    func verifyTokenResponseCompleted (result: TokenResponseWrapperResult)
    func refreshTokenResponseCompleted (result: TokenResponseWrapperResult)
}

@objc class HubToken : NSObject, Codable {
    
    private enum CodingKeys : String, CodingKey {
        case access_token
        case token_type
        case expires_in
    }

    let access_token: String
    let token_type: String
    let expires_in: Int
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        access_token = try container.decode(String.self, forKey: .access_token)
        token_type = try container.decode(String.self, forKey: .token_type)
        expires_in = try container.decode(Int.self, forKey: .expires_in)
    }
    
    @objc func _access_token() -> String { return access_token }
    @objc func _token_type() -> String {return token_type }
    @objc func _expires_in() -> Int { return expires_in }
            
}



@objc class TokenResponseWrapperResult: NSObject {
    @objc var errorMessage: String
    @objc var success: Bool
    
    override init() {
        errorMessage = ""
        success = false
    }
    
    @objc func getSuccess() -> ObjCBool{
        return ObjCBool(success)
    }
}

@objc class TokenWrapper: NSObject {
    @objc var caller: TokenWrapperProtocol?
    @objc func verifyToken(jwt: String, caller: TokenWrapperProtocol) {
         
        self.caller = caller
        let appName = "Driver"
        do {
            try TokenService.shared._verifyToken(jwt: jwt, info: appName, completion: verifyCompleted)
        }
        catch let error {
            print(error)
        }
    }
    
    func verifyCompleted(result: RestResult<Bool>) {
        switch (result){
            case .Success(let data):
                let tResult = TokenResponseWrapperResult()
                tResult.success = data
                caller?.verifyTokenResponseCompleted(result: tResult)
            case .Error(let msg):
                let tResult = TokenResponseWrapperResult()
                tResult.success = false
                tResult.errorMessage = msg
                caller?.verifyTokenResponseCompleted(result: tResult)
        }
    }
    
    @objc func  refreshToken(jwt: String){
        
        let appName = "Driver"
        
        do {
            try TokenService.shared._refreshToken(jwt: jwt, info: appName, completion: verifyRefreshCompleted)
        }
        catch let error {
            print (error)
        }
    }
    
    func verifyRefreshCompleted(result: RestResult<HubToken>) {
        let del = UIApplication.shared.delegate as? SurveyAppDelegate

        switch (result) {
        case .Success(let token):
                del?.session = token
        case .Error(let errorMsg):
            let tokenResult = TokenResponseWrapperResult()
            tokenResult.success = false
            tokenResult.errorMessage = errorMsg
            caller?.refreshTokenResponseCompleted(result: tokenResult)
            
        }
    }
}

class TokenService {
    static let shared = TokenService()
    

    func _getToken (info: SessionInfo, completion: @escaping (RestResult<HubToken>) -> Void) throws  {
        
        let del = UIApplication.shared.delegate as? SurveyAppDelegate
        let request = RestSyncRequest()
        var hubToken: HubToken? = nil
        let headerVals = ["application" : "x-www-form-urlencoded"]
        let params = ["username"                : info.user,
                      "password"                : info.password,
                      "product"                 : info.app_name,
                      "device_id"               : info.device_id,
                      "device_type"             : info.device_type,
                      "device_version"          : info.device_version,
                      "device_software_version" : info.device_software_version]
        request.scheme = "https://"
        request.host = HubEnvironment.environmentURL()
        request.basePath = "/api"
        request.methodPath = "/token"

        let body = try? JSONSerialization.data(withJSONObject: params, options:[])   //JSONEncoder().encode(z

         do {
            try request.executeHttpRequest(httpMethod: "POST", queryParameters:nil, bodyData:body , headerData: headerVals) {result in
                switch (result) {
                case .Success(let response):
                    let jsonData = Data(response.utf8)
                    let decoder = JSONDecoder()
                    do {
                        hubToken = try decoder.decode(HubToken.self, from: jsonData)
                        del?.session = hubToken
                    }
                    catch let error {
                        print(error)
                        completion(.Error(error.localizedDescription))
                        return
                    }
                    guard let hubToken = hubToken else {
                        completion(.Error("Unknown error has Occured"))
                        return
                    }
                    completion(.Success(hubToken))
                    return
                case .Error(let errorMsg):
                    completion(.Error(errorMsg))
                    return
                }
            }
        }
    }
    func _refreshToken (jwt: String, info: String, completion: @escaping (RestResult<HubToken>) -> Void) throws  {
        
        let del = UIApplication.shared.delegate as? SurveyAppDelegate
        let headerValues = ["Authorization" : "Bearer " + jwt]
        let request = RestSyncRequest()
        var hubToken: HubToken? = nil
        let params = ["product" : info]
        
        request.scheme = "https://"
        request.host = HubEnvironment.environmentURL()
        request.basePath = "/api"
        request.methodPath = "/token/refresh"
        
        do {
           try request.executeHttpRequest(httpMethod: "GET", queryParameters:params, bodyData:nil , headerData: headerValues) {result in
               switch (result) {
               case .Success(let response):
                   let jsonData = Data(response.utf8)
                   let decoder = JSONDecoder()
                   do {
                       hubToken = try decoder.decode(HubToken.self, from: jsonData)
                   }
                   catch let error {
                       print(error)
                       completion(.Error(error.localizedDescription))
                   }
                   guard let hubToken = hubToken else {
                       completion(.Error("Unknown error has Occured"))
                       return
                   }
                   completion(.Success(hubToken))
                   return
               case .Error(let errorMsg):
                   completion(.Error(errorMsg))
                   return
               }
           }
        }
        catch let error {
            completion(.Error(error.localizedDescription))
        }
    }

    func _verifyToken (jwt: String, info: String, completion: @escaping (RestResult<Bool>) -> Void) throws {
        let headerValues = ["Authorization" : "Bearer " + jwt]
        let request = RestSyncRequest()
        let params = ["product"                : info]
        var returnResponse = Dictionary<String , Bool>()
        var returnBool = Bool()
        
        request.scheme = "https://"
        request.host = HubEnvironment.environmentURL()
        request.basePath = "/api"
        request.methodPath = "/token/verify"
        
        
        do {
            try request.executeHttpRequest(httpMethod: "GET", queryParameters:params, bodyData:nil , headerData: headerValues) {result in
                switch (result) {
                case .Success(let response):
                                       let jsonData = Data(response.utf8)
                        let decoder = JSONDecoder()
                        do {
                            //TODO: fix me
                            returnResponse = try decoder.decode(Dictionary.self, from: jsonData)
                            returnBool = returnResponse["success"]!
                            completion(.Success(returnBool))
                        }
                        catch let error {  // something other than true or false
                            print(error)
                            completion(.Error(error.localizedDescription))
                        }
                    case .Error(let errorMsg): // api error
                        completion(.Error(errorMsg))
                }
            }
        }
        catch let error {
            completion(.Error(error.localizedDescription))
        }
    }
}
