//
//  TrailsView.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailsView: View {
    @EnvironmentObject var vm: ViewModel
    @State var showInfoView = false
    @State var text = ""
    @AppStorage("sortBy") var sortBy = TrailSort.name
    @AppStorage("country") var country: Country?
    @AppStorage("cycle") var cycle = false
    
    @Binding var showTrailsView: Bool
    
    var filteredTrails: [Trail] {
        vm.trails
            .filter { trail in
                (text.isEmpty || trail.name.localizedCaseInsensitiveContains(text)) &&
                (country == nil || country == trail.country) &&
                (!cycle || trail.cycle)
            }
            .sorted {
                switch sortBy {
                case .name:
                    return $0.name < $1.name
                case .ascent:
                    return $0.ascent ?? .max < $1.ascent ?? .max
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
            .navigationTitle("The Trails")
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
                        Menu {
                            Text("Filter Trails")
                            Picker("", selection: $country.animation()) {
                                Text("UK")
                                    .tag(nil as Country?)
                                ForEach(Country.allCases, id: \.self) { country in
                                    Text(country.rawValue)
                                        .tag(country as Country?)
                                }
                            }
                            Toggle("Cycleways", isOn: $cycle.animation())
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle" + ((cycle || country != nil) ? ".fill" : ""))
                        }
                        Menu {
                            Text("Sort Trails")
                            Picker("", selection: $sortBy.animation()) {
                                ForEach(TrailSort.allCases, id: \.self) { sortBy in
                                    Text(sortBy.rawValue)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                    .font(.body.weight(.medium))
                }
                ToolbarItem(placement: .principal) {
                    DraggableBar("The Trails")
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 15) {
                        Button {
                            showInfoView = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        Button {
                            showTrailsView = false
                        } label: {
                            DismissCross()
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.body.weight(.medium))
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
