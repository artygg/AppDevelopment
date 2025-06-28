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

// MARK: – Leaderboard
struct LeaderboardView: View {
    @Environment(\.dismiss)           private var dismiss
    @Environment(\.colorScheme)       private var scheme
    @StateObject                      private var vm = LeaderboardViewModel()
    @AppStorage("username")           private var currentUser = ""
    
    @State private var showInfoSheet  = false
    
    private var medalColours: [Int: Color] { scheme == .dark ? medalColorsDark : medalColorsLight }
    private var backgroundGradient:  [Color] {
        scheme == .dark ? [.black, .indigo.opacity(0.7)]
                        : [.white, .blue.opacity(0.3)]
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: backgroundGradient,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                header
                progressBar
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(vm.rows.prefix(50)) { row in
                            RowItem(rank: row.rank,
                                    user: row.user,
                                    captured: row.captured,
                                    isCurrent: row.user == currentUser,
                                    medalColors: medalColours,
                                    colorScheme: scheme)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                }
                .animation(.spring(), value: vm.rows)
            }
            .padding(.top, 20)
            .frame(maxWidth: 520)
            .task { await vm.fetch(limit: 50) }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                closeButton
                Spacer()
                infoButton
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showInfoSheet) { InfoSheet() }
    }
    
    // MARK: header
    private var header: some View {
        VStack(spacing: 8) {
            Text("🏆 Leaderboard")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(scheme == .dark ? .white : .black)
                .minimumScaleFactor(0.5)
            
            Text("Top Capturers of this World")
                .font(.headline.weight(.bold))
                .foregroundStyle(scheme == .dark ? .white.opacity(0.85) : .black.opacity(0.6))
        }
    }
    
    private var progressBar: some View {
        let maxCaptured = vm.rows.map(\.captured).max() ?? 1
        let mine        = vm.rows.first(where: { $0.user == currentUser })
        let progress    = Double(mine?.captured ?? 0) / Double(maxCaptured)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("Your progress")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.15))
                    Capsule()
                        .fill(Color.yellow)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal)
    }
    
    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(Circle().fill(.ultraThinMaterial))
    }
    
    private var infoButton: some View {
        Button { showInfoSheet = true } label: {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(Circle().fill(.ultraThinMaterial))
    }
}

private struct RowItem: View {
    let rank: Int
    let user: String
    let captured: Int
    let isCurrent: Bool
    let medalColors: [Int: Color]
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 18) {
            badge
            VStack(alignment: .leading, spacing: 2) {
                Text(user)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(isCurrent ? .yellow :
                                     (colorScheme == .dark ? .white : .black))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text("captures")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(captured)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(isCurrent ? .yellow :
                                 (colorScheme == .dark ? .white : .black))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isCurrent ? Color.yellow.opacity(0.15)
                                : (colorScheme == .dark ? Color.white.opacity(0.08)
                                                        : Color.black.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isCurrent ? Color.yellow.opacity(0.6)
                                          : (colorScheme == .dark ? Color.white.opacity(0.18)
                                                                  : Color.black.opacity(0.12)),
                                lineWidth: 1)
                )
                .shadow(color: medalColors[rank, default: .clear].opacity(0.6),
                        radius: rank <= 3 ? 8 : 0, y: 4)
        )
    }
    
    private var badge: some View {
        let fill: Color = {
            if rank <= 3 {
                medalColors[rank]!
            } else if isCurrent {
                .yellow
            } else {
                colorScheme == .dark ? Color.white.opacity(0.3)
                                     : Color.black.opacity(0.15)
            }
        }()
        
        return Text("#\(rank)")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(rank <= 3 ? .black :
                             (isCurrent ? .black :
                              (colorScheme == .dark ? .white : .black)))
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(fill, in: Capsule())
    }
}

private struct InfoSheet: View {
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow)
            
            Text("How to climb the leaderboard")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            
            Text("""
                 • Capture places to earn points.
                 • Set traps to defend your rank.
                 • The more you play, the higher you'll appear!

                 Good luck, Capturer! 💪
                 """)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
}
