//
//  ViewController.swift
//  FreeMacroTracker
//
//  Created by Guy O on 11/10/2020.
//
// Copyright (c) 2020, Guy Or Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a GNU GPL
// license that can be found in the LICENSE file.

import UIKit
import WebKit
import MobileCoreServices
import UniformTypeIdentifiers
import MaterialComponents.MaterialSnackbar

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, FMTIOSDelegate, UIDocumentPickerDelegate, WKURLSchemeHandler {

    
    @IBOutlet var webViewContainer: UIView?
    var webView: WKWebView?
    var webAppBundle: Bundle?
    var navigationDelegate: NavigationDelegate?
    let WEB_APP_BUNDLE_ID = "com.freemacrotracker.app.WebApp"
    let FMT_URL_SCHEME = "free-macro-tracker"
    let FMT_URL = "free-macro-tracker://app.freemacrotracker.com"
    let FMT_FALLBACK_URL = "https://app.freemacrotracker.com"
    var snackBarOffset: UIView?
    var vSpinner : UIView?
    let utilQueue = DispatchQueue(label: "com.freemacrotracker.app.util", qos: .utility)
    var initialNavRequest: WKNavigation?
    let SNACKBAR_DURATION_SHORT = TimeInterval(1.5)
    var fmtAppLoaded = false
    let dateFormatter = DateFormatter()
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func createTransparentNavbarOffset() -> UIView {
        let transparentNavbarOffset = UIView.init(
            frame: CGRect(x: 0,
                          y: self.view.bounds.height -
                            self.view.safeAreaInsets.bottom -
                             48,
                          width: self.view.bounds.width,
                          height: 0
            )
        )
        transparentNavbarOffset.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0)
        return transparentNavbarOffset
    }

    // Gets notified when safe area changes and reapplies the offset required
    // for displaying the snackbar in the correct height
    override func viewSafeAreaInsetsDidChange() {
        let transparentNavbarOffset = self.createTransparentNavbarOffset()
        if self.snackBarOffset != nil {
            self.snackBarOffset?.removeFromSuperview()
        }
        self.snackBarOffset = transparentNavbarOffset
        self.view.addSubview(transparentNavbarOffset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var urlToLoad: URL = URL(string: self.FMT_URL)!
        // Load WebApp Bundle or fallback to loading from the web
        let bundleURL = Bundle.main.url(forResource: "WebApp", withExtension: "bundle")
        self.webAppBundle = Bundle(url: bundleURL!)
        if (self.webAppBundle == nil) {
            // If bundle failed to load, fallback to https
            urlToLoad = changeURLScheme(url: urlToLoad, newScheme: "https") ?? URL(string: self.FMT_FALLBACK_URL)!
            print("WebApp Bundle failed loading, falling back to \(urlToLoad.absoluteString)")
        } else {
            self.navigationDelegate = AssetNavigationDelegate(bundle: self.webAppBundle, baseUrl: urlToLoad)
        }
        // Configure the WebView and Platform interface
        let webViewConfig = WKWebViewConfiguration()
        let platformInterface = FMTPlatformInterface(withDelegate: self)
        webViewConfig.userContentController.add(platformInterface, name:"FMTShowAlert")
        webViewConfig.userContentController.add(platformInterface, name:"FMTShowAlertBar")
        webViewConfig.userContentController.add(platformInterface, name:"FMTExportData")
        webViewConfig.userContentController.add(platformInterface, name:"FMTImportData")
        webViewConfig.userContentController.add(platformInterface, name:"FMTShowPrompt")
        webViewConfig.userContentController.add(platformInterface, name:"FMTFinishedLoading")
        webViewConfig.ignoresViewportScaleLimits = false
        webViewConfig.setURLSchemeHandler(self, forURLScheme: self.FMT_URL_SCHEME)

        let webViewContainer: UIView = self.webViewContainer!
        let frame = webViewContainer.frame
        let wv = WKWebView(frame: frame, configuration: webViewConfig)
        print("frame \(frame), translatesAutoresizingMaskIntoConstraints \(wv.translatesAutoresizingMaskIntoConstraints)")
        wv.translatesAutoresizingMaskIntoConstraints = false
        self.webView = wv
        wv.uiDelegate = self
        wv.navigationDelegate = self
        // Add webView and apply constraints
        webViewContainer.addSubview(wv)
        NSLayoutConstraint.activate([
            wv.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            wv.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            wv.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor)
        ])
        
        // Cache policy for developing
        //  initialNavRequest = self.webView.load(URLRequest(url: urlToLoad, cachePolicy: .reloadIgnoringLocalCacheData))

        // Default Cache policy for production
        initialNavRequest = wv.load(URLRequest(url: urlToLoad))

        // Show spinner until page loaded and the WebApp fires finish event
        showSpinner()

        print("Webview frame \(wv.frame)")
        print("View frame \(view.frame)")
    }

    override func loadView() {
        super.loadView()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation == self.initialNavRequest {
            print("Initial navigation request finished")
        }
    }

    // WKURLSchemeHandler Protocol methods
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        print("Start URL Scheme task for: \(urlSchemeTask.request.url?.absoluteString ?? "")")
        guard let navigationDelegate = self.navigationDelegate else {
            print("Null Navigation Delegate, canno't fulfill request for URL: \(urlSchemeTask.request.url?.absoluteString ?? "")")
            urlSchemeTask.didFailWithError(NSError(domain: "SchemeHandler", code: 668, userInfo: nil))
            return;
        }
        // Load the data using the navigation delegate
        navigationDelegate.navigate(webView, start: urlSchemeTask)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        urlSchemeTask.didFinish()
    }
    
    @objc func alertClose(_ gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func FMTShowAlert(msg: String, level: String) {
        var title: String? = nil
        switch (level) {
        // TODO - Localize Strings
        case "danger":
            title = "Error"
        case "warning":
            title = "Warning"
        case "success":
            title = "Success"
        default:
            break
        }
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion:{
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertClose(_:))))
        })
    }
    
    func FMTShowAlertBar(msg: String) {
        let message = MDCSnackbarMessage()
        message.text = msg
        message.duration = SNACKBAR_DURATION_SHORT
        if self.snackBarOffset != nil {
            MDCSnackbarManager.default.setPresentationHostView(self.snackBarOffset)
        }
        MDCSnackbarManager.default.show(message)
    }
    
    func FMTShowPrompt(msg: String, level: String) {
        print("FMTShowPrompt called")
        var title: String? = nil
        switch (level) {
        // TODO - Localize Strings
        case "warning":
            title = "Warning"
        default:
            title = "Are you sure?"
        }
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .default) { (action: UIAlertAction) in
            self.webView!.evaluateJavaScript("platformInterface.userPromptPlatformCallback(true);")
        })
        alert.addAction(UIAlertAction(title: "NO", style: .default) { (action: UIAlertAction) in
            self.webView!.evaluateJavaScript("platformInterface.userPromptPlatformCallback(false);")
        })
        self.present(alert, animated: true)
    }
    
    func FMTExportData(data: String, filename: String) {
        print("FMTExportData called")
        utilQueue.async {
            do {
                let fileURL : URL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: fileURL, atomically: true, encoding: .utf8)
                let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                DispatchQueue.main.async {
                    if let popoverController = activityController.popoverPresentationController {
                        popoverController.sourceView = self.snackBarOffset
                        popoverController.sourceRect = self.snackBarOffset!.bounds
                    }
                    self.present(activityController, animated: true, completion: nil)
                }
            } catch {
                print("Can't write exported data to file \(error)")
            }
        }
    }
    
    func FMTImportData() {
        print("FMTImportData called")
        var documentPicker: UIDocumentPickerViewController?
        if #available(iOS 14, *) {
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.text, UTType.json, UTType.data])
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeJSON as String, kUTTypeText as String, kUTTypeData as String], in: .open)
        }
        documentPicker!.delegate = self
        present(documentPicker!, animated: true, completion: nil)
    }
    
    func FMTFinishedLoading() {
        print("FMTFinishedLoading called")
        self.fmtAppLoaded = true
        removeSpinner()
    }
    
    func importData(fileUrl: URL) {
        utilQueue.async {
            guard fileUrl.startAccessingSecurityScopedResource() else {
                // Handle the failure here.
                DispatchQueue.main.async {
                    self.FMTShowAlert(msg: "The selected file could not be imported.", level: "danger")
                }
                return
            }
            defer { fileUrl.stopAccessingSecurityScopedResource() }
            // Use file coordination for reading and writing any of the URL’s content.
            var error: NSError? = nil
            NSFileCoordinator().coordinate(readingItemAt: fileUrl, error: &error) { (url) in
                do {
                    let rawData = try String(contentsOf: url)
                    DispatchQueue.main.async {
                        self.webView!.evaluateJavaScript("FMTImportData(`\(rawData)`);")
                    }
                } catch {
                    print("Error while reading URL \(url)")
                    DispatchQueue.main.async {
                        self.FMTShowAlert(msg: "Error reading file!", level: "danger")
                    }
                }
            }
        }
    }
    
    //Document Picker Delegate
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // TODO - localize
        FMTShowAlertBar(msg: "File Import aborted.")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            // TODO - localize
            let alert = UIAlertController(title: "Are you sure?", message: "Importing is irreversible and might replace ALL of your existing data.\nContinue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "YES", style: .default) { (action: UIAlertAction) in
                self.importData(fileUrl: urls[0])
            })
            alert.addAction(UIAlertAction(title: "NO", style: .default) { (action: UIAlertAction) in
                self.FMTShowAlertBar(msg: "File Import aborted.")
            })
            self.present(alert, animated: true)
        } else {
            FMTShowAlertBar(msg: "No file selected to Import.")
        }
    }

    func showSpinner() {
        let spinnerView = UIView.init(frame: self.view.frame)
        spinnerView.backgroundColor = UIColor.init(red: 54/255, green: 157/255, blue: 77/255, alpha: 1)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = self.view.center
        spinnerView.addSubview(ai)
        self.view.addSubview(spinnerView)
        vSpinner = spinnerView
    }
        
    func removeSpinner() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }
    }
    
    func updateToday() {
        if (self.fmtAppLoaded) {
            // Check if App state today value is same day as now
            // If not then update it
            self.webView!.evaluateJavaScript("( () => {" +
                "const today = fmtAppInstance.today;" +
                "return `${today.getFullYear()}-${today.getMonth() + 1 }-${today.getDate()}`;" +
                "} )();") { (result: Any?, err: Error?) in
                self.utilQueue.async {
                    var shouldUpdate = false
                    if err != nil {
                        print("Error getting app's date")
                        return
                    }
                    else if let dateString = result as? String {
                        let appStateToday = self.dateFormatter.date(from: dateString)
                        if let appStateTodayString =  self.dateFormatter.string(for: appStateToday) {
                            let now = Date()
                            let nowString = self.dateFormatter.string(from: now)
                            print("Comparing \(nowString) with \(appStateTodayString)" )
                            shouldUpdate = nowString != appStateTodayString
                        } else {
                            shouldUpdate = true
                        }
                        if (shouldUpdate) {
                            DispatchQueue.main.async {
                                print("Updating Today")
                                self.webView!.evaluateJavaScript("( () => { FMTOverviewLoadCurrentDay(); } )();") {
                                    res, err in
                                    if err != nil {
                                        print("Failed updating today!")
                                    } else {
                                        print("Updated today successfully!")
                                    }
                                }
                            }
                        }
                    }
                    else {
                        print("Got null date string")
                        return
                    }
                }
            }
        }
    }
}

