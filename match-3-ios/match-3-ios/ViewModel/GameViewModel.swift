//
//  GameViewModel.swift
//  match-3-ios
//
//  Created by Michał on 29/03/2026.
//

import SwiftUI

// MARK: - Stan gry

/// Reprezentuje bieżący stan rozgrywki.
enum GameState: Equatable {
    case playing
    case animating
    case gameOver
}

// MARK: - Kierunek przesunięcia

/// Kierunek gestu przesunięcia (swipe).
enum SwipeDirection {
    case up, down, left, right
}

// MARK: - ViewModel gry

/// Główny ViewModel zarządzający logiką gry match-3.
@Observable
final class GameViewModel {

    // MARK: - Stałe

    let boardRows = 6
    let boardCols = 5
    let startingMoves = 10
    let startingShuffles = 3
    /// Liczba typów klejnotów używanych w jednej rozgrywce.
    let gemTypeCount = 6
    /// Wszystkie dostępne obrazki w Assets (pic1...pic19).
    private let allImages = (1...19).map { "pic\($0)" }
    private let pointsPerGem = 10

    // MARK: - Czasy animacji (sekundy)

    private let highlightDuration: Double = 0.4
    private let fadeDuration: Double = 0.3
    private let popDelay: Double = 0.15

    // MARK: - Stan gry

    var board: Board
    var score: Int = 0
    var movesRemaining: Int = 10
    var shufflesRemaining: Int = 3
    var gameState: GameState = .playing
    var selectedPosition: Position? = nil
    var statusMessage: String = "Wybierz klejnot i przesuń!"
    var noLegalMoves: Bool = false

    /// 6 losowo wybranych obrazków na bieżącą rozgrywkę. Index odpowiada `gem.type`.
    var activeImages: [String] = []

    // MARK: - Inicjalizacja

    init() {
        self.activeImages = Array(allImages.shuffled().prefix(6))
        self.board = Board(rows: 6, cols: 5, typeCount: 6)
        self.movesRemaining = startingMoves
        self.shufflesRemaining = startingShuffles
        checkForLegalMoves()
    }

    // MARK: - Nowa gra

    func newGame() {
        activeImages = Array(allImages.shuffled().prefix(gemTypeCount))
        board = Board(rows: boardRows, cols: boardCols, typeCount: gemTypeCount)
        score = 0
        movesRemaining = startingMoves
        shufflesRemaining = startingShuffles
        gameState = .playing
        selectedPosition = nil
        noLegalMoves = false
        statusMessage = "Nowa gra! Wybierz klejnot i przesuń."
        checkForLegalMoves()
    }

    /// Zwraca nazwę obrazka dla danego klejnotu.
    func imageName(for gem: Gem) -> String {
        activeImages[gem.type]
    }

    // MARK: - Ręczne przetasowanie

    /// Przetasowuje planszę (ręcznie przez gracza). Zużywa 1 przetasowanie.
    func shuffle() {
        guard gameState == .playing, shufflesRemaining > 0 else { return }
        shufflesRemaining -= 1
        board = Board(rows: boardRows, cols: boardCols, typeCount: gemTypeCount)
        noLegalMoves = false
        statusMessage = "Przetasowano! Pozostało: \(shufflesRemaining)"
        checkForLegalMoves()
    }

    // MARK: - Obsługa zaznaczenia klejnotu

    func selectGem(at position: Position) {
        guard gameState == .playing else { return }

        if let selected = selectedPosition {
            if selected == position {
                selectedPosition = nil
                statusMessage = "Odznaczono. Wybierz klejnot."
            } else if selected.isAdjacent(to: position) {
                performSwap(from: selected, to: position)
            } else {
                selectedPosition = position
                statusMessage = "Wybrano klejnot. Przesuń na sąsiedni."
            }
        } else {
            selectedPosition = position
            statusMessage = "Wybrano klejnot. Przesuń na sąsiedni."
        }
    }

    // MARK: - Zamiana klejnotów (gest przesunięcia)

    func handleSwipe(from position: Position, direction: SwipeDirection) {
        guard gameState == .playing else { return }

        let target: Position
        switch direction {
        case .up:    target = Position(row: position.row - 1, col: position.col)
        case .down:  target = Position(row: position.row + 1, col: position.col)
        case .left:  target = Position(row: position.row, col: position.col - 1)
        case .right: target = Position(row: position.row, col: position.col + 1)
        }

        guard board.isValid(position: target) else {
            statusMessage = "Nie można przesunąć poza planszę!"
            return
        }

        performSwap(from: position, to: target)
    }

    // MARK: - Logika zamiany i dopasowań

    private func performSwap(from: Position, to: Position) {
        gameState = .animating
        selectedPosition = nil

        board.swap(from: from, to: to)
        let matches = findMatches()

        if matches.isEmpty {
            statusMessage = "Brak dopasowania! Ruch cofnięty."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.board.swap(from: from, to: to)
                self.gameState = .playing
            }
        } else {
            movesRemaining -= 1
            runMatchSequence(matches, isCascade: false)
        }
    }

    // MARK: - Sekwencja animacji dopasowania

    private func runMatchSequence(_ matches: Set<Position>, isCascade: Bool) {
        let matchCount = matches.count
        score += matchCount * pointsPerGem

        let getsBonus = matchCount >= 4 || isCascade
        if getsBonus {
            movesRemaining += 1
            statusMessage = "Dopasowanie! +\(matchCount * pointsPerGem) pkt, +1 ruch!"
        } else {
            statusMessage = "Dopasowanie! +\(matchCount * pointsPerGem) pkt"
        }

        // Krok 1: Podświetl dopasowane klejnoty
        withAnimation(.easeInOut(duration: 0.2)) {
            for pos in matches {
                board.grid[pos.row][pos.col].isHighlighted = true
            }
        }

        // Krok 2: Animacja zanikania
        DispatchQueue.main.asyncAfter(deadline: .now() + highlightDuration) { [weak self] in
            guard let self else { return }
            withAnimation(.easeIn(duration: self.fadeDuration)) {
                for pos in matches {
                    self.board.grid[pos.row][pos.col].isMatched = true
                }
            }

            // Krok 3: Usuń i wstaw nowe
            DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeDuration) { [weak self] in
                guard let self else { return }
                self.removeAndRefill(matches: matches)

                // Krok 4: Pop-in nowych klejnotów
                let newPositions = self.collectNewGemPositions()
                self.animatePopIn(positions: newPositions) {
                    // Krok 5: Sprawdź kaskadowe dopasowania
                    let cascadeMatches = self.findMatches()
                    if !cascadeMatches.isEmpty {
                        self.runMatchSequence(cascadeMatches, isCascade: true)
                    } else {
                        self.finishTurn()
                    }
                }
            }
        }
    }

    private func collectNewGemPositions() -> [Position] {
        var positions: [Position] = []
        for row in 0..<boardRows {
            for col in 0..<boardCols {
                if board.grid[row][col].isNew {
                    positions.append(Position(row: row, col: col))
                }
            }
        }
        return positions
    }

    private func animatePopIn(positions: [Position], completion: @escaping () -> Void) {
        guard !positions.isEmpty else {
            completion()
            return
        }

        for (index, pos) in positions.enumerated() {
            let delay = Double(index) * popDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    self.board.grid[pos.row][pos.col].isNew = false
                }
            }
        }

        let totalDelay = Double(positions.count) * popDelay + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            completion()
        }
    }

    /// Kończy turę — sprawdza legalne ruchy i koniec gry.
    private func finishTurn() {
        if movesRemaining <= 0 {
            gameState = .gameOver
            statusMessage = "Koniec gry! Wynik: \(score) pkt"
            return
        }

        checkForLegalMoves()

        if noLegalMoves && shufflesRemaining <= 0 {
            gameState = .gameOver
            statusMessage = "Brak ruchów i przetasowań! Wynik: \(score) pkt"
        } else if noLegalMoves {
            gameState = .playing
            statusMessage = "Brak ruchów! Użyj przetasowania. (\(shufflesRemaining) pozostało)"
        } else {
            gameState = .playing
        }
    }

    /// Sprawdza czy istnieje legalny ruch i ustawia flagę `noLegalMoves`.
    private func checkForLegalMoves() {
        noLegalMoves = !hasLegalMove()
    }

    // MARK: - Usuwanie i uzupełnianie

    private func removeAndRefill(matches: Set<Position>) {
        for col in 0..<boardCols {
            var column = (0..<boardRows).map { board.grid[$0][col] }
            column.removeAll { $0.isMatched }

            let needed = boardRows - column.count
            let newGems = (0..<needed).map { _ in Gem(type: Int.random(in: 0..<self.gemTypeCount), isNew: true) }
            column = newGems + column

            for row in 0..<boardRows {
                board.grid[row][col] = column[row]
            }
        }
    }

    // MARK: - Wykrywanie dopasowań

    func findMatches() -> Set<Position> {
        var matched = Set<Position>()

        for row in 0..<boardRows {
            for col in 0..<(boardCols - 2) {
                let g0 = board.grid[row][col]
                let g1 = board.grid[row][col + 1]
                let g2 = board.grid[row][col + 2]
                guard !g0.isMatched, !g1.isMatched, !g2.isMatched else { continue }
                if g0.type == g1.type && g1.type == g2.type {
                    matched.insert(Position(row: row, col: col))
                    matched.insert(Position(row: row, col: col + 1))
                    matched.insert(Position(row: row, col: col + 2))
                }
            }
        }

        for col in 0..<boardCols {
            for row in 0..<(boardRows - 2) {
                let g0 = board.grid[row][col]
                let g1 = board.grid[row + 1][col]
                let g2 = board.grid[row + 2][col]
                guard !g0.isMatched, !g1.isMatched, !g2.isMatched else { continue }
                if g0.type == g1.type && g1.type == g2.type {
                    matched.insert(Position(row: row, col: col))
                    matched.insert(Position(row: row + 1, col: col))
                    matched.insert(Position(row: row + 2, col: col))
                }
            }
        }

        return matched
    }

    // MARK: - Sprawdzanie legalnych ruchów

    func hasLegalMove() -> Bool {
        let directions = [(0, 1), (1, 0)]

        for row in 0..<boardRows {
            for col in 0..<boardCols {
                for (dr, dc) in directions {
                    let nr = row + dr
                    let nc = col + dc
                    guard nr < boardRows, nc < boardCols else { continue }

                    board.swap(
                        from: Position(row: row, col: col),
                        to: Position(row: nr, col: nc)
                    )
                    let hasMatch = !findMatches().isEmpty
                    board.swap(
                        from: Position(row: row, col: col),
                        to: Position(row: nr, col: nc)
                    )

                    if hasMatch { return true }
                }
            }
        }
        return false
    }
}
