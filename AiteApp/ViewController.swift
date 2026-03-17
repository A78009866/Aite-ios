import UIKit
import WebKit
import UniformTypeIdentifiers
import PhotosUI

class ViewController: UIViewController {

    // MARK: - Properties
    private var webView: WKWebView!
    private var splashView: UIView!
    private var progressView: UIProgressView!
    private var refreshControl: UIRefreshControl!
    private var progressObservation: NSKeyValueObservation?

    // The main URL of the web app
    private let appURL = URL(string: "https://chat-trimer.vercel.app")!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupWebView()
        setupSplashScreen()
        setupProgressBar()
        setupRefreshControl()
        loadApp()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    // Support portrait only
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()

        // Allow inline media playback (important for chat audio/video)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Enable JavaScript
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // Data detection
        config.dataDetectorTypes = [.link, .phoneNumber]

        // Process pool for cookie persistence
        config.processPool = WKProcessPool()

        // Website data store (persistent cookies)
        config.websiteDataStore = WKWebsiteDataStore.default()

        // User content controller for JS bridge
        let userContentController = WKUserContentController()

        // Inject viewport-fit=cover meta tag to handle safe areas
        let viewportScript = WKUserScript(
            source: """
            var meta = document.querySelector('meta[name="viewport"]');
            if (meta) {
                if (!meta.content.includes('viewport-fit=cover')) {
                    meta.content += ', viewport-fit=cover';
                }
            }
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(viewportScript)

        // Add message handler for iOS communication
        userContentController.add(self, name: "iosHandler")

        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        // Allow link preview (3D Touch / long press)
        webView.allowsLinkPreview = true

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupSplashScreen() {
        splashView = UIView(frame: view.bounds)
        splashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        splashView.backgroundColor = .black

        // App logo
        let logoImageView = UIImageView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.clipsToBounds = true
        logoImageView.layer.cornerRadius = 24
        logoImageView.backgroundColor = UIColor.darkGray

        // Load logo from URL
        if let logoURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/a0/Sond_skyline_from_top_City_Hall_-_Aug_2025.jpg") {
            URLSession.shared.dataTask(with: logoURL) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        logoImageView.image = image
                    }
                }
            }.resume()
        }

        splashView.addSubview(logoImageView)

        // App name label
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Aite"
        nameLabel.font = UIFont.systemFont(ofSize: 42, weight: .heavy)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        splashView.addSubview(nameLabel)

        // Subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "from salem ahmed"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .light)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        subtitleLabel.textAlignment = .center
        splashView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: splashView.centerYAnchor, constant: -60),
            logoImageView.widthAnchor.constraint(equalToConstant: 110),
            logoImageView.heightAnchor.constraint(equalToConstant: 110),

            nameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            nameLabel.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: splashView.centerXAnchor)
        ])

        view.addSubview(splashView)
    }

    private func setupProgressBar() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .clear
        progressView.progressTintColor = UIColor(red: 57/255, green: 130/255, blue: 247/255, alpha: 1.0)
        progressView.isHidden = true
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Observe loading progress
        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] webView, _ in
            guard let self = self else { return }
            let progress = Float(webView.estimatedProgress)
            self.progressView.isHidden = progress >= 1.0
            self.progressView.setProgress(progress, animated: true)
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.progressView.isHidden = true
                    self.progressView.setProgress(0, animated: false)
                }
            }
        }
    }

    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 57/255, green: 130/255, blue: 247/255, alpha: 1.0)
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        webView.reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func loadApp() {
        let request = URLRequest(url: appURL, cachePolicy: .reloadRevalidatingCacheData)
        webView.load(request)
    }

    private func hideSplash() {
        UIView.animate(withDuration: 0.5, animations: {
            self.splashView.alpha = 0
        }) { _ in
            self.splashView.removeFromSuperview()
        }
    }

    // Send APNs token to web app (similar to Android's receiveAndroidToken)
    private func sendTokenToWebApp() {
        if let token = UserDefaults.standard.string(forKey: "apns_device_token") {
            let js = "if(window.receiveIOSToken) { window.receiveIOSToken('\(token)'); }"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Hide splash after first successful load
        if splashView.superview != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hideSplash()
            }
        }

        // Send push token to web app
        sendTokenToWebApp()

        // Inject CSS to handle iOS safe areas
        let safeAreaCSS = """
        (function() {
            var style = document.createElement('style');
            style.textContent = 'body { padding-top: env(safe-area-inset-top); padding-bottom: env(safe-area-inset-bottom); }';
            document.head.appendChild(style);
        })();
        """
        webView.evaluateJavaScript(safeAreaCSS, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showOfflineAlert()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Show offline/error UI
        if (error as NSError).code == NSURLErrorNotConnectedToInternet ||
           (error as NSError).code == NSURLErrorTimedOut {
            showOfflineAlert()
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Open external links in Safari
        if let host = url.host,
           !host.contains("chat-trimer.vercel.app") &&
           !host.contains("localhost") &&
           (url.scheme == "http" || url.scheme == "https") &&
           navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // Handle tel:, mailto:, etc.
        if let scheme = url.scheme, ["tel", "mailto", "sms", "facetime"].contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private func showOfflineAlert() {
        let alert = UIAlertController(
            title: "غير متصل بالإنترنت",
            message: "تحقق من اتصالك بالإنترنت وحاول مرة أخرى",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "إعادة المحاولة", style: .default) { [weak self] _ in
            self?.loadApp()
        })
        present(alert, animated: true)
    }
}

// MARK: - WKUIDelegate (File Upload, Camera, Alerts)

extension ViewController: WKUIDelegate {

    // Handle JavaScript alert()
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "حسناً", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    // Handle JavaScript confirm()
    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "نعم", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "لا", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }

    // Handle JavaScript prompt()
    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "حسناً", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "إلغاء", style: .cancel) { _ in
            completionHandler(nil)
        })
        present(alert, animated: true)
    }

    // Handle window.open() - open in same WebView
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !(navigationAction.targetFrame!.isMainFrame) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // Handle camera/media capture from <input type="file">
    // This is automatically handled by WKWebView on iOS 14+
    // But we need to ensure permissions are granted
}

// MARK: - WKScriptMessageHandler (JS Bridge)

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "iosHandler" {
            if let body = message.body as? [String: Any] {
                handleJSMessage(body)
            }
        }
    }

    private func handleJSMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }

        switch action {
        case "haptic":
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        case "share":
            if let text = message["text"] as? String {
                let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                present(activityVC, animated: true)
            }
        case "copyToClipboard":
            if let text = message["text"] as? String {
                UIPasteboard.general.string = text
            }
        default:
            break
        }
    }
}
