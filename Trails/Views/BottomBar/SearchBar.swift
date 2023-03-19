//
//  SearchBar.swift
//  Paddle
//
//  Created by Jack Finnis on 14/09/2022.
//

import SwiftUI

struct SearchBar: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            SearchView()
            Button("Cancel") {
                vm.stopSearching()
            }
            .font(.body)
            .padding(.trailing, 10)
        }
    }
}

struct SearchView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = vm
        vm.searchBar = searchBar
        
        searchBar.placeholder = "Search Maps"
        searchBar.backgroundImage = UIImage()
        searchBar.autocorrectionType = .no
        searchBar.textContentType = .location
        searchBar.becomeFirstResponder()
        
        return searchBar
    }
    
    func updateUIView(_ searchBar: UISearchBar, context: Context) {}
}
