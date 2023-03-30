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
    @State var temperature: Float = 1.0
    @State var newModel = false
    
    var body: some Scene {
        WindowGroup (id: "chat") {
            ContentView(temperature: $temperature, newModel: $newModel)
        }
    }
}
#endif
