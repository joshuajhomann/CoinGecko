//
//  ChartView.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import Charts
import SwiftUI

@MainActor
final class ChartViewModel: ObservableObject, WritableByIsolatedKeyPath {
    @Published private(set) var history: History?
    nonisolated func callAsFunction(coin: Coin, coinService: CoinService) async {
        do {
            let history = try await coinService.history(for: coin)
            await set(\.history, value: history)
        } catch {
            print(error)
        }
    }
}


struct ChartView: View {
    @StateObject private var viewModel = ChartViewModel()
    @EnvironmentObject private var coinService: CoinService
    @State var days = Self.allDays[0]
    @State var pdfURL: URL?
    static let allDays = [7,30,90,180,365]
    var coin: Coin
    var body: some View {
        VStack(spacing: 0) {
            Text("Period")
            Picker("", selection: $days) {
                ForEach(Self.allDays, id: \.self) { days in
                    Text("\(days) Days").tag(days)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            Divider().padding(.top)
            if let history = viewModel.history {
                ScrollView(.vertical) {
                    VStack {
                        priceChart(for: history.prices.prefix(days))
                        volumeChart(for: history.totalVolumes.prefix(days))
                        marketCapChart(for: history.marketCaps.prefix(days))
                    }.padding()
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(coin.name)
        .toolbar {
            ToolbarItem {
                if let pdfURL {
                    ShareLink(item: pdfURL)
                }
            }
        }
        .task { await viewModel(coin: coin, coinService: coinService) }
    }

    @ViewBuilder
    private func priceChart(for prices: some RandomAccessCollection<History.DatedValue>) -> some View {
        Text("\(coin.name) Price")
        Chart(prices) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("USD", point.value)
            )
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value("Date", point.date),
                y: .value("USD", point.value)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    private func volumeChart(for volumes: some RandomAccessCollection <History.DatedValue>) -> some View {
        Text("\(coin.name) Volume")
        Chart(volumes) { point in
            BarMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.value)
            )
            .foregroundStyle(Gradient(colors: [.blue, .green, .red]))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func marketCapChart(for marketCaps: some RandomAccessCollection<History.DatedValue>) -> some View {
        Text("\(coin.name) Market Cap")
        Chart(marketCaps.prefix(days)) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("USD", point.value)
            )
            .foregroundStyle(.green.gradient)
            PointMark(
                x: .value("Date", point.date),
                y: .value("USD", point.value)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
