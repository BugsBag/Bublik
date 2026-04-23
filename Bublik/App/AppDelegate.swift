import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var setupWindow: NSWindow?
  
  func applicationDidFinishLaunching(_ notification: Notification) {
      // Register settings defaults
    UserDefaults.standard.register(defaults: [
      "hotkeyCode": -1, // nothing set
      "hotkeyModifiers": 0,
      "launchAtLogin": false
    ])
    
      // Check accessibility permissions
    if !AccessibilityManager.isTrusted() {
      openAccessibilitySetup()
    } else {
      LanguageManager.setup()
      KeyboardMonitor.shared.start()
      UpdateManager.shared.checkForUpdates(isManual: false)
    }
  }
  
  func applicationDidUpdate(_ notification: Notification) {
      // check if there are visible windows (excluding system/hidden)
    let visibleWindows = NSApp.windows.filter { $0.isVisible && $0.canBecomeKey }
    
      // show or hide icon in Dock
    if !visibleWindows.isEmpty {
      if NSApp.activationPolicy() != .regular {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
      }
    } else if NSApp.activationPolicy() != .accessory {
      NSApp.setActivationPolicy(.accessory)
    }
  }
  
  @objc func openAccessibilitySetup() {
    if setupWindow == nil {
      let contentView = AccessibilitySetupView()
      let hostingView = NSHostingView(rootView: contentView)
      
      setupWindow = NSWindow(
        // Compute the ideal size for the current content
        contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
      )
      
      setupWindow?.contentView = hostingView
      setupWindow?.isReleasedWhenClosed = false
      setupWindow?.delegate = self
      setupWindow?.center()
    }
    
    setupWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  
  func windowWillClose(_ notification: Notification) {
    guard let window = notification.object as? NSWindow else { return }
    
      // If the accessibility setup window is closed without granting permissions, the app terminates.
    if window == setupWindow {
      if !AccessibilityManager.isTrusted() {
        AppUtils.quit()
      }
      setupWindow = nil
    }
  }
}
