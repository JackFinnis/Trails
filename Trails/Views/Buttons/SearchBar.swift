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
            Menu {
                if vm.recentSearches.isEmpty {
                    Text("No Recents")
                }
                ForEach(vm.recentSearches.reversed(), id: \.self) { search in
                    Button(search) {
                        vm.searchBar?.text = search
                        vm.search()
                    }
                }
            } label: {
                if vm.searchLoading {
                    ProgressView()
                } else {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            .squareButton()
            .animation(.none)
            .padding(.trailing, -8)
            SearchView()
            
            Button {
                vm.stopSearching()
            } label: {
                Image(systemName: "xmark")
            }
            .squareButton()
            .padding(.leading, -8)
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
