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
        if vm.isSelecting {
            Group {
                if let polyline = vm.selectPolyline {
                    SelectionBar(polyline: polyline)
                } else if vm.isSelecting {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Select a Section")
                                .font(.headline)
                            Text(vm.selectError ? "Unable to select section. Please try again." : ("Tap on the \(vm.selectPins.isEmpty ? "start" : "end") point"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        Button {
                            vm.stopSelecting()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                        }
                    }
                    .padding(10)
                    .padding(.trailing, 5)
                }
            }
            .blurBackground(opacity: 0.1)
            .dismissible(edge: .bottom) {
                vm.stopSelecting()
            }
            .padding(10)
        }
    }
}

struct SelectBar_Previews: PreviewProvider {
    static var previews: some View {
        SelectBar()
            .environmentObject(ViewModel())
    }
}
