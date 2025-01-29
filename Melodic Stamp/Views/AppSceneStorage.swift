//
//  AppSceneStorage.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import SwiftUI

enum AppSceneStorage: String, Hashable, Equatable, CaseIterable, Identifiable, Codable {
    // MARK: Player

    case playbackVolume
    case playbackMuted

    var id: Self { self }

    func callAsFunction() -> String { rawValue }
}
