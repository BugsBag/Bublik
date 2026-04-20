import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var statusItem: NSStatusItem?
  var settingsWindow: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
      // Register settings defaults
    UserDefaults.standard.register(defaults: [
      "hotkeyCode": -1, // nothing set
      "hotkeyModifiers": 0,
      "launchAtLogin": false
    ])
    
    // Create menu bar icon
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem?.button {
      button.image = NSImage(named: "MenuBarIcon")
    }

    setupMenu()

    // Check accessibility permissions
    if !AccessibilityManager.isTrusted() {
      openAccessibilitySetup()
    } else {
      LanguageManager.setup()
      KeyboardMonitor.shared.start()
    }
  }

  func setupMenu() {
    let menu = NSMenu()
    
    let settingsItem = NSMenuItem(title: String(localized: "Settings"), action: #selector(openSettings), keyEquivalent: "")
    settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
    menu.addItem(settingsItem)
    
    menu.addItem(NSMenuItem.separator())
    
    let quitItem = NSMenuItem(title: String(localized: "Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
    menu.addItem(quitItem)

    statusItem?.menu = menu
  }

  @objc func openAccessibilitySetup() {
    if settingsWindow == nil {
      let contentView = AccessibilitySetupView()
      let hostingView = NSHostingView(rootView: contentView)
      
      settingsWindow = NSWindow(
        // Compute the ideal size for the current content
        contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
        styleMask: [.titled, .closable],
        backing: .buffered, defer: false
      )
      
      settingsWindow?.contentView = hostingView
      settingsWindow?.isReleasedWhenClosed = false
      settingsWindow?.delegate = self
      settingsWindow?.center()
    }

    settingsWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc func openSettings() {
    // If no access - redirect to accessibility setup
    if !AccessibilityManager.isTrusted() {
      openAccessibilitySetup()
      return
    }

    if settingsWindow == nil {
        // Create the settings interface
      let contentView = SettingsView()
      
        // Create window
      settingsWindow = NSWindow(
        contentRect: .zero,
        styleMask: [.titled, .closable, .miniaturizable],
        backing: .buffered, defer: false
      )

      settingsWindow?.contentView = NSHostingView(rootView: contentView)
      settingsWindow?.center()
      settingsWindow?.isReleasedWhenClosed = false // Swift ARC will clear memory when the reference is nulled
      settingsWindow?.delegate = self // Set delegate for nulling the reference
    }

    // Show window
    settingsWindow?.makeKeyAndOrderFront(nil)
    // Bring application to foreground
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) {
      // If the accessibility setup window is closed without granting permissions, the app terminates.
    if !AccessibilityManager.isTrusted() {
      AppUtils.quit()
    }
    settingsWindow = nil
  }
}
