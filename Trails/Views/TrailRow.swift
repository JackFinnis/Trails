//
//  TrailRow.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailRow: View {
    @AppStorage("metric") var metric = true
    @AppStorage("expand") var expand = false
    @Binding var showTrailsView: Bool
    @EnvironmentObject var vm: ViewModel
    @State var showWebView = false
    
    let trail: Trail
    let list: Bool
    
    var body: some View {
        Button {
            if list {
                showTrailsView = false
                vm.selectedTrail = trail
            }
            if vm.selectedTrail != nil {
                vm.zoomTo(trail)
            }
        } label: {
            VStack(spacing: 0) {
                if expand || list {
                    GeometryReader { geo in
                        AsyncImage(url: trail.photoUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: 120)
                                .clipped()
                        } placeholder: {
                            Color(.systemFill)
                                .frame(width: geo.size.width, height: 120)
                        }
                    }
                    .frame(height: 120)
                    .transition(.opacity)
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading) {
                            Text(trail.name)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.headline)
                            Text("\(metric ? "\(trail.km) km" : "\(trail.miles) miles") • \(trail.days) days")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 0)
                        if list {
                            Button {
                                showWebView = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                            }
                        } else {
                            Menu {
                                Button {
                                    expand.toggle()
                                } label: {
                                    Label(expand ? "Shrink" : "Expand", systemImage: expand ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                        .font(.title2)
                                }
                                Button {
                                    vm.isSelecting = true
                                } label: {
                                    Label("Select a Section", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                        .font(.title2)
                                }
                                Button {
                                    showWebView = true
                                } label: {
                                    Label("Learn More", systemImage: "info.circle")
                                        .font(.title2)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                            }
                        }
                        if !list {
                            Button {
                                vm.deselectTrail()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.trailing, 5)
                    
                    if expand || list {
                        Text(trail.headline)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(10)
            }
            .buttonStyle(.borderless)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .animation(.default, value: expand)
        .transition(.move(edge: .top).combined(with: .opacity))
        .background {
            NavigationLink("", isActive: $showWebView) {
                WebView(trail: trail)
                    .ignoresSafeArea()
            }
            .hidden()
        }
    }
}
