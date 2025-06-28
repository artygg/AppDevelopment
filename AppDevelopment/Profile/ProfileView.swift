//
//  ProfileView.swift
//  AppDevelopment
//
//  Pure presentation layer — binds to ProfileViewModel for data / actions
//

import SwiftUI

struct ProfileView: View {

    @ObservedObject var placesVM: DecodedPlacesViewModel

    @StateObject private var vm = ProfileViewModel()

    @Environment(\.colorScheme) private var scheme
    private var gradientBG: some View {
        LinearGradient(colors: scheme == .dark
                       ? [.black, .indigo]
                       : [.white, .blue.opacity(0.25)],
                       startPoint: .topLeading,
                       endPoint:   .bottomTrailing)
            .ignoresSafeArea()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    if vm.isLoggedIn {
                        statsSection
                        capturedSection
                        logoutButton
                    } else {
                        loggedOutSection
                    }
                }
                .padding(.vertical, 32)
            }
            .background(gradientBG)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { settingsToolbar }
            .sheet(isPresented: $vm.showSettings)  { SettingsView() }
            .sheet(isPresented: $vm.showAuthSheet){ AuthenticationView() }
            .sheet(isPresented: $vm.showAllPlaces){
                AllCapturedPlacesView(capturedPlaces: vm.capturedPlaces)
            }
            .sheet(isPresented: $vm.ownerQuizSheet){
                if let q = vm.ownerQuiz {
                    OwnerQuizView(mineCount: $vm.mineCount,
                                  quiz: q) { vm.ownerQuizSheet = false }
                }
            }
            .overlay(loadingOverlay)
            .onAppear { vm.bind(placesVM: placesVM) }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            AvatarView(url: vm.selectedAvatarURL, fallback: vm.username)
                .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text(vm.username.isEmpty ? "Guest" : vm.username)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                if vm.isLoggedIn {
                    Text("Explorer")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(title: "Places Captured",
                     value: "\(vm.capturedPlaces.count)",
                     icon:  "flag.checkered",
                     color: .green)
            StatCard(title: "Mines",
                     value: "\(vm.mineCount)",
                     icon:  "sparkles.rectangle.stack.fill",
                     color: .pink)
        }
        .padding(.horizontal)
    }

    private var capturedSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Captured Places",
                          showAll: !vm.capturedPlaces.isEmpty) {
                vm.showAllPlaces = true
            }

            if vm.capturedPlaces.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.capturedPlaces.prefix(5))) { place in
                        PlaceCard(place: place)
                            .onTapGesture {
                                Task { await vm.loadOwnerQuiz(for: place,
                                                              in: placesVM) }
                            }
                            .transition(.move(edge: .trailing)
                                              .combined(with: .opacity))
                    }
                }
            }
        }
        .padding(.horizontal)
        .animation(.spring(), value: vm.capturedPlaces.count)
    }

    private var logoutButton: some View {
        Button(role: .destructive) { vm.logout() } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Logout")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.12))
            )
        }
        .padding(.horizontal)
    }

    private var loggedOutSection: some View {
        VStack(spacing: 26) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)

            Text("Not Logged In")
                .font(.title2.weight(.bold))

            Text("Log in to view your profile and track your progress.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Log In or Sign Up") { vm.showAuthSheet = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    private func sectionHeader(_ title: String,
                               showAll: Bool = false,
                               action: @escaping () -> Void = {}) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if showAll {
                Button("View All", action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { vm.showSettings = true } label: {
                Image(systemName: "gear")
            }
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if vm.loadingOwnerQuiz {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading Quiz…")
                        .font(.callout.weight(.medium))
                }
                .padding(32)
                .background(Material.ultraThin,
                            in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
            }
            .transition(.opacity)
        }
    }
}

private struct AvatarView: View {
    let url: String
    let fallback: String

    var body: some View {
        ZStack {
            if let remote = URL(string: url), !url.isEmpty {
                AsyncImage(url: remote) { phase in
                    switch phase {
                    case .empty:
                        Circle().fill(Color.gray.opacity(0.25))
                            .overlay(Shimmer())
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Circle().fill(Color.gray.opacity(0.25))
                            .overlay(Image(systemName: "person.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary))
                    }
                }
            } else {
                Circle().fill(Color.accentColor)
                Text(String(fallback.prefix(1)).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 110, height: 110)
        .clipShape(Circle())
        .shadow(radius: 6, y: 4)
    }
}

private struct Shimmer: View {
    @State private var offset: CGFloat = -1
    var body: some View {
        LinearGradient(gradient:
                        Gradient(colors: [.white.opacity(0.3),
                                          .white.opacity(0.8),
                                          .white.opacity(0.3)]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .mask(Color.white)                 
            .rotationEffect(.degrees(70))
            .offset(x: offset * 200)
            .onAppear {
                withAnimation(.linear(duration: 1.4)
                                .repeatForever(autoreverses: false)) {
                    offset = 1
                }
            }
    }
}
