import Cocoa
import Carbon

private func globalHotKeyHandler(nextHandler: EventHandlerCallRef?, theEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(theEvent,
                                   EventParamName(kEventParamDirectObject),
                                   EventParamType(typeEventHotKeyID),
                                   nil,
                                   MemoryLayout<EventHotKeyID>.size,
                                   nil,
                                   &hotKeyID)
    if status == noErr {
        HotKeyManager.shared.dispatch(id: hotKeyID.id)
    }
    return noErr
}

public final class HotKeyManager {
    public static let shared = HotKeyManager()
    
    private let signature: OSType = 0x4D4B5953 // 'MKYS'
    private var eventHandler: EventHandlerRef?
    
    // Primary media hotkey refs
    private var refF16: EventHotKeyRef?
    private var refF17: EventHotKeyRef?
    private var refF18: EventHotKeyRef?
    
    // Fallback combo refs
    private var refComboSpace: EventHotKeyRef?
    private var refComboLeft: EventHotKeyRef?
    private var refComboRight: EventHotKeyRef?
    
    public private(set) var isRegistered: Bool = false
    public private(set) var fallbacksEnabled: Bool = true
    
    private init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), globalHotKeyHandler, 1, &eventType, nil, &eventHandler)
    }
    
    public func registerAll() {
        guard !isRegistered else { return }
        
        // Register F16 (Previous), F17 (Play/Pause), F18 (Next)
        RegisterEventHotKey(106, 0, EventHotKeyID(signature: signature, id: 16), GetEventDispatcherTarget(), 0, &refF16)
        RegisterEventHotKey(64,  0, EventHotKeyID(signature: signature, id: 17), GetEventDispatcherTarget(), 0, &refF17)
        RegisterEventHotKey(79,  0, EventHotKeyID(signature: signature, id: 18), GetEventDispatcherTarget(), 0, &refF18)
        
        if fallbacksEnabled {
            registerFallbacks()
        }
        
        isRegistered = true
        MediaRemoteBridge.shared.log("Media hotkeys registered")
    }
    
    public func unregisterAll() {
        guard isRegistered else { return }
        
        if let r = refF16 { UnregisterEventHotKey(r); refF16 = nil }
        if let r = refF17 { UnregisterEventHotKey(r); refF17 = nil }
        if let r = refF18 { UnregisterEventHotKey(r); refF18 = nil }
        
        unregisterFallbacks()
        
        isRegistered = false
        MediaRemoteBridge.shared.log("Media hotkeys unregistered")
    }
    
    public func setFallbacks(enabled: Bool) {
        fallbacksEnabled = enabled
        if isRegistered {
            if enabled {
                registerFallbacks()
            } else {
                unregisterFallbacks()
            }
        }
    }
    
    private func registerFallbacks() {
        let ctrlOption = UInt32(controlKey | optionKey)
        if refComboSpace == nil {
            RegisterEventHotKey(49, ctrlOption, EventHotKeyID(signature: signature, id: 88), GetEventDispatcherTarget(), 0, &refComboSpace)
        }
        if refComboLeft == nil {
            RegisterEventHotKey(123, ctrlOption, EventHotKeyID(signature: signature, id: 87), GetEventDispatcherTarget(), 0, &refComboLeft)
        }
        if refComboRight == nil {
            RegisterEventHotKey(124, ctrlOption, EventHotKeyID(signature: signature, id: 89), GetEventDispatcherTarget(), 0, &refComboRight)
        }
    }
    
    private func unregisterFallbacks() {
        if let r = refComboSpace { UnregisterEventHotKey(r); refComboSpace = nil }
        if let r = refComboLeft  { UnregisterEventHotKey(r); refComboLeft = nil }
        if let r = refComboRight { UnregisterEventHotKey(r); refComboRight = nil }
    }
    
    public func dispatch(id: UInt32) {
        switch id {
        case 16:
            MediaRemoteBridge.shared.previousTrack(source: "F7 (Media Previous)")
        case 17:
            MediaRemoteBridge.shared.playPause(source: "F8 (Media Play/Pause)")
        case 18:
            MediaRemoteBridge.shared.nextTrack(source: "F9 (Media Next)")
        case 87:
            MediaRemoteBridge.shared.previousTrack(source: "Ctrl+Opt+Left")
        case 88:
            MediaRemoteBridge.shared.playPause(source: "Ctrl+Opt+Space")
        case 89:
            MediaRemoteBridge.shared.nextTrack(source: "Ctrl+Opt+Right")
        default:
            break
        }
    }
}
