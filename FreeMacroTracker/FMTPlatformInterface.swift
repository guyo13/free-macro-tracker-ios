//
//  FMTPlatformInterface.swift
//  FreeMacroTracker
//
//  Created by Guy O on 11/10/2020.
//

import UIKit
import WebKit

class FMTPlatformInterface: NSObject, WKScriptMessageHandler {
    
    var delegate: FMTIOSDelegate
    
    init(withDelegate: FMTIOSDelegate) {
        delegate = withDelegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("FMTPlatformInterface called \(message.name)")
        switch(message.name) {
        case "FMTShowAlert":
            guard let dict = message.body as? [String: String],
                  let msg = dict["msg"],
                  let level = dict["level"] else {
                print("FMTShowAlert missing arguments")
                return
            }
            delegate.FMTShowAlert(msg: msg, level: level)
        case "FMTShowAlertBar":
            guard let dict = message.body as? [String: String],
                  let msg = dict["msg"] else {
                print("FMTShowAlertBar missing msg argument")
                return
            }
            delegate.FMTShowAlertBar(msg: msg)
        case "FMTExportData":
            guard let dict = message.body as? [String: String],
                  let data = dict["data"],
                  let filename = dict["filename"] ?? "" else {
                print("FMTExportData missing arguments")
                return
            }
            delegate.FMTExportData(data: data, filename: filename)
        case "FMTImportData":
            delegate.FMTImportData()
        case "FMTShowPrompt":
            guard let dict = message.body as? [String: String],
                  let msg = dict["msg"],
                  let level = dict["level"] else {
                print("FMTShowPrompt missing arguments")
                return
            }
            delegate.FMTShowPrompt(msg: msg, level: level)
        case "FMTFinishedLoading":
            delegate.FMTFinishedLoading()
        default:
            break
        }
    }
    
}
