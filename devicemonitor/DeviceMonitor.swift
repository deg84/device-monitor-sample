import Foundation
import IOKit
import IOKit.usb

class DeviceMonitor: ObservableObject {
    @Published var connectedDevices: [String] = []
    @Published var disconnectedDevices: [String] = []
    
    private var addedDevices: Set<String> = []
    private var removedDevices: Set<String> = []
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // USBデバイスの監視開始
        let notifyPort = IONotificationPortCreate(kIOMasterPortDefault)
        let notifySource = IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), notifySource, CFRunLoopMode.defaultMode)
        
        let matching = IOServiceMatching(kIOUSBDeviceClassName)
        
        var addedIterator: io_iterator_t = 0
        let addedResult = IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matching, deviceAddedCallback, Unmanaged.passUnretained(self).toOpaque(), &addedIterator)
        if addedResult == KERN_SUCCESS {
            deviceAddedCallback(Unmanaged.passUnretained(self).toOpaque(), addedIterator)
        }
        
        var removedIterator: io_iterator_t = 0
        let removedResult = IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matching, deviceRemovedCallback, Unmanaged.passUnretained(self).toOpaque(), &removedIterator)
        if removedResult == KERN_SUCCESS {
            deviceRemovedCallback(Unmanaged.passUnretained(self).toOpaque(), removedIterator)
        }
    }

    
    func deviceAdded(_ service: io_object_t) {
        let deviceName = getDeviceName(service)
        
        if let name = deviceName {
            addedDevices.insert(name)
            connectedDevices.append(name)
        }
    }
    
    func deviceRemoved(_ service: io_object_t) {
        let deviceName = getDeviceName(service)
        
        if let name = deviceName {
            removedDevices.insert(name)
            disconnectedDevices.append(name)
        }
    }
    
    private func getDeviceName(_ service: io_object_t) -> String? {
        let key = "USB Product Name" as CFString
        guard let property = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0) else {
            return nil
        }
        
        defer {
            property.release()
        }
        
        if let name = property.takeUnretainedValue() as? String {
            return name
        }
        
        return nil
    }
}

func deviceAddedCallback(_ refCon: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
    let monitor = Unmanaged<DeviceMonitor>.fromOpaque(refCon!).takeUnretainedValue()
    while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
        monitor.deviceAdded(service)
        IOObjectRelease(service)
    }
}

func deviceRemovedCallback(_ refCon: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
    let monitor = Unmanaged<DeviceMonitor>.fromOpaque(refCon!).takeUnretainedValue()
    while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
        monitor.deviceRemoved(service)
        IOObjectRelease(service)
    }
}
