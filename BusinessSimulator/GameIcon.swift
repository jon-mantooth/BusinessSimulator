//
//  GameIcon.swift
//  BusinessSimulator
//

import SwiftUI

enum GameIcon: Equatable {
    case emoji(String)
    case system(String)
    case asset(String)
}

struct GameIconView: View {
    let icon: GameIcon
    let size: CGFloat

    var body: some View {
        Group {
            switch icon {
            case .emoji(let character):
                Text(character)
                    .font(.system(size: size))

            case .system(let name):
                Image(systemName: name)
                    .font(.system(size: size * 0.75))
                    .foregroundStyle(.white)
                    .shadow(color: .gray.opacity(0.8), radius: 1)

            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }
}
