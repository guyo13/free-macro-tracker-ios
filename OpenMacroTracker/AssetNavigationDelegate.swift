//
//  AssetNavigationDelegate.swift
//  OpenMacroTracker
//
//  Created by Guy O on 07/03/2021.
//

import Foundation
import WebKit

class AssetNavigationDelegate: NavigationDelegate {
    let bundle: Bundle
    let baseUrl: URL
    
    init(bundle: Bundle?, baseUrl: URL) {
        self.bundle = bundle ?? Bundle.main
        self.baseUrl = baseUrl
    }
    func navigate(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // Change URL to HTTPS scheme
        guard let newUrl = changeURLScheme(url: urlSchemeTask.request.url!, newScheme: "https") else {
            print("Invalid Request URL: \(urlSchemeTask.request.url?.absoluteString ?? "")")
            urlSchemeTask.didFailWithError(NSError(domain: "AssetNavigationDelegate", code: 666, userInfo: nil))
            return;
        }
        let data: Data?
        let mimeType: String
        let fileExt: String
        if newUrl.path == baseUrl.path {
            // Load index.html
            data = NSDataAsset(name: "index.html", bundle: self.bundle)!.data
            fileExt = "html"
        }
        // CSS and CSS Map
        else if newUrl.path == "/css/bootstrap.min.css" {
            data = NSDataAsset(name: "bootstrap.min.css", bundle: self.bundle)!.data
            fileExt = "css"
        } else if newUrl.path == "/css/bootstrap.min.css.map" {
           data = NSDataAsset(name: "bootstrap.min.css.map", bundle: self.bundle)!.data
           fileExt = "json"
        } else if newUrl.path == "/css/fmt.css" {
           data = NSDataAsset(name: "fmt.css", bundle: self.bundle)!.data
           fileExt = "css"
        } else if newUrl.path == "/css/fontawesome.min.css" {
           data = NSDataAsset(name: "fontawesome.min.css", bundle: self.bundle)!.data
           fileExt = "css"
        } else if newUrl.path == "/css/light.min.css" {
            data = NSDataAsset(name: "light.min.css", bundle: self.bundle)!.data
            fileExt = "css"
        }
        // Javascript and JS Map
        else if newUrl.path == "/javascript/jquery-3.4.1.min.js" {
            data = NSDataAsset(name: "jquery-3.4.1.min.js", bundle: self.bundle)!.data
            fileExt = "js"
        } else if newUrl.path == "/javascript/bootstrap.bundle.min.js" {
            data = NSDataAsset(name: "bootstrap.bundle.min.js", bundle: self.bundle)!.data
            fileExt = "js"
        } else if newUrl.path == "/javascript/fmt.js" {
            data = NSDataAsset(name: "fmt.js", bundle: self.bundle)!.data
            fileExt = "js"
        } else if newUrl.path == "/javascript/bootstrap.bundle.min.js.map" {
            data = NSDataAsset(name: "bootstrap.bundle.min.js.map", bundle: self.bundle)!.data
            fileExt = "json"
        }
        // Webfonts
        else if newUrl.path == "/webfonts/fa-light-300.ttf" {
            data = NSDataAsset(name: "fa-light-300.ttf", bundle: self.bundle)!.data
            fileExt = "ttf"
        }
        else {
            fileExt = ""
            data = nil
        }
        mimeType = mimeTypes[fileExt] ?? DEFAULT_MIME_TYPE
        if (data != nil) {
            urlSchemeTask.didReceive(URLResponse(url: newUrl, mimeType: mimeType, expectedContentLength: data!.count, textEncodingName: "utf-8"))
            urlSchemeTask.didReceive(data!)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(NSError(domain: "AssetNavigationDelegate", code: 667, userInfo: nil))
            print("Asset yielded nil data for path: \(newUrl.path)")
        }
        
    }
}
