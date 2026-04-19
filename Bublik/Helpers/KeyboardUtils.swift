import Foundation
import Carbon
import Cocoa

// Cache keyboard type once for the entire session
private let cachedKeyboardType = UInt32(LMGetKbdType())
private var cachedASCIISource: TISInputSource?

/// Returns a string representation of the key code based on the current layout
func nameForKeyCode(_ keyCode: Int) -> String {
  if keyCode == -1 { return "" }
  
  // Special keys
  switch keyCode {
    case 49: return "Space"
    case 36: return "↩"
    case 48: return "Tab"
    case 51: return "⌫"
    case 53: return "Esc"
    case 123: return "←"
    case 124: return "→"
    case 125: return "↓"
    case 126: return "↑"
    default:
      // Get or update current ASCII layout cache
      if cachedASCIISource == nil {
          cachedASCIISource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue()
      }
      
      guard let source = cachedASCIISource else {
        return "Key \(keyCode)"
      }
      
      // Extract layout data
      guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
        return "Key \(keyCode)"
      }
      
      let dataPtr = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue()
      let rawData = CFDataGetBytePtr(dataPtr)
      
      let keyLayoutPtr = unsafeBitCast(rawData, to: UnsafePointer<UCKeyboardLayout>.self)
      
      var deadKeyState: UInt32 = 0
      let maxLength = 4
      var actualLength = 0
      var unicodeString = [UniChar](repeating: 0, count: maxLength)
      
      let result = UCKeyTranslate(
        keyLayoutPtr,
        UInt16(keyCode),
        0, // kUCKeyActionDown
        0, // Modifiers
        cachedKeyboardType,
        0, // kUnicodeDeadInputStatus
        &deadKeyState,
        maxLength,
        &actualLength,
        &unicodeString
      )
      
      if result == noErr {
        let key = String(utf16CodeUnits: unicodeString, count: actualLength).uppercased()
        return key.isEmpty ? "Key \(keyCode)" : key
      } else {
        return "Key \(keyCode)"
      }
  }
}
