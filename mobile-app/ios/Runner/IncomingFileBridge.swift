import Flutter
import UIKit

/// A file handed to the app from outside — "Open in Harrier Central" from
/// Files or Mail (a file URL), or the share extension (a custom-scheme URL
/// naming a file it left in the shared app-group container). Either way the
/// file is copied into this app's own temp directory and its path handed to
/// Flutter over `harrier_central/incoming_file`:
///
///   Flutter → native  takePending()     the path of a file that arrived
///                                       before Flutter was ready, or nil
///   native → Flutter  incomingFile(path) a file that arrived while running
///
/// Flutter decides what to do with it (today: the GPX import page). The
/// native side keeps at most one pending path; a second arrival replaces it.
final class IncomingFileBridge {
  static let shared = IncomingFileBridge()

  static let channelName = "harrier_central/incoming_file"
  static let urlScheme = "harriercentral"
  static let appGroup = "group.com.harriercentral.app"
  static let sharedInboxFolder = "ShareInbox"

  private var channel: FlutterMethodChannel?
  private var pendingPath: String?

  func start(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "takePending":
        let path = self.pendingPath
        self.pendingPath = nil
        result(path)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  /// Handles a URL given to the app. Returns true when it was ours.
  @discardableResult
  func handle(url: URL) -> Bool {
    if url.isFileURL {
      return deliver(copyIntoInbox(fileURL: url))
    }
    if url.scheme?.lowercased() == Self.urlScheme {
      // harriercentral://import?file=<name> — left by the share extension in
      // the app-group container. Moved (not copied) so the group does not
      // accumulate files.
      guard url.host?.lowercased() == "import",
            let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?
              .queryItems?.first(where: { $0.name == "file" })?.value,
            let groupURL = FileManager.default.containerURL(
              forSecurityApplicationGroupIdentifier: Self.appGroup)
      else { return true }
      let src = groupURL.appendingPathComponent(Self.sharedInboxFolder).appendingPathComponent(name)
      let dst = inboxURL(for: name)
      try? FileManager.default.removeItem(at: dst)
      if (try? FileManager.default.moveItem(at: src, to: dst)) != nil {
        deliver(dst.path)
      }
      return true
    }
    return false
  }

  /// Anything the share extension left in the app-group inbox that the
  /// URL hand-off never delivered. Called at launch and every time the app
  /// becomes active, so a share followed by opening the app (or switching
  /// back to it) still imports. Oldest first; each is moved out of the
  /// group as it is taken.
  func sweepSharedInbox() {
    guard let groupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: Self.appGroup) else { return }
    let inbox = groupURL.appendingPathComponent(Self.sharedInboxFolder, isDirectory: true)
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: inbox.path), !names.isEmpty else { return }
    func modified(_ name: String) -> Date {
      let attrs = try? FileManager.default.attributesOfItem(atPath: inbox.appendingPathComponent(name).path)
      return (attrs?[.modificationDate] as? Date) ?? Date.distantPast
    }
    let sorted = names.sorted { modified($0) < modified($1) }
    for name in sorted {
      let src = inbox.appendingPathComponent(name)
      let dst = inboxURL(for: name)
      try? FileManager.default.removeItem(at: dst)
      if (try? FileManager.default.moveItem(at: src, to: dst)) != nil {
        deliver(dst.path)
      }
    }
  }

  private func copyIntoInbox(fileURL: URL) -> String? {
    // Files/Mail hand over a security-scoped URL; the copy must happen while
    // access is held, and the app must not keep the original.
    let scoped = fileURL.startAccessingSecurityScopedResource()
    defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
    let dst = inboxURL(for: fileURL.lastPathComponent)
    try? FileManager.default.removeItem(at: dst)
    do {
      try FileManager.default.copyItem(at: fileURL, to: dst)
      return dst.path
    } catch {
      return nil
    }
  }

  private func inboxURL(for name: String) -> URL {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("incoming", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let safe = name.isEmpty ? "shared.gpx" : name
    return dir.appendingPathComponent(safe)
  }

  @discardableResult
  private func deliver(_ path: String?) -> Bool {
    guard let path = path else { return true }
    pendingPath = path
    // If Flutter is up, tell it now; it takes the pending path itself, so a
    // message that lands before the Dart handler is registered is not lost.
    channel?.invokeMethod("incomingFile", arguments: path)
    return true
  }
}
