//
//  TrailsView.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailsView: View {
    struct Header: View {
        @EnvironmentObject var vm: ViewModel
        @State var showInfoView = false
        
        var body: some View {
            HStack {
                SearchBar()
                    .padding(.vertical, -10)
                    .padding(.horizontal, -8)
                
                if !vm.isSearching {
                    Button {
                        showInfoView = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.icon)
                    }
                    .sheet(isPresented: $showInfoView) {
                        InfoView(welcome: false)
                    }
                }
            }
        }
    }
    
    @EnvironmentObject var vm: ViewModel
    @State var angle = Angle.zero
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Text(vm.filteredTrails.count.formatted(singular: "Trail") + (vm.isFiltering ? " Found" : ""))
                    .font(.headline)
                    .animation(.none, value: vm.filteredTrails.count)
                    .onTapGesture {
                        vm.zoomToFilteredTrails()
                    }
                Spacer()
                Menu {
                    Picker("", selection: $vm.trailFilter.animation()) {
                        Text("No Filter")
                            .tag(nil as TrailFilter?)
                        ForEach(TrailFilter.allCases, id: \.self) { filter in
                            if let systemName = filter.systemName {
                                Label(filter.name, systemImage: systemName)
                                    .tag(filter as TrailFilter?)
                            } else {
                                Text(filter.name)
                                    .tag(filter as TrailFilter?)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(vm.trailFilter == nil ? "" : ".fill")")
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
            .frame(height: 35, alignment: .top)
            
            Divider()
                .padding(.leading)
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(vm.filteredTrails) { trail in
                        TrailRow(trail: trail)
                    }
                }
                .padding()
            }
            .overlay {
                if vm.filteredTrails.isEmpty {
                    Text("No Trails Found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .animation(.default, value: vm.filteredTrails)
        .transition(.move(edge: .leading))
    }
}
