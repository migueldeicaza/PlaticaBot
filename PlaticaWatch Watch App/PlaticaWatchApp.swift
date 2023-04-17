//
//  PlaticaWatchApp.swift
//  PlaticaWatch Watch App
//
//  Created by Miguel de Icaza on 3/21/23.
//

import SwiftUI

@main
struct PlaticaWatch_Watch_AppApp: App {
    @StateObject private var settings = SettingsStorage()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
