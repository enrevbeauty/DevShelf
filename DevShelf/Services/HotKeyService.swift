import AppKit
import Carbon.HIToolbox

@MainActor
final class HotKeyService {

    static let shared = HotKeyService()

    private var hotKeyRef: EventHotKeyRef?

    private var eventHandlerRef: EventHandlerRef?

    private var action: (() -> Void)?

    private let signature: OSType = 0x44565348

    private init() {}

    @discardableResult
    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        action: @escaping () -> Void
    ) -> Bool {

        unregister()

        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in

                guard let event else {
                    return OSStatus(eventNotHandledErr)
                }

                var hotKeyID = EventHotKeyID()

                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr,
                      hotKeyID.signature == 0x44565348,
                      hotKeyID.id == 1
                else {
                    return OSStatus(eventNotHandledErr)
                }

                Task { @MainActor in
                    HotKeyService.shared.trigger()
                }

                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            unregister()
            return false
        }

        let hotKeyID = EventHotKeyID(
            signature: signature,
            id: 1
        )

        let registrationStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registrationStatus == noErr else {
            unregister()
            return false
        }

        return true
    }

    func unregister() {

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }

        hotKeyRef = nil
        eventHandlerRef = nil
        action = nil
    }

    private func trigger() {
        action?()
    }
}
