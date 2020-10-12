//
//  FMTIOSDelegate.swift
//  FreeMacroTracker
//
//  Created by Guy O on 11/10/2020.
//

import Foundation

protocol FMTIOSDelegate {
    
    func FMTShowAlert(msg: String, level: String)
    func FMTShowAlertBar(msg: String)
    func FMTShowPrompt(msg: String, level: String)
    func FMTExportData(data: String, filename: String)
    func FMTImportData()
    func FMTFinishedLoading()
}
