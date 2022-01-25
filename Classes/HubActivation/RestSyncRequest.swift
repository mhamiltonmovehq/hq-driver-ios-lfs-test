//
//  RestSyncRequest.swift
//  Local Crew
//
//  Created by Bob Boatwright on 1/5/21.
//

import Foundation
import os


enum RestResult<T> {
    case Success(T)
    case Error(String)
}

class RestSyncRequest {
//    let logger: Logger
    var scheme, host, basePath, methodPath: String
    var hubResponse = [String: String]()

    
    
    init() {
        scheme = "https://"
        host = "basesync.movecrm.com"
        basePath = "moveCRMSync/api/aicloud"
        methodPath = "Create a new init method that accepts this parameter and move the scheme/host/basepath contents to constants somewhere"
//        logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")
        
        hubResponse =
            ["invalid_key"              : "Invalid Key. Please contact our support team.",
            "expired_key"               : "Expired Key. Please contact our support team.",
            "no_activaiton"             : "Mobile Activation record not found. Please create one at hub.movehq.com or contact our support team.",
            "wrong_id"                  : "The device you are using is different than the one used previously. Please use the previous device or contact our support team to switch devices.",
            "account_disabled"          : "This account is disabled. Please enabled it in hub.movehq.com or contact our support team.",
            "account_locked"            : "This account is locked. Please contact our support team.",
            "invalid_credentials"       : "Your credentials are invalid. Please check your username and password.",
            "missing_info"              : "The device is missing information. Please contact our support team.",
            "no_file"                   : "Account does not have file association. Please contact our support team.",
            "missing_username_password" : "Missing Required Params",
            "account_suspended"         : "Your account is suspended"]
    }
    
    func _buildURLRequest(httpMethod: String,
                          queryParameters: Dictionary<String, String>?,
                          bodyData: Data?,
                          headerData: [String:String]? = nil) -> URLRequest? {
        
        let urlString = "\(scheme)\(host)\(basePath)\(methodPath)"
        guard let url = urlWithQueryParams(url: urlString, queryParams: queryParameters) else {
//            logger.error("Failed to create URL object")
            return nil;
        }
        
        var request = URLRequest(url: url, timeoutInterval: 120.0)
        request.httpMethod = httpMethod
        request.addValue("text/json", forHTTPHeaderField: "Content-Type")
        
        if (headerData != nil) {
            for (key, value) in headerData! {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if (bodyData != nil) {
            request.httpBody = bodyData
            
            let message = String(data: bodyData!, encoding: String.Encoding.utf8)
//            logger.info("Request Body: \(message ?? "Request Body could not be converted to string")")
        }
        
        return request
    }
    
    func executeHttpRequest(httpMethod: String,
                             queryParameters: Dictionary<String, String>?,
                             bodyData: Data?,
                             headerData: [String:String]? = nil,
                             completion: @escaping (RestResult<String>) -> Void) throws {
        
        let request = _buildURLRequest(httpMethod: httpMethod, queryParameters: queryParameters, bodyData: bodyData, headerData: headerData)
        
        // Removed nil-check for request, as the below should catch/throw if nil
        do {
            try executeRequest(request: request!, completion: completion)
        }
        catch let serviceError { // problem sending request/receiving response/creating json object from data
//            logger.error("\(serviceError.localizedDescription)")
            throw serviceError
        }
    }
    
    func executeRequest(request: URLRequest, completion: @escaping (RestResult<String>) -> Void) throws {
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
        
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                completion(.Error("Unknown error"))
                return
            }
            
            guard let responseString = String(data: data, encoding: String.Encoding.utf8) else {
                
                completion(.Error("No response from server"))
                return
            }
            
            
            guard (200 ... 299) ~= response.statusCode else {
                // TODO: handle troubling error codes
                // Add list of codes and generic messages
                if let errorData = responseString.data(using: .utf8) {
                    do {
//                        self.logger.error("\(String(data: errorData, encoding: String.Encoding.utf8) ?? "Unknown error occured in sync request")")
                        guard let jsonDict = try JSONSerialization.jsonObject(with: errorData, options: []) as? Dictionary<String, String> else {
                            
                            // I don't like this, but there are some conditions where errors are passed back in this format
                            let jsonError = try JSONSerialization.jsonObject(with: errorData, options: []) as? [String] ?? nil
                            completion(.Error(jsonError?[0] ?? "Unable to read server error"))
                            
                                return
                            }
                            completion(.Error((self.hubResponse[jsonDict["error"] ?? ""] ?? jsonDict["error"]) ?? "Unable to read server error"))
                        }
                        catch {
                            completion(.Error("Unable to read server error"))
                        }
                    return
                }
                
                completion(.Error("HTTP error \(response.statusCode)"))
                return
            }
            
            
            completion(.Success(responseString))
            
        }.resume()
    }
    
    func executeHttpRequest_legacy(httpMethod: String,
                            queryParameters: Dictionary<String, String>?,
                            bodyData: Data?,
                            headerData: [String:String]? = nil) throws -> String?
    {
        let urlString = "\(scheme)\(host)\(basePath)\(methodPath)"
        guard let url = urlWithQueryParams(url: urlString, queryParams: queryParameters) else {
//            logger.error("Failed to create URL object")
            return nil;
            // throw NSError.init(domain: "Local Crew", code: -1, userInfo: ["Error" : "Failed to create URL object"])
        }
        
        var request = URLRequest(url: url, timeoutInterval: 120.0)
        request.httpMethod = httpMethod
        request.addValue("text/json", forHTTPHeaderField: "Content-Type")
        
        if (headerData != nil) {
            for (key, value) in headerData! {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if (bodyData != nil) {
            request.httpBody = bodyData
            
            let message = String(data: bodyData!, encoding: String.Encoding.utf8)
//            logger.info("Request Body: \(message ?? "Request Body could not be converted to string")")
        }
        
        do {
            let responseString = try executeRequest_legacy(request: request)
//            logger.info("Request Response: \(responseString ?? "No Response Received")")
            
            return responseString;
        } catch {
            throw error
        }
    }
            
    func executeRequest_legacy(request: URLRequest) throws -> String? {
        var urlResponse: URLResponse? = URLResponse.init()
        do {
            // a lot of this seems unsafe. i don't like how I have to force cast so much... hopefully not buggy. Should probably update to the newer method of making calls at some point, but rewriting the current method seemed to not be prudent at the moment
            let response = try NSURLConnection.sendSynchronousRequest(request, returning: &urlResponse)
            let responseString = String(data: response, encoding: String.Encoding.utf8)
            let responseCode = (urlResponse as! HTTPURLResponse).statusCode
            if (responseCode == 200) {
                return responseString
            } else {
                let jsonDict: Dictionary = try JSONSerialization.jsonObject(with: response) as! Dictionary<String, String>
                let badRequest = NSError.init(domain: "Local Crew",
                                               code: responseCode,
                                               userInfo: ["Error" : (jsonDict["ExceptionMessage"] ?? "No Exception Message Found")]) // this code may need to change based on how the error responses look from hub
                
                throw badRequest
            }
        } catch let serviceError { // problem sending request/receiving response/creating json object from data
//            logger.error("\(serviceError.localizedDescription)")
            throw serviceError
        }
    }
    
    func urlWithQueryParams(url: String, queryParams: Dictionary<String, String>?) -> URL? {
        var params = Array<URLQueryItem>.init()
        if let queryDict = queryParams {
            for (key, value) in queryDict {
                let queryItem = URLQueryItem.init(name: key, value: value)
                params.append(queryItem)
            }
        }
        
        var components = URLComponents.init(url: URL.init(string: url)! , resolvingAgainstBaseURL: false)
        
        if (components != nil) {
            components?.queryItems = params
        }
        return components?.url
    }
}
