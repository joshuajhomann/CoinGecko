//
//  ChartView.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import Charts
import SwiftUI

@MainActor
final class ChartViewModel: ObservableObject {
    @Published private(set) var history: History?
    func callAsFunction(coin: Coin, coinService: CoinService) async {
        do {
            async let history = try await coinService.history(for: coin)
            self.history = try await history
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
        .onChange(of: days) { _ in cachePDF(for: viewModel.history) }
        .onChange(of: viewModel.history) { history in cachePDF(for: history) }
    }

    private func cachePDF(for history: History?) {
        guard let history else { return }
        let pageSize = CGSize(width: 72 * 8.5, height: 72 * 11)
        let chartSize = CGSize(width: pageSize.width - 36, height: pageSize.height - 72)
        let url = URL.documentsDirectory.appending(component: "\(coin.name).pdf")
        let views = [
            AnyView(priceChart(for: history.prices.prefix(days))),
            AnyView(volumeChart(for: history.totalVolumes.prefix(days))),
            AnyView(marketCapChart(for: history.marketCaps.prefix(days)))
        ]
        try? UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize)).pdfData { context in
            for view in views {
                let renderer = ImageRenderer(content: view.frame(width: chartSize.width, height: chartSize.height))
                context.beginPage()
                renderer.render { size, renderIn in
                    context.cgContext.concatenate(.identity
                        .scaledBy(x: 1, y: -1)
                        .translatedBy(x: 0 + 18, y: -pageSize.height + 36)
                    )
                    renderIn(context.cgContext)
                }
            }
        }
        .write(to: url)
        pdfURL = url
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
    private func volumeChart(for volumes: some RandomAccessCollection<History.DatedValue>) -> some View {
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
