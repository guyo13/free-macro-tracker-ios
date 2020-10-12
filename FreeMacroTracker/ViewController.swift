//
//  ViewController.swift
//  FreeMacroTracker
//
//  Created by Guy O on 11/10/2020.
//

import UIKit
import WebKit
import MobileCoreServices
import UniformTypeIdentifiers
import MaterialComponents.MaterialSnackbar

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, FMTIOSDelegate, UIDocumentPickerDelegate {
    
    @IBOutlet var webView: WKWebView!
    let FMT_URL = "https://app.freemacrotracker.com"
    var snackBarOffset: UIView?
    var vSpinner : UIView?
    let utilQueue = DispatchQueue(label: "com.freemacrotracker.app.util", qos: .utility)
    var initialNavRequest: WKNavigation?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // Gets notified when safe area changes and reapplies the offset required
    // for displaying the snackbar in the correct height
    override func viewSafeAreaInsetsDidChange() {
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
        if self.snackBarOffset != nil {
            self.snackBarOffset?.removeFromSuperview()
        }
        self.snackBarOffset = transparentNavbarOffset
        self.view.addSubview(transparentNavbarOffset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let platformInterface = FMTPlatformInterface(withDelegate: self)
        webView!.uiDelegate = self
        webView!.navigationDelegate = self
        webView!.configuration.userContentController.add(platformInterface, name:"FMTShowAlert")
        webView!.configuration.userContentController.add(platformInterface, name:"FMTShowAlertBar")
        webView!.configuration.userContentController.add(platformInterface, name:"FMTExportData")
        webView!.configuration.userContentController.add(platformInterface, name:"FMTImportData")
        webView!.configuration.userContentController.add(platformInterface, name:"FMTShowPrompt")
        webView!.configuration.userContentController.add(platformInterface, name:"FMTFinishedLoading")
        webView!.configuration.ignoresViewportScaleLimits = false
        // Cache policy for developing
//        initialNavRequest = webView!.load(URLRequest(url: URL(string: FMT_URL)!, cachePolicy: .reloadIgnoringLocalCacheData))
        // Default Cache policy for production
        initialNavRequest = webView!.load(URLRequest(url: URL(string: FMT_URL)!))
        showSpinner(onView: self.view)
        let greenBgColor = UIColor(red: 42/255, green: 118/255, blue: 59/255, alpha: 1)
        self.view.backgroundColor = greenBgColor
    }
    
    override func loadView() {
        super.loadView()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation == self.initialNavRequest {
            print("Initial navigation request finished")
            removeSpinner()
        }
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
//        self.view.addSubview(webView)
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
                //TODO - do the export
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

    func showSpinner(onView : UIView) {
            let spinnerView = UIView.init(frame: onView.bounds)
//            spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
            let ai = UIActivityIndicatorView.init(style: .large)
            ai.startAnimating()
            ai.center = spinnerView.center
            
            DispatchQueue.main.async {
                spinnerView.addSubview(ai)
                onView.addSubview(spinnerView)
            }
            
            vSpinner = spinnerView
        }
        
        func removeSpinner() {
            DispatchQueue.main.async {
                self.vSpinner?.removeFromSuperview()
                self.vSpinner = nil
            }
        }
    
}

