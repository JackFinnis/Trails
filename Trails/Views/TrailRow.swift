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
        VStack(spacing: 0) {
            if expand || list {
                AsyncImage(url: trail.photoUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                } placeholder: {
                    Color(.systemFill)
                        .frame(height: 100)
                }
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
                        Button(action: zoomToTrail) {
                            Image(systemName: "map")
                                .font(.title2)
                        }
                    } else {
                        Button {
                            expand.toggle()
                        } label: {
                            Image(systemName: expand ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                        }
                        Button {
                            vm.isSelecting = true
                        } label: {
                            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                .font(.title2)
                        }
                    }
                    Button {
                        showWebView = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title2)
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
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .animation(.default, value: expand)
        .transition(.move(edge: .top).combined(with: .opacity))
        .if { if list { $0.background(Color(.systemBackground)) } else { $0.materialBackground() } }
        .onTapGesture(perform: zoomToTrail)
        .background {
            NavigationLink("", isActive: $showWebView) {
                WebView(trail: trail)
                    .ignoresSafeArea()
            }
            .hidden()
        }
    }
    
    func zoomToTrail() {
        showTrailsView = false
        vm.selectedTrail = trail
        vm.zoomTo(trail)
    }
}
