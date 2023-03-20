//
//  TrailsView.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

enum SortBy: String, CaseIterable {
    case name = "Name"
    case distance = "Distance"
    
    var image: String {
        switch self {
        case .name:
            return "character"
        case .distance:
            return "ruler"
        }
    }
}

struct TrailsView: View {
    @EnvironmentObject var vm: ViewModel
    @State var showInfoView = false
    @State var text = ""
    @AppStorage("sortBy") var sortBy = SortBy.name
    
    @Binding var showTrailsView: Bool
    
    var filteredTrails: [Trail] {
        vm.trails.filter { text.isEmpty || $0.name.localizedCaseInsensitiveContains(text) }
            .sorted {
                switch sortBy {
                case .name:
                    return $0.name < $1.name
                case .distance:
                    return $0.metres < $1.metres
                }
            }
    }
    
    var body: some View {
        NavigationView {
            List(filteredTrails) { trail in
                Section {
                    TrailRow(showTrailsView: $showTrailsView, trail: trail, list: true)
                        .background(Color.background)
                }
            }
            .navigationTitle("National Trails")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $text.animation(), placement: .navigationBarDrawer(displayMode: .always))
            .overlay {
                if filteredTrails.isEmpty {
                    Text("No Results Found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    HStack {
                        Button {
                            showInfoView = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        Menu {
                            Picker("", selection: $sortBy.animation()) {
                                ForEach(SortBy.allCases, id: \.self) { sortBy in
                                    Label(sortBy.rawValue, systemImage: sortBy.image)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showTrailsView = false
                    } label: {
                        DismissCross()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showInfoView) {
            InfoView(welcome: false)
        }
    }
}

struct TrailsView_Previews: PreviewProvider {
    static var previews: some View {
        Text("").sheet(isPresented: .constant(true)) {
            TrailsView(showTrailsView: .constant(true))
                .environmentObject(ViewModel())
        }
    }
}
