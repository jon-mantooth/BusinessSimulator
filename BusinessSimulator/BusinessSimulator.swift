//
//  HelloSwiftApp.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/12/26.
//

import SwiftUI

@main
struct BusinessSimulator: App {
    private let saveRepository: FileGameSaveRepository?

    init() {
        saveRepository = try? FileGameSaveRepository()
    }

    var body: some Scene {
        WindowGroup {
            if let saveRepository {
                GameRootView(
                    saveRepository: saveRepository
                )
            } else {
                // TODO: Replace this temporary failure screen with a
                // production recovery flow that supports retrying repository
                // initialization and decides whether warned play without
                // saving should be allowed.
                ContentUnavailableView(
                    "Unable to Access Saved Games",
                    systemImage: "exclamationmark.triangle",
                    description: Text(
                        "Business Simulator could not access its save folder."
                    )
                )
            }
        }
    }
}

//@main
//struct BusinessSimulatorApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ZStack {
//                Color.white
//                    .ignoresSafeArea()
//
//                Text("APP ENTRY LOADED")
//                    .font(.largeTitle)
//                    .foregroundStyle(.red)
//            }
//        }
//    }
//}
