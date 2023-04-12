//
//  PlaticaBotApp.swift
//  PlaticaBot
//
//  Created by Miguel de Icaza on 3/21/23.
//
#if os(iOS)
import SwiftUI

@main
struct PlaticaBotApp: App {
    @StateObject private var settings = SettingsStorage()

    var body: some Scene {
        WindowGroup (id: "chat") {
            ContentView()
                .environmentObject(settings)
        }
    }
}
#endif
