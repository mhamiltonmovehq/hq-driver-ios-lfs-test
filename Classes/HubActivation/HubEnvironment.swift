//
//  HubEnvironment.swift
//  Local Crew
//
//  Created by Matthew Hamilton on 2/22/21.
//

import Foundation

struct HubEnvironment {
    enum Environments: String {
        case qa
        case uat
        case prod
        
        // Handling Enum values this way allows us to convert from a string config code -> rawValue -> string value
        // ex. Config Code as "qa" can map to Environments.qa.rawValue which gives qa.baseUrl as hub-qa.movehq.com
        var baseUrl: String {
            switch self {
            case .qa:
                return "hub-qa.movehq.com"
            case .uat:
                return "hub-uat.movehq.com"
            default:
                return "hub.movehq.com"
            }
        }
        
        var jwtSecret: String {
            switch self {
            case .qa, .uat:
                return "asdflasdnglansdoin2iotaodhflaksjdhlaiosdjflk2lkfbalskdjfaoijdlakdnsflkajnsdf"
            default:
                return "kjdsfhisfdfsdfs4YWExTXdNSGhVV0d4WVlsUkdWRmx0ZEikfjouu2fh272xc1NubFVWbFp2VkRdss"
            }
        }
    }
    
    static func environmentURL () -> String {
        
        let envString = UserDefaults.standard.string(forKey: "config_code") ?? "prod"
        
        guard let env = Environments(rawValue: envString) else {
            return Environments.prod.baseUrl
        }
        
        return env.baseUrl
    }
    
    static func environmentJWT () -> String {
        
        let envString = UserDefaults.standard.string(forKey: "config_code") ?? "prod"
        
        guard let env = Environments(rawValue: envString) else {
            return Environments.prod.jwtSecret
        }
        
        return env.jwtSecret
    }
}
