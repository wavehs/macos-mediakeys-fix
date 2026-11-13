import Cocoa

public final class MediaRemoteBridge {
    public static let shared = MediaRemoteBridge()
    
    private typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, CFDictionary?) -> Bool
    private var sendMRCommand: MRMediaRemoteSendCommandFunction?
    
    private var lastActionTimes: [UInt32: Date] = [:]
    private let lock = NSLock()
    
    public let logPath = "/tmp/mediakeyd.log"
    
    private init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) {
            if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
                sendMRCommand = unsafeBitCast(sym, to: MRMediaRemoteSendCommandFunction.self)
            }
        }
    }
    
    // Command IDs:
    // 2: Play/Pause toggle
    // 4: Next Track
    // 5: Previous Track
    
    @discardableResult
    public func sendCommand(id: UInt32, source: String = "Direct") -> Bool {
        let now = Date()
        let debounceInterval: TimeInterval = (id == 2) ? 0.20 : 0.15
        
        lock.lock()
        if let lastTime = lastActionTimes[id], now.timeIntervalSince(lastTime) < debounceInterval {
            lock.unlock()
            return false
        }
        lastActionTimes[id] = now
        lock.unlock()
        
        guard let sendFunc = sendMRCommand else {
            log("Error: MediaRemote framework not loaded")
            return false
        }
        
        let result = sendFunc(id, nil)
        log("Executed command \(id) from \(source) -> \(result)")
        return result
    }
    
    @discardableResult
    public func playPause(source: String = "Play/Pause") -> Bool {
        return sendCommand(id: 2, source: source)
    }
    
    @discardableResult
    public func nextTrack(source: String = "Next") -> Bool {
        return sendCommand(id: 4, source: source)
    }
    
    @discardableResult
    public func previousTrack(source: String = "Previous") -> Bool {
        return sendCommand(id: 5, source: source)
    }
    
    public func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        print(line, terminator: "")
        
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
        }
        if let data = line.data(using: .utf8),
           let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logPath)) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        }
    }
}
