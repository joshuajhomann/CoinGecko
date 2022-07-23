//
//  ContentView.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import SwiftUI

@MainActor
final class CoinViewModel: ObservableObject {
    @Published var searchTerm = ""
    @Published private(set) var coins: [Coin] = []
    private var taskHandle: Task<[Coin], Error>?
    deinit {
        taskHandle?.cancel()
    }
    func callAsFunction(coinService: CoinService) async {
        for await term in $searchTerm.values.dropFirst() {
            taskHandle?.cancel()
            let task = Task.detached {
                try await coinService.coins(named: term)
            }
            taskHandle = task
            do {
                coins = try await task.value
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
