//
//  SpeedInput.swift
//  Trails
//
//  Created by Jack Finnis on 28/05/2023.
//

import SwiftUI

struct SpeedInput: View {
    @EnvironmentObject var vm: ViewModel
    @State var newSpeedUnitString = ""
    @FocusState var focused: Bool
    
    var newSpeedUnit: Double? { Double(newSpeedUnitString) }
    
    var body: some View {
        HStack(spacing: 15) {
            Button("Cancel") {
                vm.showSpeedInput = false
            }
            TextField("Speed in \(vm.measurementSystem.speedUnit)", text: $newSpeedUnitString)
                .focused($focused)
                .keyboardType(.decimalPad)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.placeholderText), lineWidth: 1)
                }
            Button("Submit") {
                guard let newSpeedUnit, newSpeedUnit != 0 else { return }
                vm.speedMetres = newSpeedUnit * vm.measurementSystem.metres
                Haptics.tap()
                vm.showSpeedInput = false
            }
            .disabled(newSpeedUnit == nil || newSpeedUnit == 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background {
            RoundedCorners(radius: 10, corners: [.topLeft, .topRight])
                .fill(Color(.systemBackground))
                .ignoresSafeArea()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task {
            focused = true
        }
    }
}

struct SpeedInput_Previews: PreviewProvider {
    static var previews: some View {
        SpeedInput()
    }
}
