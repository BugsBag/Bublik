import SwiftUI

@main
struct BublikApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}
