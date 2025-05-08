import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetooth = BluetoothView()
    @State private var showDeviceSelection = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 1.0, green: 0.9, blue: 0.95).ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("RUVO")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.4)) // Dark pink

                    VStack(spacing: 20) {
                        ModernButton(title: "Select Device") {
                            showDeviceSelection = true
                        }

                        NavigationLink(destination: GPSView()) {
                            Text("GPS Page")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
                        }
                        .frame(maxWidth: 260)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showDeviceSelection) {
                DeviceSelectionView(bluetooth: bluetooth, isConnected: .constant(false))
            }
        }
    }
}

// Custom Button Style
struct ModernButton: View {
    var title: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
        }) {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
        }
        .frame(maxWidth: 260)
    }
}
