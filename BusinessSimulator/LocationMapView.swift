import SwiftUI

struct LocationMapView: View {
    let locations: [Location]
    let activeLocationID: LocationID
    let availableLocationIDs: Set<LocationID>
    let onLocationSelected: (Location) -> Void
    let onClose: () -> Void

    @State private var selectedLocationID: LocationID?
    @State private var unavailableLocation: Location?

    private let parchment = Color(red: 0.96, green: 0.82, blue: 0.58)
    private let darkBrown = Color(red: 0.24, green: 0.12, blue: 0.05)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("location_map")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()

                ForEach(locations) { location in
                    locationButton(location)
                        .position(
                            x: geometry.size.width
                                * placement(for: location.id).x,
                            y: geometry.size.height
                                * placement(for: location.id).y
                        )
                }

                mapHeader
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.safeAreaInsets.top + 52
                    )

                closeButton
                    .position(
                        x: geometry.size.width - 32,
                        y: geometry.safeAreaInsets.top + 51
                    )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
        .alert(
            "Location Unavailable",
            isPresented: Binding(
                get: { unavailableLocation != nil },
                set: { isPresented in
                    if !isPresented {
                        unavailableLocation = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let unavailableLocation {
                Text(
                    "\(unavailableLocation.name) is available for "
                        + "\(productName(for: unavailableLocation.id))."
                )
            }
        }
    }

    private var mapHeader: some View {
        Text("LOCATIONS")
            .font(.system(.title2, design: .serif))
            .fontWeight(.black)
            .foregroundStyle(darkBrown)
            .padding(.horizontal, 34)
            .padding(.vertical, 9)
            .background(parchment)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(darkBrown.opacity(0.65), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.red.opacity(0.92))
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(parchment, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close locations map")
    }

    private func locationButton(_ location: Location) -> some View {
        let isCurrent = location.id == activeLocationID
        let isAvailable = availableLocationIDs.contains(location.id)
        let isSelected = location.id == selectedLocationID
        let appearance = markerAppearance(for: location.id)

        return Button {
            guard isAvailable else {
                unavailableLocation = location
                return
            }

            selectedLocationID = location.id
            if !isCurrent {
                onLocationSelected(location)
            }
        } label: {
            VStack(spacing: 1) {
                ZStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(appearance.color)
                        .shadow(
                            color: .black.opacity(0.4),
                            radius: 4,
                            y: 3
                        )

                    Image(systemName: appearance.symbol)
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(.white)
                        .offset(y: -5)
                }

                VStack(spacing: 0) {
                    Text(location.name)
                        .font(.system(.subheadline, design: .serif))
                        .fontWeight(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if isCurrent {
                        Text("Current Location")
                            .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundStyle(darkBrown)
                .frame(width: 132)
                .padding(.vertical, isCurrent ? 5 : 8)
                .background(parchment)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(
                            isSelected ? Color.yellow : darkBrown.opacity(0.5),
                            lineWidth: isSelected ? 3 : 1.5
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            }
        }
        .buttonStyle(.plain)
        .grayscale(isAvailable ? 0 : 1)
        .opacity(isAvailable ? 1 : 0.78)
        .accessibilityLabel(
            isCurrent
                ? "\(location.name), current location"
                : isAvailable
                    ? location.name
                    : "\(location.name), unavailable for this product"
        )
    }

    private func productName(for locationID: LocationID) -> String {
        switch locationID.rawValue {
        case "ballpark":
            return "Hot Dogs"
        case "farmers-market":
            return "Pies"
        case "beach":
            return "Smoothies"
        default:
            return "this product"
        }
    }

    private func placement(for locationID: LocationID) -> CGPoint {
        switch locationID.rawValue {
        case "home":
            return CGPoint(x: 0.25, y: 0.25)
        case "ballpark":
            return CGPoint(x: 0.75, y: 0.39)
        case "farmers-market":
            return CGPoint(x: 0.27, y: 0.58)
        case "beach":
            return CGPoint(x: 0.73, y: 0.74)
        default:
            return CGPoint(x: 0.5, y: 0.5)
        }
    }

    private func markerAppearance(
        for locationID: LocationID
    ) -> (symbol: String, color: Color) {
        switch locationID.rawValue {
        case "home":
            return ("house.fill", .red)
        case "ballpark":
            return ("baseball.fill", .blue)
        case "farmers-market":
            return ("basket.fill", .green)
        case "beach":
            return ("sun.max.fill", .orange)
        default:
            return ("mappin", .gray)
        }
    }
}
