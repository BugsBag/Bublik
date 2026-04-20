import Cocoa

enum AppUtils {
    /// Terminates the current instance and launches a new one.
  static func relaunch() {
    let conf = NSWorkspace.OpenConfiguration()
    conf.createsNewApplicationInstance = true
    
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: conf) { _, error in
      if let error = error {
          // TODO: Do something?
        print("Error relaunching app: \(error.localizedDescription)")
        return
      }
      
        // Ensure we terminate the old instance on the main thread
      DispatchQueue.main.async {
        NSApp.terminate(nil)
      }
    }
  }
}
