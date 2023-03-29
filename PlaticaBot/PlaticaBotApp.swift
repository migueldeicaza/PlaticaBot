//
//  PlaticaBotApp.swift
//  PlaticaBot
//
//  Created by Miguel de Icaza on 3/21/23.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct PlaticaBotApp: App {
    @State var temperature: Float = 1.0
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    
    func quit () {
        NSApplication.shared.terminate(nil)
    }
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView(temperature: $temperature)
        }
        #if os(macOS)
        Window("Chat", id: "chat") {
            ChatView(temperature: $temperature)
                .onAppear {
                    guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }
                                window.orderFront(self)
                                NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        Settings {
            SettingsView(settingsShown: .constant(true), temperature: $temperature, dismiss: false)
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
