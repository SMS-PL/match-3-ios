//
//  GemView.swift
//  match-3-ios
//
//  Created by Michał on 29/03/2026.
//

import SwiftUI

// MARK: - Widok pojedynczego klejnotu

/// Wyświetla pojedynczy klejnot jako obrazek z Assets.
struct GemView: View {
    /// Klejnot do wyświetlenia.
    let gem: Gem
    /// Nazwa obrazka w zasobach.
    let imageName: String
    /// Czy klejnot jest aktualnie zaznaczony przez gracza.
    let isSelected: Bool

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            // Dopasowanie — przyciemnienie przed zniknięciem
            .opacity(gem.isHighlighted ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: gem.isHighlighted)
            // Zanikanie
            .opacity(gem.isMatched ? 0.0 : 1.0)
            .scaleEffect(gem.isMatched ? 0.3 : 1.0)
            .animation(.easeIn(duration: 0.25), value: gem.isMatched)
            // Pop-in nowych
            .scaleEffect(gem.isNew ? 0.0 : 1.0)
            .opacity(gem.isNew ? 0.0 : 1.0)
    }
}

#Preview {
    HStack {
        GemView(gem: Gem(type: 0), imageName: "pic1", isSelected: false)
        GemView(gem: Gem(type: 1), imageName: "pic2", isSelected: true)
        GemView(gem: Gem(type: 2), imageName: "pic3", isSelected: false)
    }
    .padding()
}
