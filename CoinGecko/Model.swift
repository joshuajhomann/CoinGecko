//
//  Model.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import Foundation

struct CoinWrapper: Codable {
    var coins: [Coin]
}


struct Coin: Codable, Identifiable, Hashable {
    var id, name, symbol: String
    var marketCapRank: Int
    var thumb, large: URL

    enum CodingKeys: String, CodingKey {
        case id, name, symbol
        case marketCapRank = "market_cap_rank"
        case thumb, large
    }
}

struct RawHistory: Codable {
    var prices, marketCaps, totalVolumes: [[Double]]

    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
}

struct History {
    struct DatedValue: Identifiable {
        var id: UUID
        var date: Date
        var value: Decimal
    }
    var prices, marketCaps, totalVolumes: [DatedValue]
}

extension History.DatedValue {
    init(_ json: [Double]) throws {
        guard json.count == 2 else { throw CustomError("Bad json: \(json)") }
        guard let date = TimeInterval(exactly: json[0] * 1e-3).map(Date.init(timeIntervalSince1970:)) else { throw CustomError("Bad date: \(json[0])") }
        self.date = date
        self.value = Decimal(json[1])
        self.id = UUID()
    }
}
