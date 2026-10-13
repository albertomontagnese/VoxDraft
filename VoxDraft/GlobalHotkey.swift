import Carbon
import Foundation

final class GlobalHotkey {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private(set) var isRegistered = false
    var onPress: (() -> Void)?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<GlobalHotkey>.fromOpaque(context).takeUnretainedValue()
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.id == 1 else { return OSStatus(eventNotHandledErr) }
            DispatchQueue.main.async { owner.onPress?() }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let keyID = EventHotKeyID(signature: OSType(0x56584446), id: 1) // VXDF
        // Control + Option + D
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_D), UInt32(controlKey | optionKey), keyID, GetApplicationEventTarget(), 0, &hotKey)
        isRegistered = result == noErr
        if !isRegistered { NSLog("VoxDraft could not register ⌃⌥D (error %d)", result) }
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
