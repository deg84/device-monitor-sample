import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var monitor = DeviceMonitor()
    @State private var showConnectedDevices = false
    
    var body: some View {
        VStack {
            Toggle("接続時も通知", isOn: $showConnectedDevices)
            
            List {
                Section(header: Text("接続されたデバイス")) {
                    ForEach(monitor.connectedDevices, id: \.self) { device in
                        Text(device)
                    }
                }
                
                Section(header: Text("切断されたデバイス")) {
                    ForEach(monitor.disconnectedDevices, id: \.self) { device in
                        Text(device)
                    }
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .onChange(of: monitor.connectedDevices) { newValue in
            if showConnectedDevices {
                NotificationManager.shared.showNotification(title: "デバイス接続", body: newValue.last ?? "")
            }
        }
        .onChange(of: monitor.disconnectedDevices) { newValue in
            NotificationManager.shared.showNotification(title: "デバイス切断", body: newValue.last ?? "")
        }
    }
}
