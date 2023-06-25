//
//  Settings.swift
//  platicador
//
//  Created by Miguel de Icaza on 3/21/23.
//

import Foundation
import SwiftUI

// MARK: -
// MARK: Settings Storage

class SettingsStorage: ObservableObject {
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    private let APIKeyKey = "OpenAI-key"
    @Published var apiKey: String {
        didSet {
            keyValueStore.set(apiKey, forKey: APIKeyKey)
            keyValueStore.synchronize()
        }
    }
    private let temperatureKey = "Temperature-key"
    @Published var temperature: Float {
        didSet {
            keyValueStore.set(temperature, forKey: temperatureKey)
            keyValueStore.synchronize()
        }
    }
    private let modelKey = "Model-key"
    @Published var newModel: Bool {
        didSet {
            keyValueStore.set(newModel, forKey: modelKey)
            keyValueStore.synchronize()
        }
    }
#if os(macOS)
    private let showDockIconKey = "ShowDockIcon-key"
    @Published var showDockIcon: Bool {
        didSet {
            keyValueStore.set(showDockIcon, forKey: showDockIconKey)
            keyValueStore.synchronize()
        }
    }
#endif
    
    init() {
        self.apiKey = keyValueStore.string(forKey: APIKeyKey) ?? ""
        self.temperature = keyValueStore.object(forKey: temperatureKey) as? Float ?? 1.0
        self.newModel = keyValueStore.bool(forKey: modelKey)
#if os(macOS)
        self.showDockIcon = keyValueStore.bool(forKey: showDockIconKey)
#endif
    }

    static let preview = SettingsStorage()
}

// MARK: -
// MARK: Settings View

struct GeneralSettings: View {
    @EnvironmentObject var settings: SettingsStorage
    @State var apiKey: String = ""
    @Binding var settingsShown: Bool
    var dismiss: Bool
    
    var body: some View {
        Form {
            Picker("Model", selection: $settings.newModel) {
                Text("GPT-3.5-turbo-16k").tag(false)
                Text("GPT-4").tag(true)
            }
            LabeledContent ("Temperature") {
                Slider(value: $settings.temperature, in: 0.0...1.6, step: 0.2) {
                    EmptyView()
                } minimumValueLabel: {
                    Text("Focused").font(.footnote).fontWeight(.thin)
                } maximumValueLabel: {
                    Text("Random").font(.footnote).fontWeight(.thin)
                }
            }.padding([.leading, .trailing])
            VStack (alignment: .leading) {
                TextField ("OpenAI Key", text: $apiKey)
                    .onAppear {
                        apiKey = settings.apiKey
                    }
                    .onSubmit {
                        settings.apiKey = apiKey
                    }
                Text ("Create or get an OpenAI key from the [API keys](https://platform.openai.com/account/api-keys) dashboard.")
                    .foregroundColor(.secondary)
                    .font (.caption)
            }
            .padding ()
#if os(macOS)
            LabeledContent("Show Dock Icon") {
                Toggle(isOn: $settings.showDockIcon) {
                    Text(" ")
                }
            }.padding([.leading, .trailing])
#endif
            if dismiss {
                HStack {
                    Spacer ()
                    Button ("Ok") {
                        settings.apiKey = apiKey
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

// MARK: -
// MARK: Preview

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
#if os(iOS)
        iOSGeneralSettings(settingsShown: .constant(true), dismiss: false)
            .environmentObject(SettingsStorage.preview)
#else
        SettingsView(settingsShown: .constant (true), dismiss: false)
            .environmentObject(SettingsStorage.preview)
#endif
        
    }
}
