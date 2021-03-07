//
//  NavigationDelegate.swift
//  OpenMacroTracker
//
//  Created by Guy O on 07/03/2021.
//

import Foundation
import WebKit

protocol NavigationDelegate {
    func navigate(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) -> Void
}
