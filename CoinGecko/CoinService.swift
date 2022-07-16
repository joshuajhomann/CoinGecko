//
//  CoinService.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import Foundation

actor CoinService: ObservableObject {
    private let decoder = JSONDecoder()
    func coins(named query: String) async throws -> [Coin] {
        var components = URLComponents()
        components.scheme = Constant.scheme
        components.host = Constant.host
        components.path = Constant.searchPath
        components.queryItems = [.init(name: Constant.searchKey, value: query)]
        guard let url = components.url else { throw CustomError("Invalid url for \(query)") }
        return try await value(ofType: CoinWrapper.self, from: url, transform: \.coins)
    }
    func history(for coin: Coin) async throws -> History {
        var components = URLComponents()
        components.scheme = Constant.scheme
        components.host = Constant.host
        components.path = Constant.historyPath.replacingOccurrences(of: Constant.idKey, with: coin.id)
        components.queryItems = [
            .init(name: Constant.currencyKey, value: Constant.currencyValue),
            .init(name: Constant.dayKey, value: String(describing: Constant.dayValue))
        ]
        guard let url = components.url else { throw CustomError("Invalid url for \(coin.id)") }
        return try await value(ofType: RawHistory.self, from: url) { rawHistory in
            History(
                prices: try rawHistory.prices.lazy.map(History.DatedValue.init(_:)).reversed(),
                marketCaps: try rawHistory.marketCaps.lazy.map(History.DatedValue.init(_:)).reversed(),
                totalVolumes: try rawHistory.totalVolumes.lazy.map(History.DatedValue.init(_:)).reversed()
            )
        }
    }

    func value<SomeDecodable: Decodable, Transformed>(
        ofType: SomeDecodable.Type,
        from url: URL,
        transform: @escaping (SomeDecodable) throws -> Transformed
    ) async throws -> Transformed {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try decoder.decode(SomeDecodable.self, from: data)
        return try transform(decoded)
    }
}

extension CoinService {
    enum Constant {
        static let scheme = "https"
        static let host = "api.coingecko.com"
        static let searchPath = "/api/v3/search"
        static let searchKey = "query"
        static let historyPath = "/api/v3/coins/{id}/market_chart"
        static let idKey = "{id}"
        static let currencyKey = "vs_currency"
        static let currencyValue = "usd"
        static let dayKey = "days"
        static let dayValue = 365
    }
}
