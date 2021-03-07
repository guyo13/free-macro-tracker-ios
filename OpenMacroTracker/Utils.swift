//
//  Utils.swift
//  OpenMacroTracker
//
//  Created by Guy O on 07/03/2021.
//

import Foundation

func changeURLScheme(url: URL, newScheme: String) -> URL? {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    components?.scheme = newScheme
    return components?.url
}
