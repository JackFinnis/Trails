//
//  SearchBar.swift
//  Paddle
//
//  Created by Jack Finnis on 14/09/2022.
//

import SwiftUI

struct SearchBar: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = vm
        vm.searchBar = searchBar
        
        searchBar.backgroundImage = UIImage()
        searchBar.autocorrectionType = .no
        searchBar.scopeButtonTitles = SearchScope.allCases.map(\.rawValue)
        searchBar.scopeBarBackgroundImage = UIImage()
        
        return searchBar
    }
    
    func updateUIView(_ searchBar: UISearchBar, context: Context) {
        if vm.isSearching {
            searchBar.placeholder = "Search \(vm.searchScope.rawValue)"
        } else {
            searchBar.placeholder = "Search Trails & Maps"
        }
    }
}
