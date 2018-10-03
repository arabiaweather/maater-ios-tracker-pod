
//
//  AppDelegate+tracking.swift
//  TrackerIosPOC
//
//  Created by Mohammed O. Tillawy on 9/28/18.
//  Copyright © 2018 MOH TILLAWY. All rights reserved.
//

import Foundation
import SocketIO



public class Tracker {

    public static let shared = Tracker()
    
    var userId: Int = 0
    var clientId: Int = 0
    var name: String = ""
    var email: String = ""
    var trackingId: Int = 0
    var environment: TrackingEnvironment = .development
    
    var manager : SocketManager
    var socket : SocketIOClient
    
    public init() {
        manager = SocketManager(socketURL: URL(string: "http://localhost:8282")!, config: [.log(true), .compress])
        socket = manager.defaultSocket
    }
    

    public func trackUser(env: TrackingEnvironment, userId: Int, clientId: Int, fullname: String, email: String ){
        connectTracking(env: env) {
            self.trackUser(userId: userId, clientId: clientId, fullname: fullname, email: email)
        }
    }
    
    public func resumeTrackingIfAvailable(){
        if ( self.userId != 0 && self.clientId != 0 && !self.name.isEmpty && !self.email.isEmpty ){
            trackUser(env: environment, userId: userId, clientId: clientId, fullname: name, email: email)
        } else  {
            print("no previous saved")
        }
    }
    
    private func trackUser(userId: Int, clientId: Int, fullname: String, email: String ){
        
        guard self.socket.status == .connected else {
            print("NOT CONNECTED TO TRACK")
            return
        }
        
        if (trackingId != 0){
            print("allready tracked, trackingId \(trackingId)")
            return
        }
        
        let c = TrackCommand(userId: userId, clientId: clientId, name: fullname , email: email)
        let encoder = JSONEncoder()
        let d = try! encoder.encode(c)
        let json = String(data: d, encoding: .utf8)!
        let K_TRACK = "track"
        self.socket.emit(K_TRACK, json)
        
        self.userId = userId
        self.clientId = clientId
        self.name = fullname
        self.email = email
    }
    
    private func connectTracking(env: TrackingEnvironment, trackCallback : @escaping () -> ()){
        
        if (socket.status == .connected || socket.status == .connecting){
            return
        }
        environment = env
        
        var server =  "http://localhost:8282"
        let isSecure = env != .development
        let isVerboseLogging = env == .development
        
        switch environment {
        case .development:
            server = "http://macbook-air.duckdns.org:8282"
        case .staging:
            server = "https://staging.tracker.devops.arabiaweather.com"
        case .production:
            server = "https://production.tracker.devops.arabiaweather.com"
        }
        
        manager = SocketManager(socketURL: URL(string: server)!, config: [.log(isVerboseLogging), .secure(isSecure), .compress])
        
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected, time to trackuser")
            trackCallback()
        }
        
        socket.on("tracked", callback: { data , ack  in
            if let arr = data as? Array<[String:Any]>, let dic = arr.first , let pvid = dic["id"] as? Int{
                print("tracked :\n\n", pvid)
                self.trackingId = pvid
            }
        })
        
        socket.connect()
    }
    
    public func disconnectTracking(){
        socket.disconnect()
        self.trackingId = 0
    }
}


public enum TrackingEnvironment {
    case development
    case staging
    case production
}


struct TrackCommand : Codable {
    
    enum CodingKeys: String, CodingKey
    {
        case command
        case userId = "user_id"
        case email
        case name
        case clientId = "client_id"
        case os = "os"
        case osVersion = "os_version"
        case clientType = "client_type"
        case deviceModel = "device_model"
        case deviceBrand = "device_brand"
        case deviceType = "device_type"
        case appId = "app_id"
    }
    
    let command: String = "track"
    let userId: Int
    let name: String
    let email: String
    let clientId: Int
    let os: String = UIDevice.current.systemName
    let osVersion: String = UIDevice.current.systemVersion
    let deviceModel: String = UIDevice.modelName
    let deviceType = 1
    let clientType = "mobile"
    let appId = 2
    let deviceBrand = "Apple"
    
    
    init( userId: Int, clientId: Int, name: String, email: String ) {
        self.userId = userId
        self.clientId = clientId
        self.name = name
        self.email = email
    }
    
}



public extension UIDevice {
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}





enum SchemeEnum: String, Codable
{
    case Http = "http"
    case Https = "https"
}


struct Connection: Codable {
    
    let host: String
    let scheme: SchemeEnum
    let isSecure: Bool
    
    init(host: String, scheme: String ){
        self.host = host
        var p1 = SchemeEnum.Https
        if let p2 = SchemeEnum(rawValue: scheme){
            p1 = p2
        }
        self.scheme = p1
        self.isSecure = self.scheme == .Https
    }
    
}
