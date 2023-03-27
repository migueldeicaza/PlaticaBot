//
//  ContentView.swift
//  PlaticaBot
//
//  Created by Miguel de Icaza on 3/13/23.
//

import SwiftUI
import Foundation
struct ContentView: View {
    @State var settingsShown = false
    @Environment(\.openURL) var openURL
    @ObservedObject var key = openAIKey
    @Binding var temperature: Float
    @Binding var newModel: Bool
    
    var body: some View {
        NavigationStack {
            if key.key == "" {
#if os(iOS)
                iOSGeneralSettings(settingsShown: .constant(true), temperature: $temperature, dismiss: false)
                
#else
                Text ("Please set your key in Settings")
                Button (action: {
                    #if os(macOS)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    #endif
                }) {
                    Text ("Open Settings")
                }
#endif
            } else {
                ChatView (temperature: $temperature, newModel: $newModel)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(temperature: .constant(1.0), newModel: .constant(false))
    }
}
