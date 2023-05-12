//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI
import MessageUI

struct InfoView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var showShareSheet = false
    @State var showEmailSheet = false
    
    let welcome: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 10) {
                    Image("my_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .continuousRadius(15)
                    Text(NAME)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                }
                .horizontallyCentred()
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 15) {
                    InfoRow(systemName: "map", title: "The Walks", description: "Browse \(vm.trails.count) of the most spectacular long-distance UK walks.")
                    InfoRow(systemName: "magnifyingglass", title: "Search Maps", description: "Find B&Bs, cafés, shops & more along your trip.")
                    InfoRow(systemName: "point.topleft.down.curvedto.point.bottomright.up", title: "Select a Trail Section", description: "Measure the length of your next trip.")
                    InfoRow(systemName: "checkmark.circle", title: "Track Your Progress", description: "Mark sections of a trail as complete.")
                    InfoRow(systemName: "ruler", title: "Distance Unit") {
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
                        if MFMailComposeViewController.canSendMail() {
                            Button {
                                showEmailSheet = true
                            } label: {
                                Label("Send us Feedback", systemImage: "envelope")
                            }
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if welcome {
                        Text("")
                    } else {
                        DraggableTitle()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !welcome {
                        Button {
                            dismiss()
                        } label: {
                            DismissCross(toolbar: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .shareSheet(items: [APP_URL], isPresented: $showShareSheet)
        .emailSheet(recipient: EMAIL, subject: "\(NAME) Feedback", isPresented: $showEmailSheet)
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

struct InfoRow<Content: View>: View {
    let systemName: String
    let title: String
    let content: () -> Content
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                content()
            }
            Spacer(minLength: 0)
        }
    }
    
    init(systemName: String, title: String, content: @escaping () -> Content) {
        self.systemName = systemName
        self.title = title
        self.content = content
    }
    
    init(systemName: String, title: String, description: String) where Content == Text {
        self.systemName = systemName
        self.title = title
        self.content = {
            Text(description)
                .foregroundColor(.secondary)
        }
    }
}
