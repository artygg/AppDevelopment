//
//  LeaderboardView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import SwiftUI

private let medalColorsLight: [Int: Color] = [
    1: Color(red: 0.98, green: 0.83, blue: 0.26),
    2: Color(red: 0.83, green: 0.83, blue: 0.83),
    3: Color(red: 0.82, green: 0.55, blue: 0.28)
]

private let medalColorsDark: [Int: Color] = [
    1: Color(red: 1.00, green: 0.93, blue: 0.35),
    2: Color(red: 0.90, green: 0.90, blue: 0.95),
    3: Color(red: 1.00, green: 0.72, blue: 0.35)
]

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm = LeaderboardViewModel()
    
    @AppStorage("username") private var currentUser = ""
    
    private var medalColors: [Int: Color] { colorScheme == .dark ? medalColorsDark : medalColorsLight }
    
    private var gradientColors: [Color] {
        colorScheme == .dark ? [.black, .indigo.opacity(0.7)]
                             : [.white, .blue.opacity(0.3)]
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Text("🏆 Leaderboard")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .minimumScaleFactor(0.5)
                
                Text("Top Capturers of this World")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.85)
                                                          : .black.opacity(0.6))
                
                list
                    .frame(maxWidth: 460)
            }
            .padding(.top, 20)
            .task { await vm.fetch(limit: 10) }
        }
        .overlay(
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 1, y: 1)
            )
            .padding(.top, 8)
            .padding(.leading, 12),
            alignment: .topLeading
        )
    }
    
    // MARK: - list
    private var list: some View {
        VStack(spacing: 4) {
            ForEach(vm.rows.prefix(10)) { row in
                RowItem(
                    rank: row.rank,
                    user: row.user,
                    captured: row.captured,
                    isCurrent: row.user == currentUser,
                    medalColors: medalColors,
                    colorScheme: colorScheme
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - row (keeps compiler happy)
private struct RowItem: View {
    let rank: Int
    let user: String
    let captured: Int
    let isCurrent: Bool
    let medalColors: [Int: Color]
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 20) {
            badge
            Text(user)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(isCurrent ? .yellow :
                                 (colorScheme == .dark ? .white : .black))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Text("\(captured)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(isCurrent ? .yellow :
                                 (colorScheme == .dark ? .white : .black))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrent ? Color.yellow.opacity(0.15) :
                      (colorScheme == .dark ? Color.white.opacity(0.08)
                                            : Color.black.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrent ? Color.yellow.opacity(0.6) :
                                (colorScheme == .dark ? Color.white.opacity(0.18)
                                                      : Color.black.opacity(0.12)),
                                lineWidth: 1)
                )
                .shadow(color: medalColors[rank, default: .clear].opacity(0.6),
                        radius: rank <= 3 ? 8 : 0, y: 4)
        )
    }
    
    private var badge: some View {
        let fill = isCurrent
        ? Color.yellow
        : medalColors[rank] ??
          (colorScheme == .dark ? Color.white.opacity(0.3)
                                : Color.black.opacity(0.15))
        
        return Text("#\(rank)")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(rank <= 3 || isCurrent ? .black :
                             (colorScheme == .dark ? .white : .black))
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(fill, in: Capsule())
    }
}
