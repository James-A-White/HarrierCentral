import UIKit
import UniformTypeIdentifiers

/// The Harrier Central row in the iOS share sheet for a GPX file.
///
/// An extension cannot run the app's code, so it does the least possible:
/// copies the shared file into the app-group container and opens the main
/// app with `harriercentral://import?file=<name>`. The app's
/// IncomingFileBridge moves the file out of the group and hands it to
/// Flutter, which opens the GPX import page. Anything that is not a GPX
/// file is refused here with a short message.
final class ShareViewController: UIViewController {
  private static let appGroup = "group.com.harriercentral.app"
  private static let inboxFolder = "ShareInbox"
  private static let urlScheme = "harriercentral"

  private let label = UILabel()
  private let spinner = UIActivityIndicatorView(style: .large)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.systemBackground
    label.text = "Sending to Harrier Central…"
    label.textAlignment = .center
    label.numberOfLines = 0
    label.font = UIFont.preferredFont(forTextStyle: .body)
    label.translatesAutoresizingMaskIntoConstraints = false
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.startAnimating()
    view.addSubview(spinner)
    view.addSubview(label)
    NSLayoutConstraint.activate([
      spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),
      label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    handleShare()
  }

  private func handleShare() {
    let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
    let providers = items.flatMap { $0.attachments ?? [] }
    let candidates = ["com.topografix.gpx", "public.xml", "public.data"]
    guard let provider = providers.first(where: { p in candidates.contains { p.hasItemConformingToTypeIdentifier($0) } }),
          let typeId = candidates.first(where: { provider.hasItemConformingToTypeIdentifier($0) })
    else {
      finish(message: "That is not a GPX file.")
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: typeId) { [weak self] url, _ in
      guard let self = self else { return }
      guard let url = url, url.pathExtension.lowercased() == "gpx" || typeId != "public.data" else {
        self.finish(message: "That is not a GPX file.")
        return
      }
      // loadFileRepresentation's URL is gone once this closure returns, so
      // copy synchronously into the app group before handing off.
      guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup) else {
        self.finish(message: "Harrier Central could not receive the file.")
        return
      }
      let inbox = groupURL.appendingPathComponent(Self.inboxFolder, isDirectory: true)
      try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
      var name = url.lastPathComponent
      if name.isEmpty { name = "shared.gpx" }
      if !name.lowercased().hasSuffix(".gpx") { name += ".gpx" }
      let dst = inbox.appendingPathComponent(name)
      try? FileManager.default.removeItem(at: dst)
      do {
        try FileManager.default.copyItem(at: url, to: dst)
      } catch {
        self.finish(message: "Harrier Central could not receive the file.")
        return
      }
      var comps = URLComponents()
      comps.scheme = Self.urlScheme
      comps.host = "import"
      comps.queryItems = [URLQueryItem(name: "file", value: name)]
      guard let open = comps.url else {
        self.finish(message: nil)
        return
      }
      DispatchQueue.main.async {
        self.openHostApp(open)
        // Give the open a moment before the sheet goes away; completing the
        // request first can cancel it. Whether or not the app came forward,
        // the file is in the inbox for the app's next activation.
        self.label.text = "Shared with Harrier Central. If the app did not open, open it to import."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          self.finish(message: nil)
        }
      }
    }
  }

  /// Extensions have no UIApplication; the host app is opened by walking
  /// the responder chain to whatever can perform openURL — the share-
  /// extension hand-off every share-to-app plugin uses. It is not an
  /// official API and recent iOS is picky: every responder that answers is
  /// asked (not just the first), with both selectors. If none of it works
  /// the file is still in the app-group inbox, and the app sweeps that
  /// inbox whenever it becomes active — so the share is never lost.
  private func openHostApp(_ url: URL) {
    let openURL = sel_registerName("openURL:")
    let openURLOptions = sel_registerName("openURL:options:completionHandler:")
    var responder: UIResponder? = self
    while let r = responder {
      if r.responds(to: openURLOptions) {
        _ = r.perform(openURLOptions, with: url, with: [:] as NSDictionary)
      } else if r.responds(to: openURL) {
        _ = r.perform(openURL, with: url)
      }
      responder = r.next
    }
    // Foundation's UIApplication, reached without naming it (an extension
    // cannot link UIApplication.shared).
    if let appClass = NSClassFromString("UIApplication") as? NSObject.Type,
       let app = appClass.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? NSObject,
       app.responds(to: openURLOptions) {
      _ = app.perform(openURLOptions, with: url, with: [:] as NSDictionary)
    }
  }

  private func finish(message: String?) {
    DispatchQueue.main.async {
      if let message = message {
        self.spinner.stopAnimating()
        self.label.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
      } else {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
      }
    }
  }
}
