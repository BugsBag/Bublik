import SwiftUI
import ServiceManagement

struct SettingsView: View {
  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem {
          Label("System", systemImage: "gearshape")
        }
      HotkeySettingsView()
        .tabItem {
          Label("Keys", systemImage: "keyboard")
        }
      AboutView()
        .tabItem {
          Label("About", systemImage: "info.circle")
        }
      }
    .frame(width: 550, height: 250)
    .padding()
  }
}

#Preview {
    SettingsView()
}
