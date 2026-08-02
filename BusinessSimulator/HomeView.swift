//
//  ContentView.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/12/26.
//

import SwiftUI

struct HomeView: View {
    
    let onBeginJourney: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Business Simulator")
                .font(.largeTitle)
            
            Button("Begin Your Journey"){
                onBeginJourney()
            }
        }
        .padding()
    }
}

#Preview {
    HomeView(
        onBeginJourney: {
            print("Begin Journey pressed")
        }
    )
}
