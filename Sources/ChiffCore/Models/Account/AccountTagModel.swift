//
//  AccountTag.swift
//
//
//  Created by Dmitriy Starodubtsev on 8.08.2021.
//

import Foundation
import UIKit

public struct AccountTagModel: Hashable {
    public var id: String
    public var title: String
    public var color: AccountTagModel.Color
}

public extension AccountTagModel {
    enum Color: Int, Codable {
        case red    = 0
        case orange = 1
        case yellow = 2
        case green  = 3
        case blue   = 4
        case indigo = 5
        case violet = 6

        public func value() -> UIColor {
            switch self {
            case .red:
                return .red
            case .orange:
                return .orange
            case .yellow:
                return .yellow
            case .green:
                return .green
            case .blue:
                return .blue
            case .indigo:
                return UIColor(red: 75/255, green: 0, blue: 130/255, alpha: 1)
            case .violet:
                return UIColor(red: 143/255, green: 0, blue: 255/255, alpha: 1)
            }
        }
    }
}

extension AccountTagModel: Equatable {
    public static func == (lhs: AccountTagModel, rhs: AccountTagModel) -> Bool {
        return lhs.title == rhs.title && lhs.color == rhs.color &&  lhs.id == rhs.id
    }
}

extension AccountTagModel.Color: Equatable {
    public static func == (lhs: AccountTagModel.Color, rhs: AccountTagModel.Color) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension AccountTagModel: Codable {
    enum CodingKeys: CodingKey {
        case id
        case title
        case color
    }
    
    public init(title: String, color: AccountTagModel.Color) {
        self.id = UUID().uuidString
        self.title = title
        self.color = color
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.title = try values.decode(String.self, forKey: .title)
        self.color = try values.decode(AccountTagModel.Color.self, forKey: .color)
    }
    
    //STUB ONLY
    public static var list: [AccountTagModel] {
        return [AccountTagModel(id: UUID().uuidString, title: "red", color: .red), AccountTagModel(title: "orange", color: .orange), AccountTagModel(title: "yellow", color: .yellow), AccountTagModel(title: "green", color: .green), AccountTagModel(title: "blue", color: .blue), AccountTagModel(title: "indigo", color: .indigo), AccountTagModel(title: "violet", color: .violet)]
    }
}


