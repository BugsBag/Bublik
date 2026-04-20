import Cocoa
import ApplicationServices

struct AccessibilityManager {
    /// Get the Accessibility permissions status
  static func isTrusted() -> Bool {
    return AXIsProcessTrusted()
  }
  
    /// Opens System Settings for Accessibility
  static func openSystemSettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
  }
}
