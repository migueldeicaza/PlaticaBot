//
//  PlaticaBotApp.swift
//  PlaticaBot
//
//  Created by Miguel de Icaza on 3/21/23.
//

import SwiftUI

@main
struct PlaticaBotApp: App {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
   
    func quit () {
        NSApplication.shared.terminate(nil)
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        Window("Chat", id: "chat") {
            ChatView ()
        }
        Settings {
            SettingsView(settingsShown: .constant(true), dismiss: false)
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
