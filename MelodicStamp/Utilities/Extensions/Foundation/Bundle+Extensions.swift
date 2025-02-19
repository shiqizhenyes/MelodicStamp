//
//  Bundle+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/10.
//

import Foundation

extension Bundle {
    enum Key: String {
        case appName = "CFBundleName"
        case displayName = "CFBundleDisplayName"
        case bundleID = "CFBundleIdentifier"
        case copyright = "NSHumanReadableCopyright"
        case appBuild = "CFBundleVersion"
        case appVersion = "CFBundleShortVersionString"
    }
}

extension Bundle {
    subscript(localized key: Key) -> String {
        String(localized: String.LocalizationValue(key.rawValue))
    }

    subscript(_ key: Key) -> String {
        guard let infoDictionary = self.infoDictionary else {
            return "⚠️"
        }
        return infoDictionary[key.rawValue] as? String ?? "⚠️"
    }
}
