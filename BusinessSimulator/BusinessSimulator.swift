//
//  HelloSwiftApp.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/12/26.
//

import SwiftUI

@main
struct BusinessSimulator: App {
    @State private var saveRepository: FileGameSaveRepository?

    init() {
        _saveRepository = State(
            initialValue: try? FileGameSaveRepository()
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let saveRepository {
                    GameRootView(
                        saveRepository: saveRepository
                    )
                } else {
                    ContentUnavailableView(
                        label: {
                            Label(
                                "Saved Games Unavailable",
                                systemImage: "exclamationmark.triangle"
                            )
                        },
                        description: {
                            Text(
                                "The game cannot access its saved-game storage. If the issue persists, close and reopen the app and check that your device has available storage."
                            )
                        },
                        actions: {
                            Button("Try Again") {
                                saveRepository = try? FileGameSaveRepository()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    )
                }
            }
            .preferredColorScheme(.light)
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
