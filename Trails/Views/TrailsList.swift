//
//  TrailsView.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailsList: View {
    @EnvironmentObject var vm: ViewModel
    @State var angle = Angle.radians(0)
    @AppStorage("country") var country: Country?
    @AppStorage("cycle") var cycle = false
    @AppStorage("completed") var completed = false
    @AppStorage("favourites") var favourites = false
    
    var filtering: Bool { favourites || completed || cycle || country != nil }
    var filteredTrails: [Trail] {
        vm.trails
            .filter {
                (vm.searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(vm.searchText)) &&
                (country == nil || country == $0.country) &&
                (!cycle || $0.cycle) &&
                (!completed || vm.completedTrails.contains($0.id)) &&
                (!favourites || vm.favouriteTrails.contains($0.id))
            }
            .sorted {
                switch vm.sortBy {
                case .name:
                    return $0.name < $1.name
                case .ascent:
                    return $0.ascent ?? .greatestFiniteMagnitude < $1.ascent ?? .greatestFiniteMagnitude
                case .distance:
                    return $0.metres < $1.metres
                case .completed:
                    return (vm.getTrips(trail: $0)?.metres ?? 0) < (vm.getTrips(trail: $1)?.metres ?? 0)
                }
            }
    }
    
    var body: some View {
        VStack {
            if !vm.isSearching {
                HStack(spacing: 15) {
                    Text("Trails")
                        .font(.headline)
                    Spacer()
                    Menu {
                        Picker("", selection: $country.animation()) {
                            Text("UK")
                                .tag(nil as Country?)
                            ForEach(Country.allCases, id: \.self) { country in
                                Text(country.rawValue)
                                    .tag(country as Country?)
                            }
                        }
//                        Toggle(isOn: $cycle.animation()) {
//                            Label("Cycleways", systemImage: "bicycle")
//                        }
                        Toggle(isOn: $completed.animation()) {
                            Label("Completed", systemImage: "checkmark.circle")
                        }
                        Toggle(isOn: $favourites.animation()) {
                            Label("Favourites", systemImage: "star")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle" + (filtering ? ".fill" : ""))
                            .font(.icon)
                    }
                    Menu {
                        Picker("", selection: $vm.sortBy.animation()) {
                            ForEach(TrailSort.allCases, id: \.self) { sortBy in
                                if sortBy == vm.sortBy {
                                    Label(sortBy.rawValue, systemImage: vm.ascending ? "chevron.up" : "chevron.down")
                                } else {
                                    Text(sortBy.rawValue)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.icon)
                            .rotationEffect(angle)
                            .rotation3DEffect(vm.ascending ? .zero : .radians(.pi), axis: (1, 0, 0))
                    }
                    .onChange(of: vm.sortBy) { _ in
                        withAnimation {
                            angle += .radians(.pi)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(vm.ascending ? filteredTrails : filteredTrails.reversed()) { trail in
                        TrailRow(trail: trail)
                    }
                    if filteredTrails.isNotEmpty {
                        Text(filteredTrails.count.formatted(word: "Trail") + ((vm.searchText.isNotEmpty || filtering) ? " Found" : ""))
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .horizontallyCentred()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .animation(.default, value: vm.ascending)
            .animation(.default, value: vm.searchText)
            .overlay {
                if filteredTrails.isEmpty {
                    Text("No Results Found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .transition(.move(edge: .leading))
    }
}
