//
//  File.swift
//
//
//  Created by Dmitriy Starodubtsev on 27.07.2021.
//

import Foundation

public struct ChiffRequestLogModel: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case siteName
        case sessionID
        case type
        case requsetDate
        case isRejected
        case browserTab
    }
    
    public init(request: ChiffRequest) {
        siteName = request.siteName
        sessionID = request.sessionID
        type = request.type
        isRejected = request.type == .reject
        browserTab = request.browserTab ?? 0
        requsetDate = Date(timeIntervalSince1970: Double(request.sentTimestamp) / 1000.0)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(siteName, forKey: .siteName)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(type, forKey: .type)
        try container.encode(requsetDate, forKey: .requsetDate)
        try container.encode(isRejected, forKey: .isRejected)
        try container.encode(browserTab, forKey: .browserTab)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        siteName = try container.decode(String.self, forKey: .siteName)
        sessionID = try container.decode(String.self, forKey: .sessionID)
        type = try container.decode(ChiffMessageType.self, forKey: .type)
        requsetDate = try container.decode(Date.self, forKey: .requsetDate)
        isRejected = try container.decode(Bool.self, forKey: .isRejected)
        browserTab = try container.decode(Int.self, forKey: .browserTab)
    }
    
    public var isRejected: Bool
    public var siteName: String?
    public var sessionID: String?
    public var type: ChiffMessageType
    public var browserTab: Int
    
    public var dateString: String {
        guard let date = requsetDate else {
            return ""
        }
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "dd-MM-yyyy HH:mm:ss"
        return dateFormatterGet.string(from: date)
    }
   
    private var requsetDate: Date?
    
    public static func == (lhs: ChiffRequestLogModel, rhs: ChiffRequestLogModel) -> Bool {
        return lhs.sessionID == rhs.sessionID &&
            lhs.siteName == rhs.siteName &&
            lhs.browserTab == rhs.browserTab
    }
}
