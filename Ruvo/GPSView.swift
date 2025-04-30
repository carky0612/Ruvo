import SwiftUI
import MapKit

struct GPSView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()

    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    @State private var isMapFullScreen = false

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.9, blue: 0.95).ignoresSafeArea()

            if isMapFullScreen {
                // Fullscreen Map View
                Map(position: $region) {
                    UserAnnotation()
                }
                .edgesIgnoringSafeArea(.all)
                .mapControls {
                    MapUserLocationButton()
                }
                .onTapGesture {
                    withAnimation {
                        isMapFullScreen = false
                    }
                }

                // Optional close button overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isMapFullScreen = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            } else {
                // Normal View with UI
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.4))
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    Text("Your Location")
                        .font(.title)
                        .foregroundColor(.black)

                    if let location = locationManager.location {
                        Map(position: $region) {
                            UserAnnotation()
                        }
                        .frame(height: 300)
                        .cornerRadius(15)
                        .mapControls {
                            MapUserLocationButton()
                        }
                        .onTapGesture {
                            withAnimation {
                                isMapFullScreen = true
                            }
                        }
                        .onAppear {
                            region = MapCameraPosition.region(
                                MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            )
                        }
                    } else {
                        switch locationManager.authorizationStatus {
                        case .notDetermined:
                            Text("Requesting location permission...")
                        case .denied:
                            Text("Location permission denied.")
                                .foregroundColor(.red)
                        case .restricted:
                            Text("Location access is restricted.")
                                .foregroundColor(.red)
                        default:
                            Text("Fetching location...")
                        }
                    }
                }
                .padding()
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
            }
        }
    }
}
