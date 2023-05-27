//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct SelectBar: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Select a Section")
                    .font(.headline)
                Text(vm.selectError ? "Select different start and end points." : ("Tap on the \(vm.startPin == nil ? "start" : "end") point"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                vm.stopSelecting()
            } label: {
                Image(systemName: "xmark")
                    .font(.icon)
            }
            .padding(.horizontal, 5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .blurBackground(prominentShadow: true)
        .offset(x: vm.shake ? 20 : 0)
        .onTapGesture {
            vm.zoomTo(vm.selectedTrail)
        }
        .onDismiss {
            vm.stopSelecting()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct SelectBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Map(mapRect: .constant(.world))
                .ignoresSafeArea()
            SelectBar()
        }
        .environmentObject(ViewModel())
    }
}
