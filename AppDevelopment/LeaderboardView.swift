//
//  LeaderboardView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import SwiftUI

private let medalColors: [Int: Color] = [
    1: Color(red: 0.98, green: 0.83, blue: 0.26),
    2: Color(red: 0.83, green: 0.83, blue: 0.83),
    3: Color(red: 0.82, green: 0.55, blue: 0.28)
]

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = LeaderboardViewModel()
    @Namespace private var ns

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo.opacity(0.4), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🏆 Leaderboard")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)

                Text("Top Capturers of this World")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                list
                    .frame(maxWidth: 460)
            }
            .padding(.top, 12)
            .task { await vm.fetch(limit: 10) }
        }
        .overlay(
            Button("Close") { dismiss() }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 6)
                .padding(.leading, 12),
            alignment: .topLeading
        )
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(vm.rows.prefix(10)) { row in
                HStack(spacing: 18) {
                    badge(rank: row.rank)
                    Text(row.user)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Text("\(row.captured)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 22)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: medalColors[row.rank, default: .clear].opacity(0.5),
                                radius: row.rank <= 3 ? 6 : 0, y: 3)
                )
                .padding(.vertical, 3)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func badge(rank: Int) -> some View {
        let fill = medalColors[rank] ?? Color.white.opacity(0.25)
        Text("#\(rank)")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(rank <= 3 ? .black : .white)
            .padding(.vertical, 5)
            .padding(.horizontal, 14)
            .background(fill, in: Capsule())
    }
}
