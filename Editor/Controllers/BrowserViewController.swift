//
//  BrowserViewController.swift
//  Editor
//
//  Created by Mohamed on 6/10/24.
//

import UIKit
import WebKit

class BrowserViewController: UIViewController {
    private var webView: WKWebView!
    private var currentPageUrl: URL!
    private var defaultURL: URL? = URL(string: "https://google.com") // Default search engine
    private var updateUrlButton: UIBarButtonItem!
    private var backButton: UIBarButtonItem!
    private var forwardButton: UIBarButtonItem!
    internal var editorInteractor: EditorInteractor?
    private var progressView: UIProgressView!
    var initialUrl: URL? {
        set {
            if let newValue = newValue {
                defaultURL = newValue
            }
        }
        get {
            return defaultURL
        }
    }
    var range: NSRange?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    override func loadView() {
        super.loadView()
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration.shared)
        webView.navigationDelegate = self
        if let url = defaultURL {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        view.addSubview(webView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Autolayout
        webView.translatesAutoresizingMaskIntoConstraints = false
        let safeViewMargins = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: safeViewMargins.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: safeViewMargins.trailingAnchor),
            webView.topAnchor.constraint(equalTo: safeViewMargins.topAnchor),
            webView.bottomAnchor.constraint(equalTo: safeViewMargins.bottomAnchor),
        ])
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        if let toolbar = navigationController?.toolbar {
            NSLayoutConstraint.activate([
                progressView.leftAnchor.constraint(equalTo: toolbar.leftAnchor),
                progressView.rightAnchor.constraint(equalTo: toolbar.rightAnchor),
            ])
        }
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.sizeToFit()
        if let toolbar = navigationController?.toolbar {
            toolbar.addSubview(progressView)
        }

         navigationController?.isNavigationBarHidden = true
        
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        
        updateUrlButton = UIBarButtonItem(title: "Update link", style: .plain, target: self, action: #selector(self.saveTapped))
        updateUrlButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .normal)
        updateUrlButton.setTitleTextAttributes([.foregroundColor : primaryColor], for: .selected)
        updateUrlButton.isEnabled = false
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        // SF symbols
        backButton = UIBarButtonItem(image: UIImage(systemName: "arrow.backward"), style: .plain, target: webView, action: #selector(webView.goBack))
        forwardButton = UIBarButtonItem(image: UIImage(systemName: "arrow.forward"), style: .plain, target: webView, action: #selector(webView.goForward))

        toolbarItems = [backButton, forwardButton, spacer, updateUrlButton]
        navigationController?.isToolbarHidden = false
        navigationController?.toolbar.backgroundColor = .white
        navigationController?.toolbar.tintColor = primaryColor
        
        updateButtons()
    }
    
    @objc private func saveTapped() {
        if let range = range {
            editorInteractor?.replaceURL(in: range, with: currentPageUrl, title: webView.title)
            dismiss(animated: true)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            forwardButton.isEnabled = false
        }
        if keyPath == "estimatedProgress" {
            progressView.isHidden = (webView.estimatedProgress == 1)
            progressView.progress = Float(webView.estimatedProgress)
        }
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            currentPageUrl = url
            updateUrlButton.isEnabled = true
        }
        updateButtons()
    }
    
    func webView(_ webView: WKWebView, 
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        updateUrlButton.isEnabled = false
        updateButtons()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateUrlButton.isEnabled = false
    }
    
    func webView(_ webView: WKWebView, 
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: any Error) {
        updateUrlButton.isEnabled = false
    }
    
    func updateButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
}

extension WKWebViewConfiguration {
    static var shared : WKWebViewConfiguration {
        if _sharedConfiguration == nil {
            _sharedConfiguration = WKWebViewConfiguration()
            _sharedConfiguration.websiteDataStore = WKWebsiteDataStore.default()
            _sharedConfiguration.userContentController = WKUserContentController()
            _sharedConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
            _sharedConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = false
        }
        return _sharedConfiguration
    }
    private static var _sharedConfiguration : WKWebViewConfiguration!
}
