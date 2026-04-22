import SwiftUI

@main
struct BublikApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    MenuBarExtra {
      if AccessibilityManager.isTrusted() {
        SettingsLink {
          Label("Settings", systemImage: "gear")
        }
      } else {
        // If permissions are missing, we display the usual opening
        // instructions to prevent the user from opening the settings
        Button {
          appDelegate.openAccessibilitySetup()
        } label: {
          Label("Settings", systemImage: "gear")
        }
      }
      
      Divider()
      
      Button {
        AppUtils.quit()
      } label: {
        Label("Quit", systemImage: "power")
      }
    } label: {
      Image("MenuBarIcon")
    }
    
    Settings {
      SettingsView()
    }
  }
}
