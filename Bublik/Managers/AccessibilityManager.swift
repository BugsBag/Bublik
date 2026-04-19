import Cocoa
import ApplicationServices

struct AccessibilityManager {
  static func checkAccessibility() -> Bool {
    // Check if accessibility permissions are granted
    // Extract string from Unmanaged object
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options: [String: Any] = [key: true]

    let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

    return isTrusted
  }
}
