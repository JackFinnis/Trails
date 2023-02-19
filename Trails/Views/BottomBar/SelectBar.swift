//
//  SelectBar.swift
//  Trails
//
//  Created by Jack Finnis on 19/02/2023.
//

import SwiftUI

struct SelectBar: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Text(vm.showSelectError ? "Tap on a pin to reposition it" : "Tap on the start and end locations")
                .font(.subheadline)
                .padding(.horizontal)
            
            Spacer()
            
            Divider().frame(height: SIZE)
            Button {
                vm.stopSelecting()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: SIZE, height: SIZE)
            }
        }
    }
}

struct SelectBar_Previews: PreviewProvider {
    static var previews: some View {
        SelectBar()
    }
}
