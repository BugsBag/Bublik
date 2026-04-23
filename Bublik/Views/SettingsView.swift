import SwiftUI
import ServiceManagement

struct SettingsView: View {
  @State private var selectedTab = 0
  
  private var currentSize: CGSize {
    switch selectedTab {
      case 0: return CGSize(width: 550, height: 300) // General
      case 1: return CGSize(width: 550, height: 300) // Hotkeys
      case 2: return CGSize(width: 450, height: 280) // About
      default: return CGSize(width: 500, height: 300)
    }
  }

  var body: some View {
      // Binding to control the selected tab and trigger animation
    let selectionBinding = Binding<Int>(
      get: { self.selectedTab },
      set: { newValue in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
          self.selectedTab = newValue
        }
      }
    )
    
    TabView(selection: selectionBinding) {
      GeneralSettingsView()
        .tabItem { Label("System", systemImage: "gearshape") }
        .tag(0)
        .navigationTitle(Text(verbatim: ""))

      HotkeySettingsView()
        .tabItem { Label("Keys", systemImage: "keyboard") }
        .tag(1)
        .navigationTitle(Text(verbatim: ""))

      AboutView()
        .tabItem { Label("About", systemImage: "info.circle") }
        .tag(2)
        .navigationTitle(Text(verbatim: ""))
    }
    .padding(32)
    .frame(width: currentSize.width, height: currentSize.height)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
  }
}

#Preview {
  SettingsView()
}
