import Cocoa

@MainActor
enum AppUtils {
  private static var isRelaunching = false
  
    /// Terminates the current instance and launches a new one
  static func relaunch() {
    guard !isRelaunching else { return }
    isRelaunching = true
    
    let conf = NSWorkspace.OpenConfiguration()
    conf.createsNewApplicationInstance = true
    
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: conf) { _, error in
      if let error = error {
          // TODO: Do something?
        print("Error relaunching app: \(error.localizedDescription)")
        DispatchQueue.main.async {
          isRelaunching = false
        }
        return
      }
      
      // Ensure we terminate the old instance on the main thread correctly
      DispatchQueue.main.async {
        NSApp.terminate(nil)
      }
    }
  }
}
