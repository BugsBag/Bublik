import SwiftUI
import Cocoa

/// `KeyEventHandling` is a bridge between SwiftUI and AppKit's event system.
/// It creates an invisible `NSView` that allows the application to capture keyboard events
/// locally when the user is in "recording" mode for a new hotkey.
///
/// We use `NSViewRepresentable` because SwiftUI's native keyboard handling is limited
/// and doesn't easily support capturing global modifier-only combinations or raw key codes.
struct KeyEventHandling: NSViewRepresentable {
  /// Whether the view is currently capturing keyboard input.
  @Binding var isRecording: Bool
  
  /// The final key code and modifiers that will be saved to persistent storage.
  @Binding var keyCode: Int
  @Binding var modifiers: Int
  
  /// Temporary storage for the key code and modifiers while the user is still holding keys.
  @Binding var tempCode: Int
  @Binding var tempMods: Int
  
  /// The `Coordinator` acts as the delegate and state manager for the `NSView`.
  /// It manages the lifecycle of `NSEvent` monitors to prevent memory leaks.
  class Coordinator: NSObject {
    var parent: KeyEventHandling
    
    /// References to the local event monitors. 
    /// These MUST be removed when recording stops to avoid multiple active listeners and performance degradation.
    var eventMonitors: [Any?] = []
    
    init(_ parent: KeyEventHandling) {
      self.parent = parent
    }
    
    /// Sets up local monitors for KeyDown, KeyUp, and FlagsChanged (modifiers) events.
    func startMonitoring() {
      // Clean up any existing monitors before starting new ones to ensure idempotency.
      stopMonitoring()
      
      // Monitor for KeyDown and FlagsChanged (e.g., pressing Cmd, Shift, etc.)
      let keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
        guard let self = self, self.parent.isRecording else { return event }
        
        // Extract only relevant modifier flags (Cmd, Opt, Shift, Ctrl)
        let currentMods = event.modifierFlags.intersection([.command, .option, .shift, .control])
        let currentModsRaw = Int(currentMods.rawValue)
        
        if event.type == .keyDown {
          // A regular key was pressed (possibly with modifiers).
          // We capture the state and keep waiting for the user to release the keys.
          self.parent.tempCode = Int(event.keyCode)
          self.parent.tempMods = currentModsRaw
        }
        else if event.type == .flagsChanged {
          // Only modifier keys were toggled.
          if currentModsRaw > self.parent.tempMods {
            // User pressed an additional modifier.
            self.parent.tempMods = currentModsRaw
            self.parent.tempCode = -1 // Indicates that no regular key is part of this combo yet.
          } else if currentModsRaw < self.parent.tempMods {
            // User released a modifier. This signals the end of a modifier-only shortcut recording.
            self.finalizeRecording()
          }
        }
        
        // Return nil to "swallow" the event, preventing system beeps or unintended actions 
        // in the background UI while recording.
        return nil
      }
      
      // Monitor for KeyUp events of regular keys.
      let keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
        guard let self = self, self.parent.isRecording else { return event }
        // When a regular key is released, the shortcut recording is considered complete.
        self.finalizeRecording()
        return event
      }
      
      eventMonitors = [keyDownMonitor, keyUpMonitor]
    }
    
    /// Removes active `NSEvent` monitors from the system.
    func stopMonitoring() {
      for monitor in eventMonitors {
        if let monitor = monitor {
          NSEvent.removeMonitor(monitor)
        }
      }
      eventMonitors.removeAll()
    }
    
    /// Processes the captured keys and saves them to the parent bindings.
    private func finalizeRecording() {
      // Validate the combination: we don't allow "empty" shortcuts or shortcuts without modifiers.
      if self.parent.tempMods == 0 {
        // Reset if no modifiers were used (to prevent overriding layout switching with a single letter).
        self.parent.keyCode = -1
        self.parent.modifiers = 0
      } else {
        // Successfully captured a valid combination.
        self.parent.keyCode = self.parent.tempCode
        self.parent.modifiers = self.parent.tempMods
      }
      
      // Immediately notify the global KeyboardMonitor that settings have changed.
      KeyboardMonitor.shared.updateConfig()
      
      // UI updates must happen on the main thread.
      DispatchQueue.main.async {
        self.parent.isRecording = false
      }
    }
    
    deinit {
      // Safety net: ensure monitors are removed if the Coordinator is deallocated.
      stopMonitoring()
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  /// Creates the underlying NSView. It doesn't need to render anything.
  func makeNSView(context: Context) -> NSView {
    return NSView()
  }
  
  /// Called by SwiftUI when the state changes.
  /// We use this to toggle the event monitors based on the `isRecording` binding.
  func updateNSView(_ nsView: NSView, context: Context) {
    if isRecording {
      context.coordinator.startMonitoring()
    } else {
      context.coordinator.stopMonitoring()
    }
  }
  
  /// Called by SwiftUI when the view is removed from the hierarchy.
  /// Crucial for preventing memory leaks by ensuring monitors are stopped.
  static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
    coordinator.stopMonitoring()
  }
}
