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

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        setApplicationActivationPolicy()
    }
}
#endif

@main
struct PlaticaBotApp: App {
    @State var temperature: Float = 1.0
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    func quit () {
        NSApplication.shared.terminate(nil)
    }
    #endif
    
    var body: some Scene {
        WindowGroup (id: "chat") {
            ContentView(temperature: $temperature)
                .onAppear {
                    guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }
                    window.orderFront(self)
                    NSApplication.shared.activate(ignoringOtherApps: true)

                }
        }
        #if os(macOS)
        Settings {
            SettingsView(settingsShown: .constant(true), temperature: $temperature, dismiss: false)
        }

        MenuBarExtra("", systemImage: "brain") {
            Button (action: { openWindow(id: "chat") }) {
                Text ("New Window")
            }
            Divider()

            Button {
                // Sad solution from: https://stackoverflow.com/questions/65355696/how-to-programatically-open-settings-preferences-window-in-a-macos-swiftui-app
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Text ("Settings...")
            }

            Divider()

            Button (action: { quit ()}) {
                Text ("Quit PlaticaBot")
            }
        }
        .menuBarExtraStyle(.menu)
        #endif
    }
}
