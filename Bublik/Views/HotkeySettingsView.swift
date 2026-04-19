import SwiftUI

struct HotkeySettingsView: View {
  @AppStorage("hotkeyCode") private var hotkeyCode: Int = -1
  @AppStorage("hotkeyModifiers") private var hotkeyModifiers: Int = 0
  
  @State private var isRecording = false
  @State private var tempCode: Int = -1
  @State private var tempModifiers: Int = 0
  
    // Define active combination in one place
  private var currentCode: Int { isRecording ? tempCode : hotkeyCode }
  private var currentMods: Int { isRecording ? tempModifiers : hotkeyModifiers }
    // Flags for the selected combination type
  private var isOnlyModifiers: Bool { currentCode == -1 && currentMods != 0 }
  private var isComplexCombo: Bool { currentCode != -1 && currentMods != 0 }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 15) {
      Text("Hotkeys for switching:")
        .font(.headline)

      ZStack {
        RoundedRectangle(cornerRadius: 6)
          .stroke(isRecording ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
          .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
        
        HStack {
          if isRecording {
            Text(displayString(code: tempCode, mods: tempModifiers))
              .foregroundColor(.blue)
              .font(.system(size: 13, weight: .bold))
            Spacer()
            Text("Recording...")
              .font(.caption)
              .foregroundColor(.secondary)
          } else if hotkeyCode == -1 && hotkeyModifiers == 0 {
            Text("No hotkey set")
              .foregroundColor(.secondary)
          } else {
            Text(displayString(code: hotkeyCode, mods: hotkeyModifiers))
              .font(.system(size: 13, weight: .bold))
          }
        }
        .padding(.horizontal, 10)
      }
      .frame(height: 36)
      .onTapGesture {
        isRecording = true
        tempCode = -1
        tempModifiers = 0
      }
      
      VStack(alignment: .leading, spacing: 12) {
        Text("Click the field and press the hotkey. Recording will finish when you release the keys.")
          .lineLimit(nil)
        
          // Determine current values for highlighting logic
        let currentCode = isRecording ? tempCode : hotkeyCode
        let currentMods = isRecording ? tempModifiers : hotkeyModifiers
        let isOnlyModifiers = currentCode == -1 && currentMods != 0
        let isComplexCombo = currentCode != -1 && currentMods != 0
        
        hintRow(
          text: String(localized: "When setting a combination that contains only modifier keys, such as Command + Shift, layout switching will be performed upon releasing any key from the combination."),
          isActive: isOnlyModifiers
        )
        hintRow(
          text: String(localized: "When setting a combination that contains a regular key along with modifier keys, such as Command + Shift + A, layout switching will be performed upon pressing the last key in the combination."),
          isActive: isComplexCombo
        )
      }
      .font(.caption)
      .foregroundColor(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .background(KeyEventHandling(
      isRecording: $isRecording,
      keyCode: $hotkeyCode,
      modifiers: $hotkeyModifiers,
      tempCode: $tempCode,
      tempMods: $tempModifiers
    ))
  }
  
  func displayString(code: Int, mods: Int) -> String {
    let nsMods = NSEvent.ModifierFlags(rawValue: UInt(mods))
    let modStr = nsMods.shortcutString
    let keyStr = nameForKeyCode(code)
    
    if modStr.isEmpty && keyStr.isEmpty { return String(localized: "Press keys") }
    
    // If there are both icons and a key — also separate them with 2 spaces
    if !modStr.isEmpty && !keyStr.isEmpty {
      return "\(modStr)  \(keyStr)"
    }
    
    return modStr.isEmpty ? keyStr : modStr
  }
  
  @ViewBuilder
  private func hintRow(text: String, isActive: Bool) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
        .foregroundColor(isActive ? .green : .secondary)
        .font(.system(size: 14))
        .frame(width: 16) // Fix width to prevent text from jumping
      
      Text(text)
        .lineLimit(nil)
        .foregroundColor(isActive ? .green : .secondary)
        .fontWeight(isActive ? .medium : .regular)
    }
  }
}

#Preview {
    HotkeySettingsView()
}
