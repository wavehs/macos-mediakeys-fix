import Cocoa
import Carbon

typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, CFDictionary?) -> Bool

var sendMRCommand: MRMediaRemoteSendCommandFunction? = {
    guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
        return nil
    }
    guard let sym = dlsym(handle, "MRMediaRemoteSendCommand") else {
        return nil
    }
    return unsafeBitCast(sym, to: MRMediaRemoteSendCommandFunction.self)
}()

var lastActionTimes: [UInt32: Date] = [:]

func handleMediaAction(commandID: UInt32, source: String) {
    let now = Date()
    let debounceInterval: TimeInterval = (commandID == 2) ? 0.20 : 0.15
    if let lastTime = lastActionTimes[commandID], now.timeIntervalSince(lastTime) < debounceInterval {
        return
    }
    lastActionTimes[commandID] = now
    
    let res = sendMRCommand?(commandID, nil) ?? false
    let logMsg = "[\(Date())] Executed \(commandID) from \(source) -> \(res)\n"
    if let data = logMsg.data(using: .utf8) {
        if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/tmp/mediakeyd.log")) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        }
    }
}

// MediaRemote command codes:
// 2 = Play/Pause
// 4 = Next Track
// 5 = Previous Track

func hotKeyHandler(nextHandler: EventHandlerCallRef?, theEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(theEvent,
                                   EventParamName(kEventParamDirectObject),
                                   EventParamType(typeEventHotKeyID),
                                   nil,
                                   MemoryLayout<EventHotKeyID>.size,
                                   nil,
                                   &hotKeyID)
    if status == noErr {
        switch hotKeyID.id {
        case 16:
            handleMediaAction(commandID: 5, source: "F7 (Media Previous)")
        case 17:
            handleMediaAction(commandID: 2, source: "F8 (Media Play/Pause)")
        case 18:
            handleMediaAction(commandID: 4, source: "F9 (Media Next)")
        case 88:
            handleMediaAction(commandID: 2, source: "Ctrl+Opt+Space")
        case 87:
            handleMediaAction(commandID: 5, source: "Ctrl+Opt+Left")
        case 89:
            handleMediaAction(commandID: 4, source: "Ctrl+Opt+Right")
        default:
            break
        }
    }
    return noErr
}

var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetEventDispatcherTarget(), hotKeyHandler, 1, &eventType, nil, nil)

let sig: OSType = 0x4D4B5953 // 'MKYS'

// Virtual keycodes (remapped from Consumer media keys):
// kVK_F16 = 106 (Mapped from Consumer Previous)
// kVK_F17 = 64  (Mapped from Consumer Play/Pause)
// kVK_F18 = 79  (Mapped from Consumer Next)
var refF16: EventHotKeyRef?
var refF17: EventHotKeyRef?
var refF18: EventHotKeyRef?
RegisterEventHotKey(106, 0, EventHotKeyID(signature: sig, id: 16), GetEventDispatcherTarget(), 0, &refF16)
RegisterEventHotKey(64,  0, EventHotKeyID(signature: sig, id: 17), GetEventDispatcherTarget(), 0, &refF17)
RegisterEventHotKey(79,  0, EventHotKeyID(signature: sig, id: 18), GetEventDispatcherTarget(), 0, &refF18)

// Fallback combinations (Ctrl + Option)
let ctrlOption = UInt32(controlKey | optionKey)
var refComboSpace: EventHotKeyRef?
var refComboLeft: EventHotKeyRef?
var refComboRight: EventHotKeyRef?
RegisterEventHotKey(49, ctrlOption, EventHotKeyID(signature: sig, id: 88), GetEventDispatcherTarget(), 0, &refComboSpace)
RegisterEventHotKey(123, ctrlOption, EventHotKeyID(signature: sig, id: 87), GetEventDispatcherTarget(), 0, &refComboLeft)
RegisterEventHotKey(124, ctrlOption, EventHotKeyID(signature: sig, id: 89), GetEventDispatcherTarget(), 0, &refComboRight)

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
