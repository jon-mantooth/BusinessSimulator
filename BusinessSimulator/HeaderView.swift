//
//  headerView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/23/26.
//

import SwiftUI

struct HeaderView: View {
    let gameState: GameState

    var body: some View {
        HStack {
            Text("Day \(gameState.calendar.day)")

            Spacer()

            Text(gameState.finance.displayedBalance,
                 format: .currency(code: "USD"))
        }
        .padding()
    }
}
