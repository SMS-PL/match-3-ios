//
//  BoardView.swift
//  match-3-ios
//
//  Created by Michał on 29/03/2026.
//

import SwiftUI

// MARK: - Widok planszy

/// Wyświetla siatkę 6×4 klejnotów z obsługą gestu przeciągania (drag/swipe).
struct BoardView: View {
    /// ViewModel gry — źródło danych i logiki.
    @Bindable var viewModel: GameViewModel

    /// Minimalna odległość przesunięcia palca do rozpoznania swipe.
    private let swipeThreshold: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 6
            let hSpacing = spacing * CGFloat(viewModel.boardCols - 1)
            let vSpacing = spacing * CGFloat(viewModel.boardRows - 1)
            let cellSize = min(
                (geometry.size.width - hSpacing) / CGFloat(viewModel.boardCols),
                (geometry.size.height - vSpacing) / CGFloat(viewModel.boardRows)
            )
            let totalWidth = cellSize * CGFloat(viewModel.boardCols) + hSpacing
            let totalHeight = cellSize * CGFloat(viewModel.boardRows) + vSpacing

            VStack(spacing: spacing) {
                ForEach(0..<viewModel.boardRows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<viewModel.boardCols, id: \.self) { col in
                            let position = Position(row: row, col: col)
                            let gem = viewModel.board.grid[row][col]
                            let isSelected = viewModel.selectedPosition == position

                            GemView(
                                gem: gem,
                                imageName: viewModel.imageName(for: gem),
                                isSelected: isSelected
                            )
                                .frame(width: cellSize, height: cellSize)
                                .contentShape(Rectangle())
                                // Gest swipe — główny gest gry
                                .gesture(
                                    DragGesture(minimumDistance: swipeThreshold)
                                        .onEnded { value in
                                            let dir = swipeDirection(from: value.translation)
                                            viewModel.handleSwipe(from: position, direction: dir)
                                        }
                                )
                                .onTapGesture {
                                    viewModel.selectGem(at: position)
                                }
                        }
                    }
                }
            }
            .frame(width: totalWidth, height: totalHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(
            CGFloat(viewModel.boardCols) / CGFloat(viewModel.boardRows),
            contentMode: .fit
        )
    }

    /// Wyznacza kierunek swipe na podstawie przesunięcia.
    private func swipeDirection(from translation: CGSize) -> SwipeDirection {
        if abs(translation.width) > abs(translation.height) {
            return translation.width > 0 ? .right : .left
        } else {
            return translation.height > 0 ? .down : .up
        }
    }
}

#Preview {
    BoardView(viewModel: GameViewModel())
        .padding()
}
