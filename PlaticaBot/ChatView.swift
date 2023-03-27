//
//  ContentView.swift
//  platicador
//
//  Created by Miguel de Icaza on 3/11/23.
//
import Foundation
import SwiftUI
import SwiftChatGPT
#if !os(watchOS) && !os(macOS)
import Introspect
#endif
import AVFoundation
import AVFAudio

/// Records what the user asked, the plain result, and the attributed version of it
struct Interaction: Identifiable, Equatable, Hashable {
    var id = UUID()
    var query: String
    var plain: String
}

class InteractionStorage: ObservableObject {
    @Published var interactions: [Interaction] = []
    //Interaction (query: "Where is France", plain: "France is a country located in Western Europe. It shares borders with Belgium, Luxembourg, Germany, Switzerland, Italy, Spain, and Andorra. The country is also bordered by the English Channel to the north and the Atlantic Ocean to the west.")]
    
    init () { }
}

struct SingleInteractionView<Content:View, Content2:View>: View {
    var color: Color
    @ViewBuilder var left: () -> Content
    @ViewBuilder var text: () -> Content2
    
    var body: some View {
        HStack (alignment: .top){
            left ()
            text ()
            Spacer()
        }
        .padding()
        .foregroundColor(.primary)
        .background (color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if os(watchOS)
let userColor = Color.orange
let assistantColor = Color.blue
#else
let userColor = Color ("UserColor")
let assistantColor = Color ("BotColor")
#endif

struct InteractionView: View {
    @Binding var interaction: Interaction
    @Binding var synthesizer: AVSpeechSynthesizer
    @Binding var speaking: UUID?
    
    var img: some View {
        VStack { Image (systemName: "person") }
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            SingleInteractionView(color: userColor) {
                VStack { Image (systemName: "person") }
            } text: {
                Text (interaction.query)
            }
            SingleInteractionView(color: assistantColor) {
                VStack {
                    Image (systemName: "tortoise")
                        .font (.footnote)
                    Spacer ()
                    Image (systemName: speaking == interaction.id ? "stop" : "play")
                        .font (.footnote)
                        .foregroundColor(speaking == interaction.id ? Color.accentColor : Color.primary)
                        .onTapGesture {
                            if speaking == interaction.id {
                                synthesizer.stopSpeaking(at: .word)
                                speaking = nil
                                return
                            } else if speaking != nil {
                                synthesizer.stopSpeaking(at: .word)
                            }
                            let utterance = AVSpeechUtterance(string: interaction.plain)
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                            // Alternative:
                            //                             utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.eloquence.en-US.Rocko")

                            //utterance.rate = 0.5

                            synthesizer.speak(utterance)
                            speaking = interaction.id
                        }
                }
            } text: {
                HStack (alignment: .top){
                    Text (markdownToAttributedString(text: interaction.plain))
#if !os(watchOS)
                        .textSelection(.enabled)
#endif
                    Spacer ()
                }
            }
        }
    }
}

#if !os(watchOS) && !os(macOS)
extension UIScrollView {
    func scrollToBottom(animated:Bool) {
        let offset = self.contentSize.height - self.visibleSize.height
        if offset > self.contentOffset.y {
            self.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
        }
    }
}
#endif

struct ChatView: View {
    @State var chat = ChatGPT(key: openAIKey.key)
    @Binding var temperature: Float
    @ObservedObject var key = openAIKey
    @Binding var newModel: Bool
    @State var prompt: String = ""
    @State var started = Date ()
    @ObservedObject var store = InteractionStorage ()
    @FocusState private var isPromptFocused: Bool
    @State var prime = false
    @State var appended = 0
    @State var stopAutoscroll = false
    @State private var scrollViewContentOffset = CGFloat(0)
    @State var synthesizer: AVSpeechSynthesizer
    @State var synthesizerDelegate: MyDelegate?
    @State var playing = false
    @State var speaking: UUID? = nil
    @State var showSettings: Bool = false
    
    #if os(tvOS) || os(iOS)
    @State var sc: UIScrollView? = nil
    #endif
    
    class MyDelegate: NSObject, AVSpeechSynthesizerDelegate {
        @Binding var speaking: UUID?
        
        init (speaking: Binding<UUID?>) {
            _speaking = speaking
        }
        
        func set (speaking: Binding<UUID?>) {
            _speaking = speaking
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            speaking = nil
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        }
    }
    
    init (prime: Bool = false, temperature: Binding<Float>, newModel: Binding<Bool>) {
        self._prime = State (initialValue: prime)
        _synthesizer = State (initialValue: AVSpeechSynthesizer())
        _synthesizerDelegate = State (initialValue: nil)
        _temperature = temperature
        _newModel = newModel
        let d = MyDelegate (speaking: .constant(nil))
        _synthesizerDelegate = State (initialValue: d)
        synthesizer.delegate = synthesizerDelegate
    }
    
    @MainActor
    func appendAnswer (_ text: String) {
        let idx = store.interactions.count-1
        if idx < 0 {
            return
        }
         
        store.interactions[idx].plain += text
        appended += 1
    }
   
    func saveChat () {
        // Save the chat
    }
    
    func newChat () {
        prompt = ""
        store.interactions = []
        started = Date ()
        chat = ChatGPT(key: key.key)
    }
    
    func getMessageSummary () -> String {
        guard let first = store.interactions.first else {
            return "PlaticaBot: Empty Discussion"
        }
        return "PlaticaBot: \(first.query)"
    }
    
    func makeAttributedString () -> AttributedString {
        var result: String = ""
        for item in store.interactions {
            result += "User: \(item.query)\n\nPlaticaBot: \(item.plain)\n\n"
        }
        
        print ( "AttributedString: \(result)")
        return markdownToAttributedString(text: result)
    }
    
    func runQuery () {
        store.interactions.append(Interaction(query: prompt, plain: ""))
        stopAutoscroll = false
        let copy = prompt
        prompt = ""
        appended += 1
        Task {
            chat.model = newModel ? "gpt-4-0314" : "gpt-3.5-turbo"
            chat.key = openAIKey.key
            switch await chat.streamChatText(copy, temperature: temperature) {
            case .failure(let error):
                appendAnswer("Communication Error:\n\(error.description)")
                return
            case .success(let results):
                for try await result in results {
                    if let result {
                        print ("Got: \(result)")
                        DispatchQueue.main.async {
                            appendAnswer (result)
                        }
                    }
                }
                DispatchQueue.main.async {
                    appended += 1
                }
                saveChat ()
            }
        }
    }
    
    var textFieldCore: some View {
#if os(watchOS)
        TextField(store.interactions.count == 0 ? "Your Question" : "Follow up", text: $prompt)
#else
        TextField(store.interactions.count == 0 ? "Your Question" : "Follow up", text: $prompt, axis: .vertical)
            .textFieldStyle(.roundedBorder)
#endif
    }
    
    var textField: some View {
        textFieldCore
        .focused ($isPromptFocused)
        .onSubmit {
            runQuery()
        }
#if !os(watchOS)
        .onChange(of: prompt) { newValue in
            guard let newValueLastChar = newValue.last else { return }
            if newValueLastChar == "\n" {
                prompt.removeLast()
#if os(tvOS) || os(iOS)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
                runQuery ()
            }
        }
    #endif

    }
    
    var shareView: some View {
        ShareLink(item: makeAttributedString(),
                  subject: Text ("PlaticaBot Conversation"),
                  message: Text (getMessageSummary()),
                  preview: SharePreview("PlaticaBot", icon: Image (systemName: "tortoise.fill")))
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            ScrollViewReader { proxy in
                ScrollView  {
                    VStack {
                        SingleInteractionView (color: assistantColor) {
                            Image (systemName: "brain")
                        } text: {
                            VStack {
                                Text ("Welcome to PlaticaBot, ask your questions below")
                            }
                        }
                        ForEach ($store.interactions, id: \.id) { $inter in
                            InteractionView(interaction: $inter, synthesizer: $synthesizer, speaking: $speaking)
                                .id (inter)
                        }
                    }.id (UUID ())
                }
                .scrollDismissesKeyboard(.interactively)
#if os(iOS) || os(tvOS)
                .introspectScrollView { sc in
                    self.sc = sc
                }
                .onChange(of: appended, perform: { value in
                    //proxy.scrollTo(1, anchor: .bottom)
                    if !stopAutoscroll {
                        sc?.scrollToBottom(animated: false)
                    }
                })
#elseif os(macOS) || os(watchOS)
                .onChange(of: appended, perform: { value in
                    if let last = store.interactions.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                })
#endif
#if os(watchOS)
                textField
#endif
            }
            VStack (alignment: .leading){
#if !os(watchOS)
                textField
#endif
            }
            //.padding([.horizontal, .bottom])
            #if os(iOS)
            .background (Color (uiColor: UIColor.secondarySystemBackground))
            #endif
        }
        #if os(macOS)
        .padding ()
        #endif
        #if !os(watchOS)
        .navigationTitle("PlaticaBot")
        #endif
        .toolbar {
            #if os(watchOS)
            ToolbarItem(placement: .destructiveAction) {
                Button(action: newChat) {
                    Text ("New")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                shareView
            }
            #elseif os(macOS)
            ToolbarItem(placement: .destructiveAction){
                Button(action: newChat) {
                    Text ("New Chat")
                }
            }
            #elseif os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: newChat) {
                    Text ("New Chat")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ControlGroup {
                    shareView
                    Menu (content: {
                        Button (action: { newModel.toggle() }) {
                            Text ("Toggle Engine - " + (newModel ? "GPT4" : "GPT3"))
                        }
                        Button (action: { showSettings = true }) {
                            Text ("Settings")
                        }
                    }, label: {
                        Label ("Settings", systemImage: "gear")
                    })
                }
            }
            #endif
        }
        #if os(iOS)
        .sheet (isPresented: $showSettings) {
            iOSGeneralSettings(settingsShown: $showSettings, temperature: $temperature, dismiss: true)
        }
        #endif
        .onAppear {
            isPromptFocused = true
            if prime {
                store.interactions.append(Interaction(query: "Hello", plain: "World `here`"))
            }
            synthesizerDelegate?.set (speaking: $speaking)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(prime: true, temperature: .constant(1.0), newModel: .constant(false))
    }
}
