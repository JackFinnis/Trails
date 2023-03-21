//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var showShareSheet = false
    
    let welcome: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 10) {
                    Image("my_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .cornerRadius(15)
                    Text(NAME)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                }
                .horizontallyCentred()
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 15) {
                    InfoRow(systemName: "map", title: "The Trails", description: "Browse 45 of the most spectacular long-distance trails in the UK.")
                    InfoRow(systemName: "magnifyingglass", title: "Search Maps", description: "Find B&Bs, cafés, shops & more along your route.")
                    InfoRow(systemName: "checkmark.circle", title: "Track Your Progress", description: "Mark sections of a trail as complete.")
                    InfoRow(systemName: "point.topleft.down.curvedto.point.bottomright.up", title: "Select a Trail Section", description: "Measure the length of your next trip.")
                    HStack {
                        Image(systemName: "ruler")
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Distance Unit")
                                .font(.headline)
                            Picker("", selection: $vm.metric) {
                                Text("Kilometres")
                                    .tag(true)
                                Text("Miles")
                                    .tag(false)
                            }
                            .frame(width: 250)
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                }
                
                Spacer()
                if welcome {
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .bigButton()
                    }
                } else {
                    Menu {
                        Button {
                            Emails.compose(subject: "\(NAME) Feedback")
                        } label: {
                            Label("Send us Feedback", systemImage: "envelope")
                        }
                        Button {
                            Store.writeReview()
                        } label: {
                            Label("Write a Review", systemImage: "quote.bubble")
                        }
                        Button {
                            Store.requestRating()
                        } label: {
                            Label("Rate \(NAME)", systemImage: "star")
                        }
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share with a Friend", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Text("Contribute...")
                            .bigButton()
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !welcome {
                        Button {
                            dismiss()
                        } label: {
                            DismissCross()
                        }
                        .buttonStyle(.plain)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if !welcome {
                        DraggableBar()
                    }
                }
            }
        }
        .shareSheet(url: APP_URL, isPresented: $showShareSheet)
        .interactiveDismissDisabled(welcome)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                InfoView(welcome: false)
                    .environmentObject(ViewModel())
            }
    }
}

struct InfoRow: View {
    let systemName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
