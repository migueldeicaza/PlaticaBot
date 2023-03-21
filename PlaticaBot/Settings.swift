//
//  Settings.swift
//  platicador
//
//  Created by Miguel de Icaza on 3/21/23.
//

import Foundation
import SwiftUI

let openAIkeytag = "OpenAI-key"
func getOpenAIKey () -> String {
    let key = NSUbiquitousKeyValueStore.default.string(forKey: openAIkeytag) ?? ""
    
    print ("Key is: \(key)")
    return key
}

func setOpenAIKey (_ value: String) {
    NSUbiquitousKeyValueStore.default.set(value, forKey: openAIkeytag)
    NSUbiquitousKeyValueStore.default.synchronize()
}

class OpenAIKey: ObservableObject {
    @Published var key: String = getOpenAIKey()
}

var openAIKey = OpenAIKey ()

struct GeneralSettings: View {
    @Binding var settingsShown: Bool
    @State var key = getOpenAIKey()
    var dismiss: Bool
    
    var body: some View {
        VStack (alignment: .leading){
            Text ("General Settings")
                .bold()
                .padding ([.bottom])
            Grid {
                GridRow (alignment: .firstTextBaseline){
                    Text ("OpenAI Key")
                    VStack (alignment: .leading){
                        TextField ("key", text: $key)
                            .onSubmit {
                                setOpenAIKey(key)
                                openAIKey.key = key
                            }
                        Text ("Create or get an OpenAI key from the [API keys](https://platform.openai.com/account/api-keys) dashboard.")
                            .foregroundColor(.secondary)
                            .font (.caption)
                    }
                }
            }
            .padding ()
            if dismiss {
                HStack {
                    Spacer ()
                    Button ("Ok") {
                        settingsShown = false
                    }
                    Spacer ()
                }
            }
            Spacer ()
        }
        .padding ()
    }
}

struct iOSGeneralSettings: View {
    @Binding var settingsShown: Bool
    var dismiss: Bool
    var body: some View {
        NavigationView {
            GeneralSettings(settingsShown: $settingsShown, dismiss: dismiss)
        }
        .navigationTitle("Settings")
    }
}
struct SettingsView: View {
    @Binding var settingsShown: Bool
    var dismiss: Bool
    
    var body: some View {
        TabView {
            GeneralSettings (settingsShown: $settingsShown, dismiss: dismiss)
                .tabItem {
                    Label ("General", systemImage: "person")
                }
        }.frame (width: 350, height: 250)
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsShown: .constant (true), dismiss: false)
    }
}
