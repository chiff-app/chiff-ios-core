//
//  File.swift
//
//
//  Created by Dmitriy Starodubtsev on 27.07.2021.
//

import Foundation

public struct ChiffRequestLogModel: Codable {
    enum CodingKeys: String, CodingKey {
        case siteName
        case sessionID
        case type
        case requsetDate
    }
    
    public init(request: ChiffRequest) {
        siteName = request.siteName
        sessionID = request.sessionID
        type = request.type
        
        //TODO: - NEED TO CHANGE DATE INIT !!!!
        requsetDate = Date(timeIntervalSince1970: request.sentTimestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(siteName, forKey: .siteName)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(type, forKey: .type)
        try container.encode(requsetDate, forKey: .requsetDate)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        siteName = try container.decode(String.self, forKey: .siteName)
        sessionID = try container.decode(String.self, forKey: .sessionID)
        type = try container.decode(ChiffMessageType.self, forKey: .type)
        requsetDate = try container.decode(Date.self, forKey: .requsetDate)
    }
    
    public var siteName: String?
    public var sessionID: String?
    public var type: ChiffMessageType
    
    public var dateString: String {
        guard let date = requsetDate else {
            return ""
        }
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "dd-MM-yyyy HH:mm:ss"
        return dateFormatterGet.string(from: date)
    }
   
    private var requsetDate: Date?
}
