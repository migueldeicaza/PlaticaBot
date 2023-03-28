//
//  PlaticaBotApp.swift
//  PlaticaBot
//
//  Created by Miguel de Icaza on 3/21/23.
//

import SwiftUI

@main
struct PlaticaBotApp: App {
    @State var temperature: Float = 1.0
    @State var newModel: Bool = false
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    
    func quit () {
        NSApplication.shared.terminate(nil)
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView(temperature: $temperature, newModel: $newModel)
        }
        #if os(macOS)
        Window("Chat", id: "chat") {
            ChatView(temperature: $temperature, newModel: $newModel)
        }
        Settings {
            SettingsView(settingsShown: .constant(true), temperature: $temperature, newModel: $newModel, dismiss: false)
        }

        MenuBarExtra("", systemImage: "brain") {
            Button (action: { openWindow(id: "chat") }) {
                Text ("New Window")
            }
            Button (action: { quit ()}) {
                Text ("Quit PlaticaBot")
            }
        }
        .menuBarExtraStyle(.menu)
        #endif
    }
}
