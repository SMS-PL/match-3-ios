//
//  Gem.swift
//  match-3-ios
//
//  Created by Michał on 29/03/2026.
//

import Foundation

// MARK: - Model klejnotu

/// Pojedynczy klejnot na planszy gry.
/// `type` to indeks (0...5) odpowiadający jednemu z 6 losowo wybranych obrazków w danej rozgrywce.
struct Gem: Identifiable, Equatable {
    let id: UUID
    /// Indeks typu klejnotu (0..<gemTypeCount). Mapowany na obrazek w ViewModel.
    var type: Int
    /// Podświetlenie — klejnot jest częścią dopasowania.
    var isHighlighted: Bool
    /// Klejnot oznaczony do usunięcia (animacja zanikania).
    var isMatched: Bool
    /// Nowo dodany klejnot (animacja pop-in).
    var isNew: Bool

    init(type: Int, isNew: Bool = false) {
        self.id = UUID()
        self.type = type
        self.isHighlighted = false
        self.isMatched = false
        self.isNew = isNew
    }
}
