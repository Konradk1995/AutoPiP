//
//  ViewController.swift
//  AutoPiP
//

import Cocoa
import SafariServices
import WebKit

let extensionBundleIdentifier = "com.konrad.AutoPiP.Extension"
let githubRepo = "Konradk1995/AutoPiP"

class ViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet var webView: WKWebView!

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        self.webView.configuration.userContentController.add(self, name: "controller")
        self.webView.loadFileURL(
            Bundle.main.url(forResource: "Main", withExtension: "html")!,
            allowingReadAccessTo: Bundle.main.resourceURL!
        )
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
            guard let state = state, error == nil else { return }
            DispatchQueue.main.async {
                let useSettings = if #available(macOS 13, *) { true } else { false }
                webView.evaluateJavaScript("show(\(state.isEnabled), \(useSettings), '\(self.currentVersion)')")
                self.checkForUpdates()
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        switch body {
        case "open-preferences":
            SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { _ in
                DispatchQueue.main.async { NSApplication.shared.terminate(nil) }
            }
        default:
            if body.hasPrefix("open-url:") {
                let urlString = String(body.dropFirst("open-url:".count))
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self, let data, error == nil,
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String, !tag.isEmpty,
                  let htmlUrl = json["html_url"] as? String else { return }

            let latest = tag.replacingOccurrences(of: "v", with: "")
            if !latest.isEmpty, latest.compare(self.currentVersion, options: .numeric) == .orderedDescending {
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("showUpdate('\(latest)', '\(htmlUrl)')")
                }
            }
        }.resume()
    }
}
