//
//  FooterView.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/22/26.
//

import SwiftUI

struct FooterView: View {
    let onNavigate: (Screen) -> Void
    let resetDisplayedBalance: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Button {
                resetDisplayedBalance()
                onNavigate(.home)
            } label: {
                Image(systemName: "house.fill")
            }

            Spacer()
        }
        .padding()
    }
}
