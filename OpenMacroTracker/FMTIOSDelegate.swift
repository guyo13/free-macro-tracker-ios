//
//  FMTIOSDelegate.swift
//  FreeMacroTracker
//
//  Created by Guy O on 11/10/2020.
//
// Copyright (c) 2020, Guy Or Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a GNU GPL
// license that can be found in the LICENSE file.

import Foundation

protocol FMTIOSDelegate {
    
    func FMTShowAlert(msg: String, level: String)
    func FMTShowAlertBar(msg: String)
    func FMTShowPrompt(msg: String, level: String)
    func FMTExportData(data: String, filename: String)
    func FMTImportData()
    func FMTFinishedLoading()
}
