import Foundation

extension Bundle {

  var appName: String {
    return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    ?? object(forInfoDictionaryKey: "CFBundleName") as? String
    ?? "Bublik"
  }

  var appVersion: String {
    return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    ?? "0.0.0"
  }
  
  var appBuildNumber: String {
    return object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
  }

  var githubURL: String { "https://github.com/BugsBag/Bublik" }
}
