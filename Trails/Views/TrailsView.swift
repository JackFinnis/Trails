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
    @State var angle = Angle.radians(0)
    @AppStorage("sortBy") var sortBy = TrailSort.name
    @AppStorage("country") var country: Country?
    @AppStorage("cycle") var cycle = false
    @AppStorage("completed") var completed = false
    @AppStorage("favourites") var favourites = false
    
    @Binding var showTrailsView: Bool
    
    var filtering: Bool { favourites || completed || cycle || country != nil }
    var filteredTrails: [Trail] {
        vm.trails
            .filter {
                (text.isEmpty || $0.name.localizedCaseInsensitiveContains(text)) &&
                (country == nil || country == $0.country) &&
                (!cycle || $0.cycle) &&
                (!completed || vm.completedTrails.contains($0.id)) &&
                (!favourites || vm.favouriteTrails.contains($0.id))
            }
            .sorted {
                switch sortBy {
                case .name:
                    return $0.name < $1.name
                case .ascent:
                    return $0.ascent ?? .greatestFiniteMagnitude < $1.ascent ?? .greatestFiniteMagnitude
                case .distance:
                    return $0.metres < $1.metres
                case .completed:
                    return (vm.getSelectedTrips(trail: $0)?.metres ?? 0) > (vm.getSelectedTrips(trail: $1)?.metres ?? 0)
                }
            }
    }
    
    var body: some View {
        NavigationView {
            List(filteredTrails) { trail in
                Section {
                    TrailRow(showTrailsView: $showTrailsView, trail: trail, list: true)
                }
            }
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
                            Toggle(isOn: $cycle.animation()) {
                                Label("Cycleways", systemImage: "bicycle")
                            }
                            Toggle(isOn: $completed.animation()) {
                                Label("Completed", systemImage: "checkmark.circle")
                            }
                            Toggle(isOn: $favourites.animation()) {
                                Label("Favourites", systemImage: "star")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle" + (filtering ? ".fill" : ""))
                        }
                        Menu {
                            Text("Sort Trails")
                            Picker("", selection: $sortBy.animation()) {
                                ForEach(TrailSort.allCases, id: \.self) { sortBy in
                                    Label(sortBy.rawValue, systemImage: sortBy.image)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .rotation3DEffect(angle, axis: (1, 0, 0))
                        }
                        .onChange(of: sortBy) { _ in
                            withAnimation {
                                angle += .radians(.pi)
                            }
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
