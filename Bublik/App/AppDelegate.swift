import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var statusItem: NSStatusItem?
  var settingsWindow: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
      // check accessibility permissions
    if !AccessibilityManager.checkAccessibility() {
      // TODO show instruction window explaining why access is needed
      // but actually the system will prompt itself as it is implemented inside checkAccessibility
    }
    
      // Register settings defaults
    UserDefaults.standard.register(defaults: [
      "hotkeyCode": -1, // nothing set
      "hotkeyModifiers": 0,
      "launchAtLogin": false
    ])
    
    // Create menu bar icon
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem?.button {
        button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Switcher")
    }

    setupMenu()
    LanguageManager.setup()
    KeyboardMonitor.shared.start()
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

  @objc func openSettings() {
    if settingsWindow == nil {
        // Create the settings interface
      let contentView = SettingsView()
      
        // Create window
      settingsWindow = NSWindow(
        contentRect: .zero,
        styleMask: [.titled, .closable, .miniaturizable],
        backing: .buffered, defer: false)

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

  // Null the reference when closing the window to free memory
  func windowWillClose(_ notification: Notification) {
    settingsWindow = nil
  }
}
