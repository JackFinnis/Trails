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

struct SelectBar_Previews: PreviewProvider {
    static var previews: some View {
        SelectBar()
    }
}
