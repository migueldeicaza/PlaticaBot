//
//  PlaticaWatchApp.swift
//  PlaticaWatch Watch App
//
//  Created by Miguel de Icaza on 3/21/23.
//

import SwiftUI

@main
struct PlaticaWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let key = getOpenAIKey()
                }
        }
    }
}
