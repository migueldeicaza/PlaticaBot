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
    @Binding var temperature: Float
    @State var key = getOpenAIKey()
    var dismiss: Bool
    
    var body: some View {
        Form {
            LabeledContent ("Temperature") {
                Slider(value: $temperature, in: 0.4...1.6, step: 0.2) {
                    EmptyView()
                } minimumValueLabel: {
                    Text("Focused").font(.footnote).fontWeight(.thin)
                } maximumValueLabel: {
                    Text("Random").font(.footnote).fontWeight(.thin)
                }
            }
            VStack (alignment: .leading){
                TextField ("OpenAI Key", text: $key)
                    .onSubmit {
                        setOpenAIKey(key)
                        openAIKey.key = key
                    }
                Text ("Create or get an OpenAI key from the [API keys](https://platform.openai.com/account/api-keys) dashboard.")
                    .foregroundColor(.secondary)
                    .font (.caption)
            }
            .padding ()
            if dismiss {
                HStack {
                    Spacer ()
                    Button ("Ok") {
                        setOpenAIKey(key)
                        openAIKey.key = key
                        settingsShown = false
                    }
                    Spacer ()
                }
            }
        }
    }
}

struct iOSGeneralSettings: View {
    @Binding var settingsShown: Bool
    @Binding var temperature: Float
    var dismiss: Bool
    var body: some View {
        NavigationView {
            GeneralSettings(settingsShown: $settingsShown, temperature: $temperature, dismiss: dismiss)
        }
        .navigationTitle("Settings")
    }
}
struct SettingsView: View {
    @Binding var settingsShown: Bool
    @Binding var temperature: Float
    var dismiss: Bool
    
    var body: some View {
        TabView {
            GeneralSettings (settingsShown: $settingsShown, temperature: $temperature, dismiss: dismiss)
                .tabItem {
                    Label ("General", systemImage: "person")
                }
        }.frame (width: 350, height: 250)
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsShown: .constant (true), temperature: .constant(1.0), dismiss: false)
    }
}
