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
struct Interaction: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var date = Date ()
    var query: String
    var plain: String
}

class InteractionStorage: ObservableObject {
    @Published var interactions: [Interaction] = []
    //Interaction (query: "Where is France", plain: "France is a country located in Western Europe. It shares borders with Belgium, Luxembourg, Germany, Switzerland, Italy, Spain, and Andorra. The country is also bordered by the English Channel to the north and the Atlantic Ocean to the west.")]
    
    init () {
    }
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

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

struct InteractionView: View {
    var interaction: Interaction
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
#if !os(watchOS)
                    .textSelection(.enabled)
#endif
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
        //.background(.random)
        
    }
}

struct StaticChatView: View {
    @Binding var interactions: [Interaction] 
    @State var synthesizer: AVSpeechSynthesizer
    @State var synthesizerDelegate: SpeechDelegate?
    @State var speaking: UUID? = nil
    
    init (interactions: Binding<[Interaction]>) {
        self._interactions = interactions
        _synthesizer = State (initialValue: AVSpeechSynthesizer())
        _synthesizerDelegate = State (initialValue: nil)
        let d = SpeechDelegate (speaking: .constant(nil))
        _synthesizerDelegate = State (initialValue: d)
        synthesizer.delegate = synthesizerDelegate
    }
    
    var body: some View {
        ScrollView {
            Text ("Conversation from \((interactions.first?.date ?? Date()).formatted(date: .abbreviated, time: .shortened))")
            ForEach (interactions, id: \.id) { inter in
                InteractionView(interaction: inter, synthesizer: $synthesizer, speaking: $speaking)
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
class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    private var contentHeightWhenDragEnded: CGFloat?

    var onDrag: (()->Void)? = nil
    var onBottomReached: (()->Void)? = nil

    /// disable autoscroll when user starts manually scrolling
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onDrag?()
    }

    /// resume autoscroll when user scrolls back down to bottom
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if bottomEdge >= scrollView.contentSize.height {
            onBottomReached?()
        }
        contentHeightWhenDragEnded = scrollView.contentSize.height
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if let contentHeightWhenDragEnded = self.contentHeightWhenDragEnded,
           bottomEdge >= contentHeightWhenDragEnded {
            onBottomReached?()
        }
        contentHeightWhenDragEnded = nil
    }
    
}
#endif

class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
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

struct ChatView: View {
    @EnvironmentObject var settings: SettingsStorage
    @State var id: UUID
    @State var starDate = Date()
    @State var chat = ChatGPT(key: "")
    @State var prompt: String = ""
    @State var started = Date ()
    @StateObject var store = InteractionStorage ()
    @FocusState private var isPromptFocused: Bool
    @State var prime = false
    @State var appended = 0
    @State var stopAutoscroll = false
    @State private var scrollViewContentOffset = CGFloat(0)
    @State var synthesizer: AVSpeechSynthesizer
    @State var synthesizerDelegate: SpeechDelegate?
    @State var playing = false
    @State var speaking: UUID? = nil
    @State var showSettings: Bool = false
    @State var showHistory: Bool = false
    @State var chatInteraction: Interaction? = nil
    @State var serial = 1
    #if os(iOS)
    private var scrollViewDelegate = ScrollViewDelegate()
    #endif
    
    #if os(tvOS) || os(iOS)
    @State var sc: UIScrollView? = nil
    #endif
    
    
    init (prime: Bool = false) {
        self._prime = State (initialValue: prime)
        self._id = State (initialValue: UUID())
        _synthesizer = State (initialValue: AVSpeechSynthesizer())
        _synthesizerDelegate = State (initialValue: nil)
        let d = SpeechDelegate (speaking: .constant(nil))
        _synthesizerDelegate = State (initialValue: d)
        synthesizer.delegate = synthesizerDelegate
    }
    
    func saveConversation () {
        guard let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        guard let result = try? JSONEncoder().encode(store.interactions) else {
            return
        }
        let file = doc.appendingPathComponent("chat-\(id)-\(serial).json")
        try? result.write(to: file)
    }
    
    @MainActor
    func appendAnswer (_ text: String) {
        chatInteraction?.plain += text
        appended += 1
    }
   
    func saveChat () {
        saveConversation()
    }
    
    func newChat () {
        prompt = ""
        store.interactions = []
        started = Date ()
        chat = ChatGPT(key: "")
        serial += 1
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
        
        return markdownToAttributedString(text: result)
    }
    
    func runQuery () {
        stopAutoscroll = false
        chatInteraction = Interaction(query: prompt, plain: "")
        let copy = prompt
        prompt = ""
        appended += 1

        Task {
            chat.model = settings.newModel ? "gpt-4-0314" : "gpt-3.5-turbo"
            chat.key = settings.apiKey
            switch await chat.streamChatText(copy, temperature: settings.temperature) {
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
                    if let chatInteraction {
                        store.interactions.append(chatInteraction)
                    }
                    
                    chatInteraction = nil
                    appended += 1
                }
                saveChat ()
            }
        }
    }
    
    func acceptUserResponse () {
#if os(tvOS) || os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
        runQuery ()
    }
    
    var textFieldCore: some View {
#if os(watchOS)
        TextField(store.interactions.count == 0 ? "Your Question" : "Follow up", text: $prompt)
#else
        HStack (alignment: .bottom) {
            TextField(store.interactions.count == 0 ? "Your Question" : "Follow up", text: $prompt, axis: .vertical)
#if os(iOS)
                .textFieldStyle(.roundedBorder)
#endif
            Button (action: acceptUserResponse) {
                Image (systemName: "arrow.up.circle.fill")
                    .foregroundColor(Color.accentColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .padding([.bottom], 2)
        }
        .padding ([.horizontal])
        .padding ([.vertical], 4)
#endif
    }
    
    var textField: some View {
        textFieldCore
        .focused ($isPromptFocused)
        .onSubmit {
            runQuery()
            isPromptFocused =  true
        }
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
                        ForEach (store.interactions) { inter in
                            InteractionView(interaction: inter, synthesizer: $synthesizer, speaking: $speaking)
                        }
                        if let chatInteraction {
                            InteractionView(interaction: chatInteraction, synthesizer: $synthesizer, speaking: $speaking)
                                .id (10)
                        }
                    }
                    .padding ([.horizontal])
                }
                .scrollDismissesKeyboard(.interactively)
#if os(iOS) || os(tvOS)
                .introspectScrollView { sc in
                    self.sc = sc
                    self.scrollViewDelegate.onDrag = { self.stopAutoscroll = true }
                    self.scrollViewDelegate.onBottomReached = { self.stopAutoscroll = false }
                    self.sc?.delegate = scrollViewDelegate
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
                        proxy.scrollTo(10, anchor: .bottom)
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
                        Button (action: { settings.newModel.toggle() }) {
                            Text ("Toggle Engine - " + (settings.newModel ? "GPT4" : "GPT3"))
                        }
                        Button (action: { showSettings = true }) {
                            Text ("Settings")
                        }
                        Button (action: { showHistory = true }) {
                            Text ("History")
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
            iOSGeneralSettings(settingsShown: $showSettings, dismiss: true)
        }
        .sheet (isPresented: $showHistory) {
            HistoryView ()
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
        ChatView(prime: true)
            .environmentObject(SettingsStorage.preview)
    }
}
