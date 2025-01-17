//
//  SettingsPerformancePage.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import SwiftUI

struct SettingsPerformancePage: View {
    var body: some View {
        SettingsExcerptView(.performance, descriptionKey: "Performance settings excerpt.")

        Section {
            SettingsGradientFPSControl()

            SettingsGradientResolutionControl()
        }

        Section("While \(Bundle.main.displayName) is Inactive") {
            SettingsHidesInspectorWhileInactiveControl()
        }
    }
}

#Preview {
    Form {
        SettingsPerformancePage()
    }
    .formStyle(.grouped)
}
