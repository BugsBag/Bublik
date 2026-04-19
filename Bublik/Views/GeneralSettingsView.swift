import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
  @AppStorage("launchAtLogin") private var launchAtLogin = false
  // get first element from array or awalable languages
  @AppStorage("selectedLanguage") private var selectedLanguage: String = {
    let current = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first
    return current ?? "en"
  }()
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
        // Autostart section
      settingRow(
        title: String(localized: "Launch at Login"),
        description: String(localized: "This allows the app to start working immediately after your will Log in to your profile.")) {
          Toggle(isOn: $launchAtLogin) {
              // skip adding the title to the localization
            Text(verbatim: "")
          }
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
            .onChange(of: launchAtLogin) { _, newValue in
              toggleAutoStart(enabled: newValue)
            }
        }
      
      Divider().padding(.vertical, 8)
      
        // Lanuage select section
      settingRow(
        title: String(localized: "Language"),
        description: String(localized: "Changing the language will have consequences after restarting the application.")) {
          Picker(selection: $selectedLanguage) {
            Text("English").tag("en")
            Text("Russian").tag("ru")
          } label: {
              // skip adding the title to the localization
            Text(verbatim: "")
          }
          .labelsHidden()
          .fixedSize()
          .onChange(of: selectedLanguage) { _, newValue in
            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
          }
        }
      
      Divider().padding(.vertical, 8)
      
        // Restart app section
      settingRow(
        title: String(localized: "Restart application"),
        description: String(localized: "All changes will be saved.")) {
          Button(action: relaunchApp) {
            Label("Restart application", systemImage: "arrow.clockwise")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
        }
    }
    .padding()
  }
  
  /// Helper view for build compact row
  @ViewBuilder
  private func settingRow<Content: View>(title: String, description: String, @ViewBuilder content: () -> Content) -> some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
        Text(description)
          .font(.system(size: 11))
          .foregroundColor(.secondary)
      }
      Spacer()
      content()
    }
  }
  
  func toggleAutoStart(enabled: Bool) {
    let service = SMAppService.mainApp
    do {
      if enabled {
        try service.register()
      } else {
        try service.unregister()
      }
    } catch {
        // TODO - show error to user?
      print("Autostart configuration error: \(error)")
    }
  }
  
  func relaunchApp() {
    let conf = NSWorkspace.OpenConfiguration()
    conf.createsNewApplicationInstance = true
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: conf) { _, error in
      if let error = error {
        print("Restarting app error: \(error.localizedDescription)")
        return
      }
        // kill old process
      DispatchQueue.main.async {
        NSApp.terminate(nil)
      }
    }
  }
}

#Preview {
    GeneralSettingsView()
}
