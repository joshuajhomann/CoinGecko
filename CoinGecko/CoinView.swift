//
//  ContentView.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import SwiftUI

@MainActor
final class CoinViewModel: ObservableObject, WritableByIsolatedKeyPath {
    @Published var searchTerm = ""
    @Published private(set) var coins: [Coin] = []
    nonisolated func callAsFunction(coinService: CoinService) async {
        var taskHandle: Task<[Coin], Error>?
        for await term in await $searchTerm.values.dropFirst() {
            taskHandle?.cancel()
            let task = Task {
                try await coinService.coins(named: term)
            }
            taskHandle = task
            do {
                await set(\.coins, value: try await task.value)
            } catch {
                print(error)
            }
        }

    }
}

struct CoinView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = CoinViewModel()
    @EnvironmentObject private var coinService: CoinService

    var body: some View {
        NavigationSplitView {
            List(viewModel.coins) { coin in
                NavigationLink {
                    ChartView(coin: coin).id(coin)
                } label: {
                    HStack(alignment: .center) {
                        AsyncImage(url: coin.thumb) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().foregroundColor(Color(uiColor: .tertiarySystemFill))
                        }
                        .frame(width: 30, height: 30)
                        VStack(alignment: .leading) {
                            Text(coin.symbol)
                            Text(coin.name).foregroundColor(.secondary).font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Coin Gecko")
            .searchable(text: $searchText)
            .disableAutocorrection(true)
            .onSubmit(of: .search) { viewModel.searchTerm = searchText }
        } detail: {
            Text("Select a coin")
        }
        .task { await viewModel(coinService: coinService) }
    }
}

