//
//  ContentView.swift
//  Compote
//
//  Created by James MARTIN on 01.02.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(viewModel.notesContent, id: \.self) { note in
                        Text(note)
                            .padding()
                    }
                }
            }
            .onAppear(perform: viewModel.fetchNotesContent)
        }
}

#Preview {
    ContentView()
}
