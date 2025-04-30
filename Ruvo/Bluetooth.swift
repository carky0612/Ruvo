import SwiftUI
import CoreBluetooth

class BluetoothView: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    private var selectedPeripheral: CBPeripheral?
    
    @Published var peripheralNames: [String] = []
    @Published var receivedMessages: [String] = [] // Store received messages
    @Published var isConnected: Bool = false // Track connection status
    @Published var connectedPeripheralName: String? = nil // Name of connected peripheral
    
    private var peripheralMap: [String: CBPeripheral] = [:]
    private var writableCharacteristic: CBCharacteristic? // Store writable characteristic
    private var notifyCharacteristic: CBCharacteristic?   // Store notify characteristic (optional)
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is on")
            self.centralManager?.scanForPeripherals(withServices: nil,
                                                    options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        case .poweredOff:
            print("Bluetooth is powered off")
            resetConnection()
        case .resetting:
            print("Bluetooth is resetting")
            resetConnection()
        case .unauthorized:
            print("Bluetooth is unauthorized")
            resetConnection()
        case .unsupported:
            print("Bluetooth is unsupported on this device")
            resetConnection()
        case .unknown:
            print("Bluetooth state is unknown")
            resetConnection()
        @unknown default:
            print("A new state is available that is not handled")
            resetConnection()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // Use peripheral.name or, if nil, try the advertisement data key.
        let deviceName = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Unknown Device"
        
        // Process every discovered peripheral and print its UUID
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
            peripheralNames.append(deviceName)
            peripheralMap[deviceName] = peripheral // Store the mapping
            print("Discovered peripheral: \(deviceName), uuid: \(peripheral.identifier.uuidString)")
        }
    }
    
    func connectToPeripheral(named peripheralName: String) {
        guard let peripheral = peripheralMap[peripheralName] else {
            print("Peripheral \(peripheralName) not found")
            return
        }
        print("Connecting to peripheral: \(peripheralName)")
        selectedPeripheral = peripheral
        selectedPeripheral?.delegate = self
        centralManager?.stopScan()
        centralManager?.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "a peripheral")")
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedPeripheralName = peripheral.name
        }
        peripheral.discoverServices(nil) // Discover services after connecting
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "a peripheral"):", error?.localizedDescription ?? "No error")
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheralName = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "a peripheral")")
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheralName = nil
        }
        // Optionally, restart scanning
        centralManager?.scanForPeripherals(withServices: nil,
                                           options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    // MARK: - CBPeripheralDelegate Methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            // Check for writable characteristic
            if characteristic.properties.contains(.write) ||
               characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
                sendData("Hello from Mac!") // Example: send data once found
            }
            // Check for notify characteristic
            if characteristic.properties.contains(.notify) {
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("Subscribed to notifications for characteristic: \(characteristic.uuid)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            print("No data received for characteristic \(characteristic.uuid)")
            return
        }
        
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessages.append(message)
                print("Received data: \(message)")
            }
        } else {
            print("Unable to decode received data.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Error writing value to characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }
        print("Successfully wrote value to characteristic \(characteristic.uuid)")
    }
    
    // MARK: - Sending Data
    
    func sendData(_ message: String) {
        guard let selectedPeripheral = selectedPeripheral,
              let writableCharacteristic = writableCharacteristic else {
            print("No connected peripheral or writable characteristic available.")
            return
        }
        if let data = message.data(using: .utf8) {
            selectedPeripheral.writeValue(data,
                                          for: writableCharacteristic,
                                          type: .withResponse)
            print("Sent data: \(message)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetConnection() {
        peripherals.removeAll()
        peripheralNames.removeAll()
        peripheralMap.removeAll()
        selectedPeripheral = nil
        isConnected = false
        connectedPeripheralName = nil
        receivedMessages.removeAll()
    }
}
