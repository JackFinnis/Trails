//
//  TrailsView.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailsView: View {
    @Binding var showTrailsView: Bool
    @EnvironmentObject var vm: ViewModel
    @State var text = ""
    
    var filteredTrails: [Trail] {
        vm.trails.filter { text.isEmpty || $0.name.localizedCaseInsensitiveContains(text) }
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
            .toolbar {
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
