import Cocoa

public final class KeyMappingManager {
    public static let shared = KeyMappingManager()
    
    // Mapping:
    // Consumer Previous (0xC000000B4), Rewind (0xC000000B6) -> Keyboard F16 (0x70000006B)
    // Consumer Play/Pause (0xC000000CD)                     -> Keyboard F17 (0x70000006C)
    // Consumer FastForward (0xC000000B3), Next (0xC000000B5) -> Keyboard F18 (0x70000006D)
    public let mappingJSON = """
    {"UserKeyMapping":[
        {"HIDKeyboardModifierMappingSrc":0xC000000B4,"HIDKeyboardModifierMappingDst":0x70000006B},
        {"HIDKeyboardModifierMappingSrc":0xC000000B6,"HIDKeyboardModifierMappingDst":0x70000006B},
        {"HIDKeyboardModifierMappingSrc":0xC000000CD,"HIDKeyboardModifierMappingDst":0x70000006C},
        {"HIDKeyboardModifierMappingSrc":0xC000000B3,"HIDKeyboardModifierMappingDst":0x70000006D},
        {"HIDKeyboardModifierMappingSrc":0xC000000B5,"HIDKeyboardModifierMappingDst":0x70000006D}
    ]}
    """
    
    private var wakeObserver: NSObjectProtocol?
    public private(set) var isApplied: Bool = false
    
    private init() {
        setupWakeObserver()
    }
    
    deinit {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    private func setupWakeObserver() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.isApplied else { return }
            MediaRemoteBridge.shared.log("System woke from sleep: re-applying key mapping")
            _ = self.applyMapping()
        }
    }
    
    @discardableResult
    public func applyMapping() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        task.arguments = ["property", "--set", mappingJSON]
        
        do {
            try task.run()
            task.waitUntilExit()
            isApplied = (task.terminationStatus == 0)
            if isApplied {
                MediaRemoteBridge.shared.log("Key mapping successfully applied via hidutil")
            } else {
                MediaRemoteBridge.shared.log("Failed to apply key mapping. Exit code: \(task.terminationStatus)")
            }
            return isApplied
        } catch {
            MediaRemoteBridge.shared.log("Error running hidutil: \(error)")
            isApplied = false
            return false
        }
    }
    
    @discardableResult
    public func resetMapping() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        task.arguments = ["property", "--set", "{\"UserKeyMapping\":[]}"]
        
        do {
            try task.run()
            task.waitUntilExit()
            let success = (task.terminationStatus == 0)
            if success {
                isApplied = false
                MediaRemoteBridge.shared.log("Key mapping reset to default")
            }
            return success
        } catch {
            MediaRemoteBridge.shared.log("Error resetting hidutil mapping: \(error)")
            return false
        }
    }
    
    public func checkIsActive() -> Bool {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        task.arguments = ["property", "--get", "UserKeyMapping"]
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            if let output = String(data: data, encoding: .utf8) {
                // Check for destination keycodes 0x70000006C = 30064771180 or 0x6C
                let active = output.contains("30064771180") || output.contains("70000006C") || output.contains("70000006c")
                self.isApplied = active
                return active
            }
        } catch {
            MediaRemoteBridge.shared.log("Error querying UserKeyMapping: \(error)")
        }
        return false
    }
}
