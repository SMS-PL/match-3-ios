//
//  GameView.swift
//  match-3-ios
//
//  Created by Michał on 29/03/2026.
//

import SwiftUI

// MARK: - Główny widok gry

/// Ekran rozgrywki match-3.
struct GameView: View {
    /// ViewModel zarządzający logiką gry.
    @State private var viewModel = GameViewModel()

    var body: some View {
        VStack(spacing: 16) {
            // MARK: Górny pasek — shuffle i nowa gra
            HStack(spacing: 12) {
                // Przycisk przetasowania
                Button {
                    withAnimation {
                        viewModel.shuffle()
                    }
                } label: {
                    Label("Shuffle (\(viewModel.shufflesRemaining))", systemImage: "shuffle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.shufflesRemaining <= 0 || viewModel.gameState != .playing)

                Spacer()

                // Przycisk nowej gry
                Button {
                    withAnimation {
                        viewModel.newGame()
                    }
                } label: {
                    Label("Nowa gra", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)

            // MARK: Wynik i ruchy
            HStack(spacing: 32) {
                VStack(spacing: 2) {
                    Text("Wynik")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.score)")
                        .font(.title2.bold())
                }

                VStack(spacing: 2) {
                    Text("Ruchy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.movesRemaining)")
                        .font(.title2.bold())
                        .foregroundStyle(viewModel.movesRemaining <= 3 ? .red : .primary)
                }
            }

            // MARK: Komunikat statusu
            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 20)

            // MARK: Plansza gry
            BoardView(viewModel: viewModel)
                .padding(.horizontal, 12)

            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
        // MARK: Overlay końca gry
        .overlay {
            if viewModel.gameState == .gameOver {
                gameOverOverlay
            }
        }
    }

    // MARK: - Overlay końca gry

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Koniec gry!")
                    .font(.title.bold())

                Text("\(viewModel.score) pkt")
                    .font(.largeTitle.bold())

                Button {
                    withAnimation {
                        viewModel.newGame()
                    }
                } label: {
                    Text("Zagraj ponownie")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    GameView()
}
