import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon:  String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Captured place cell
struct PlaceCard: View {
    let place: Place

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: place.placeIcon)
                    .font(.title3)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // ── FIX: build the coordinate string with String(format:) ──
                Text(
                    "Lat: \(String(format: "%.4f", place.coordinate.latitude)), " +
                    "Lon: \(String(format: "%.4f", place.coordinate.longitude))"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Empty-state placeholder
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 4) {
                Text("No Places Captured Yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Start exploring to capture your first place")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 180)
        .padding(.horizontal, 32)
    }
}
