//
//  CoinGeckoApp.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import SwiftUI

@main
struct CoinGeckoApp: App {
    @StateObject private var coinService = CoinService()
    var body: some Scene {
        WindowGroup {
            CoinView()
                .environmentObject(coinService)
        }
    }
}
