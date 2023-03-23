//
//  TrailRow.swift
//  Trails
//
//  Created by Jack Finnis on 15/03/2023.
//

import SwiftUI

struct TrailRow: View {
    @EnvironmentObject var vm: ViewModel
    @State var showWebView = false
    @State var tappedMenu = Date.now
    
    @Binding var showTrailsView: Bool
    
    let trail: Trail
    let list: Bool
    
    var body: some View {
        Button {
            guard tappedMenu.distance(to: .now) > 1 else { return }
            if list {
                vm.selectedTrail = trail
                showTrailsView = false
            } else {
                vm.zoomTo(trail)
            }
        } label: {
            VStack(spacing: 0) {
                if vm.expand || list {
                    GeometryReader { geo in
                        AsyncImage(url: trail.photoUrl, transaction: Transaction(animation: .default)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 120)
                                    .clipped()
                            default:
                                Color(.systemFill)
                                    .frame(width: geo.size.width, height: 120)
                            }
                        }
                    }
                    .frame(height: 120)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .overlay(alignment: .bottomTrailing) {
                        if trail.cycle {
                            Image(systemName: "bicycle")
                                .padding(4)
                                .background(.regularMaterial)
                                .cornerRadius(5)
                                .padding(5)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading) {
                            Text(trail.name)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.headline)
                            HStack(spacing: 0) {
                                if vm.completedTrailIDs.contains(trail.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 5)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                } else if let metres = vm.getSelectedTrips(trail: trail)?.metres, metres > 0 {
                                    Text("\(vm.formatMiles(metres, showUnit: false, round: true))/")
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                Text("\(vm.formatMiles(trail.metres, showUnit: true, round: true)) • \(trail.days) days")
                                
                                if let ascent = trail.ascent {
                                    Text(" • ")
                                    Image(systemName: "arrow.up")
                                        .padding(.trailing, 2)
                                        .font(.caption2.weight(.bold))
                                    Text("\(vm.formatFeet(ascent))")
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
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
                                    vm.startSelecting()
                                } label: {
                                    Label("Select a Section", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                }
                                Button {
                                    showWebView = true
                                } label: {
                                    Label("More Info", systemImage: "info.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .iconFont()
                            }
                            .onTapGesture {
                                tappedMenu = .now
                            }
                            Button {
                                vm.expand.toggle()
                            } label: {
                                Image(systemName: vm.expand ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .iconFont()
                            }
                        }
                    }
                    .padding(.trailing, 5)
                    
                    if vm.expand || list {
                        Text(trail.headline)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(10)
            }
            .buttonStyle(.borderless)
            .contentShape(Rectangle())
        }
        .if { view in
            if list {
                view.background(Color.background)
            } else {
                view.materialBackground()
            }
        }
        .detectSize($vm.trailRowSize)
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .animation(.default, value: vm.expand)
        .transition(.move(edge: .top).combined(with: .opacity))
        .background {
            NavigationLink("", isActive: $showWebView) {
                WebView(webVM: WebVM(url: trail.url), trail: trail)
            }
            .hidden()
        }
    }
}

struct TrailRow_Previews: PreviewProvider {
    static var previews: some View {
        TrailRow(showTrailsView: .constant(true), trail: .example, list: true)
            .environmentObject(ViewModel())
    }
}
