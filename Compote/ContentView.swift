//
//  ContentView.swift
//  Compote
//
//  Created by James MARTIN on 01.02.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = NotesViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(viewModel.notesContent, id: \.id) { note in
                    VStack(alignment: .leading) {
                        Text(note.id)
                            .font(.headline)
                            .padding(.bottom, 1)
                        
                        Text(note.name)
                            .font(.headline)
                            .padding(.bottom, 1)
                        
//                        Text(note.body)
//                            .font(.subheadline)
//                            .padding(.bottom, 1)
                        
                        Text("Created: \(note.creationDate)")
                            .font(.caption)
                            .padding(.bottom, 1)
                        
                        Text("Last Modified: \(note.modificationDate)")
                            .font(.caption)
                            .padding(.bottom, 1)
                    }
                    .padding()
                    Divider()
                }
            }
        }
        .onAppear(perform: viewModel.fetchNotesContent)
    }
}

// Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
