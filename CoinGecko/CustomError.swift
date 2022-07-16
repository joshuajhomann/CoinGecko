//
//  CustomError.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import Foundation

enum CustomError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case let .message(message): return message
        }
    }
    init(_ message: String) {
        self = .message(message)
    }
}
