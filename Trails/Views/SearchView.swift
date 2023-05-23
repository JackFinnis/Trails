//
//  SearchView.swift
//  Trails
//
//  Created by Jack Finnis on 19/04/2023.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if vm.searchRequestLoading {
                ProgressView()
                    .padding(.top, 50)
            } else if vm.isEditing {
                if vm.searchText.isNotEmpty {
                    Divider()
                        .padding(.leading)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(vm.searchCompletions, id: \.self) { completion in
                                Button {
                                    vm.searchMaps(newSearch: .completion(completion))
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text(completion.title)
                                                .font(.headline)
                                            Text(completion.subtitle)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .frame(height: 60)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.leading)
                            }
                        }
                        .padding(.bottom)
                    }
                } else if vm.filteredRecentSearches.isNotEmpty {
                    HStack {
                        Text("Recents")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            vm.recentSearches = []
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    Divider()
                        .padding(.leading)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(vm.filteredRecentSearches, id: \.self) { string in
                                Button {
                                    vm.searchMaps(newSearch: .string(string))
                                } label: {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.secondary)
                                            .frame(width: 30)
                                        Text(string)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .frame(height: 40)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.leading)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            } else if vm.searchResults.isEmpty {
                Text("No Results")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            } else if vm.searchResults.isNotEmpty {
                Divider()
                    .padding(.leading)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.searchResults, id: \.self) { result in
                            Button {
                                vm.sheetDetent = .medium
                                vm.mapView?.selectAnnotation(result, animated: true)
                                if let rect = result.mapItem.placemark.region?.rect {
                                    vm.setRect(rect, extraPadding: true)
                                }
                            } label: {
                            HStack(spacing: 10) {
                                    let category = result.mapItem.pointOfInterestCategory
                                    Circle().fill(category?.color ?? .red)
                                        .frame(width: 35, height: 35)
                                        .overlay {
                                            Image(systemName: category?.systemName ?? "mappin")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(result.title ?? "")
                                            .font(.headline)
                                        let distance = result.coordinate.location.distance(from: vm.locationManager.location ?? result.coordinate.location)
                                        let formattedDistance = distance == 0 ? "" : vm.formatDistance(distance, showUnit: true, round: false)
                                        let subtitle = result.subtitle ?? ""
                                        Text(formattedDistance.isEmpty ? (subtitle.isEmpty ? "" : subtitle) : (subtitle.isEmpty ? formattedDistance : formattedDistance + " • " + subtitle))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal)
                                .frame(height: 60)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                                .padding(.leading)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .transition(.move(edge: .trailing))
        .animation(.default, value: vm.filteredRecentSearches)
        .animation(.default, value: vm.searchRequestLoading)
        .animation(.default, value: vm.searchResults)
        .lineLimit(1)
    }
}
