import SwiftUI

struct DeviceSelectionView: View {
    @ObservedObject var bluetooth: BluetoothView
    @Binding var isConnected: Bool
    @State private var searchText: String = ""
    
    // Filter devices based on search text.
    var filteredDevices: [String] {
        if searchText.isEmpty {
            return bluetooth.peripheralNames
        } else {
            return bluetooth.peripheralNames.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    List(filteredDevices, id: \.self) { peripheralName in
                        Button(action: {
                            bluetooth.connectToPeripheral(named: peripheralName)
                        }) {
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                Text(peripheralName)
                                    .foregroundColor(.primary)
                                Spacer()
                                // Check if the current peripheral is connected
                                if bluetooth.connectedPeripheralName == peripheralName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle("Select a Device")
                    .searchable(text: $searchText, prompt: "Search Devices")
                    
                    Button(action: {
                        // Set variables here for preview mode.
                        isConnected = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text("Preview Mode")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: geometry.size.height * 0.2)
                }
            }
        }
    }
}

struct DeviceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide dummy data for preview.
        DeviceSelectionView(bluetooth: BluetoothView(), isConnected: .constant(false))
    }
}
