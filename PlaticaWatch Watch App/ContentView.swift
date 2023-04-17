//
//  ContentView.swift
//  PlaticaWatch Watch App
//
//  Created by Miguel de Icaza on 3/21/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ChatView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
