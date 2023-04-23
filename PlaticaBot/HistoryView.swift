//
//  HistoryView.swift
//  PlaticaBot
//
//  Created by Miguel de Icaza on 3/30/23.
//

import SwiftUI
import Foundation

struct ChatPreview: View {
    var first: Interaction
    
    var body: some View {
        VStack (alignment: .leading) {
            Text ("\(first.query)")
            Text (first.date.formatted(date: .abbreviated, time: .shortened))
                .foregroundColor(.secondary)
                .font(.caption2)
        }
    }
}


struct HistoryView: View {
    @State var chats: [[Interaction]] = []
    
    func loadChats () {
        guard let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        var result: [[Interaction]] = []
        let decoder = JSONDecoder()
        
        for f in (try? FileManager.default.contentsOfDirectory(at: doc, includingPropertiesForKeys: nil)) ?? [] {
            guard let d = try? Data(contentsOf: f) else {
                continue
            }
            guard let interaction = try? decoder.decode([Interaction].self, from: d) else {
                continue
            }
            guard interaction.count != 0 else {
                continue
            }
            result.append (interaction)
        }
        chats = result
    }
    
    var body: some View {
        NavigationStack {
            Form {
                List {
                    ForEach (chats, id: \.self) { exchange in
                        if let first = exchange.first {
                            NavigationLink(destination: { StaticChatView (interactions: .constant (exchange)) }, label: {
                                ChatPreview (first: first)
                            })
                        }
                    }
                }
                .navigationTitle("History")
            }
            #if os(macOS)
            .formStyle(.grouped)
            #endif
        }.onAppear {
            loadChats()
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
