//
//  Board.swift
//  match-3-ios
//
//  Created by Michał on 29/03/2026.
//

import Foundation

// MARK: - Model planszy

/// Plansza gry match-3 o rozmiarze `rows` × `cols`.
/// Przechowuje dwuwymiarową siatkę klejnotów (`Gem`).
struct Board {
    /// Liczba wierszy planszy.
    let rows: Int
    /// Liczba kolumn planszy.
    let cols: Int
    /// Liczba różnych typów klejnotów w grze.
    let typeCount: Int
    /// Dwuwymiarowa siatka klejnotów: `grid[wiersz][kolumna]`.
    var grid: [[Gem]]

    /// Tworzy nową planszę wypełnioną losowymi klejnotami bez początkowych dopasowań.
    init(rows: Int = 6, cols: Int = 5, typeCount: Int = 6) {
        self.rows = rows
        self.cols = cols
        self.typeCount = typeCount
        self.grid = Self.generateGrid(rows: rows, cols: cols, typeCount: typeCount)
    }

    /// Generuje siatkę klejnotów bez początkowych dopasowań trzech w rzędzie.
    private static func generateGrid(rows: Int, cols: Int, typeCount: Int) -> [[Gem]] {
        var grid = [[Gem]]()
        for _ in 0..<rows {
            var row = [Gem]()
            for _ in 0..<cols {
                row.append(Gem(type: Int.random(in: 0..<typeCount)))
            }
            grid.append(row)
        }
        // Usuwanie początkowych dopasowań
        var hasMatch = true
        while hasMatch {
            hasMatch = false
            for row in 0..<rows {
                for col in 0..<cols {
                    if col >= 2,
                       grid[row][col].type == grid[row][col - 1].type,
                       grid[row][col].type == grid[row][col - 2].type {
                        grid[row][col] = Gem(type: Int.random(in: 0..<typeCount))
                        hasMatch = true
                    }
                    if row >= 2,
                       grid[row][col].type == grid[row - 1][col].type,
                       grid[row][col].type == grid[row - 2][col].type {
                        grid[row][col] = Gem(type: Int.random(in: 0..<typeCount))
                        hasMatch = true
                    }
                }
            }
        }
        return grid
    }

    /// Zamienia klejnoty na dwóch pozycjach.
    mutating func swap(from: Position, to: Position) {
        let temp = grid[from.row][from.col]
        grid[from.row][from.col] = grid[to.row][to.col]
        grid[to.row][to.col] = temp
    }

    /// Sprawdza, czy pozycja mieści się w granicach planszy.
    func isValid(position: Position) -> Bool {
        position.row >= 0 && position.row < rows &&
        position.col >= 0 && position.col < cols
    }
}

// MARK: - Pozycja na planszy

/// Współrzędne komórki na planszy (wiersz, kolumna).
struct Position: Equatable, Hashable {
    let row: Int
    let col: Int

    /// Sprawdza, czy dwie pozycje sąsiadują (góra, dół, lewo, prawo).
    func isAdjacent(to other: Position) -> Bool {
        let rowDiff = abs(row - other.row)
        let colDiff = abs(col - other.col)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)
    }
}
