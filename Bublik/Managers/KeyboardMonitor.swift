import Cocoa
import CoreGraphics

class KeyboardMonitor {
  static let shared = KeyboardMonitor()
  
  private var eventTap: CFMachPort?
  
  // Settings cache for performance (to avoid reading UserDefaults in EventTap)
  private var cachedKeyCode: Int = -1
  private var cachedModifiersRaw: Int = 0
  private var cachedTargetCGFlags: CGEventFlags = []
  
  // State variables
  private var isModifierKeyPathActive = false
  private var didPressAnyOtherKeyDuringModifiers = false
  
  private init() {
    updateConfig()
    
    // Listen for defaults changes
    NotificationCenter.default.addObserver(
      forName: UserDefaults.didChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.updateConfig()
    }
  }
  
  /// Updates settings cache from UserDefaults.
  func updateConfig() {
    cachedKeyCode = UserDefaults.standard.object(forKey: "hotkeyCode") as? Int ?? -1
    cachedModifiersRaw = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
    
    // Pre-calculate CGFlags for performance
    var flags: CGEventFlags = []
    let nsFlags = NSEvent.ModifierFlags(rawValue: UInt(cachedModifiersRaw))
    if nsFlags.contains(.command) { flags.insert(.maskCommand) }
    if nsFlags.contains(.option) { flags.insert(.maskAlternate) }
    if nsFlags.contains(.shift) { flags.insert(.maskShift) }
    if nsFlags.contains(.control) { flags.insert(.maskControl) }
    cachedTargetCGFlags = flags
  }
  
  func start() {
    if eventTap != nil { return }

      // Listen for: Key Down, Key Up, and Modifier Changes
    let mask = (1 << CGEventType.keyDown.rawValue) |
               (1 << CGEventType.flagsChanged.rawValue) |
               (1 << CGEventType.keyUp.rawValue)
    
      // Pass nil to userInfo as we will access KeyboardMonitor.shared directly
    eventTap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(mask),
      callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        return KeyboardMonitor.shared.handleEvent(proxy: proxy, type: type, event: event)
      },
      userInfo: nil
    )
    
    if let tap = eventTap {
      let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: tap, enable: true)
    }
  }
  
  private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    // If no hotkey set - just pass through
    if cachedKeyCode == -1 && cachedModifiersRaw == 0 {
      return Unmanaged.passRetained(event)
    }
    
    let currentFlags = event.flags
    let relevantMask: CGEventFlags = [.maskCommand, .maskAlternate, .maskShift, .maskControl]
    let currentCleanFlags = currentFlags.intersection(relevantMask)
    
    // SCENARIO 1: Modifiers only (e.g., Cmd+Shift)
    if cachedKeyCode == -1 {
      if type == .flagsChanged {
        let exactlyTarget = currentCleanFlags == cachedTargetCGFlags
        let containsTarget = currentCleanFlags.contains(cachedTargetCGFlags)
        
        if exactlyTarget {
          self.isModifierKeyPathActive = true
        } else if containsTarget {
            // Pressed more than necessary
            // (for example, Cmd+Shift+Opt when pressing Cmd+Shift).
            // Mark it as "dirty" to skip switching when released.
          self.didPressAnyOtherKeyDuringModifiers = true
        } else if self.isModifierKeyPathActive {
            // If we were in an active state and now the flags don't
            // contain the target — it means something was released.
          if !self.didPressAnyOtherKeyDuringModifiers {
            LanguageManager.toggleLanguage()
          }
            // Reset the state
          self.isModifierKeyPathActive = false
          self.didPressAnyOtherKeyDuringModifiers = false
        }
        
      } else if type == .keyDown && self.isModifierKeyPathActive {
          // A regular key was pressed while we are tracking modifiers - invalidate the switch
        self.didPressAnyOtherKeyDuringModifiers = true
      }

      return Unmanaged.passRetained(event)
    }
    
    // SCENARIO 2: Regular hotkey (e.g., Cmd+Opt+S)
    if type == .keyDown {
      let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
      if keyCode == cachedKeyCode && currentCleanFlags == cachedTargetCGFlags {
          // Check if the press is REPEATED (held key)
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
          // If it is an auto-repeat — just "swallow" the event without switching language
        if isRepeat { return nil }
        
        LanguageManager.toggleLanguage()
        return nil // "Swallow" the press
      }
    }
    
    return Unmanaged.passRetained(event)
  }
}
