import SwiftUI
import UserNotifications

struct DeviceInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let date: Date
    
    static func == (lhs: DeviceInfo, rhs: DeviceInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct ContentView: View {
    @StateObject private var monitor = DeviceMonitor()
    @State private var showConnectedDevices = false
    
    var body: some View {
        VStack {
            Toggle("接続時も通知", isOn: $showConnectedDevices)
            
            List {
                connectedDevicesSection
                disconnectedDevicesSection
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .onChange(of: monitor.connectedDevices) { newValue in
            if showConnectedDevices {
                NotificationManager.shared.showNotification(title: "デバイス接続", body: newValue.last?.name ?? "")
            }
        }
        .onChange(of: monitor.disconnectedDevices) { newValue in
            NotificationManager.shared.showNotification(title: "デバイス切断", body: newValue.last?.name ?? "")
        }
    }
    
    private var connectedDevicesSection: some View {
        Section(header: Text("接続されたデバイス")) {
            ForEach(monitor.connectedDevices) { device in
                deviceRow(device)
            }
        }
    }
    
    private var disconnectedDevicesSection: some View {
        Section(header: Text("切断されたデバイス")) {
            ForEach(monitor.disconnectedDevices) { device in
                deviceRow(device)
            }
        }
    }
    
    private func deviceRow(_ device: DeviceInfo) -> some View {
        HStack {
            Text(device.name)
            Spacer()
            Text(formattedDate(device.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
