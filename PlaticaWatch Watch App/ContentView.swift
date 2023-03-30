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
            ChatView(temperature: .constant(1.0), newModel: .constant(false))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
