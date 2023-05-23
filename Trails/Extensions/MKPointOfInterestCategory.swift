//
//  MKPointOfInterestCategory.swift
//  Trails
//
//  Created by Jack Finnis on 22/05/2023.
//

import MapKit
import SwiftUI

extension MKPointOfInterestCategory {
    func supportedIcon160(new: String, old: String) -> String {
        if #available(iOS 16, *) {
            return new
        }
        return old
    }
    
    func supportedIcon161(new: String, old: String) -> String {
        if #available(iOS 16.1, *) {
            return new
        }
        return old
    }
    
    var systemName: String {
        let defaultIcon = "mappin"
        switch self {
        case .airport: return "airplane"
        case .amusementPark: return "ticket.fill"
        case .aquarium: return supportedIcon160(new: "fish.fill", old: "building.columns.fill")
        case .atm: return "creditcard.fill"
        case .bakery: return supportedIcon160(new: "birthday.cake.fill", old: "cart.fill")
        case .bank: return "banknote.fill"
        case .beach: return supportedIcon160(new: "beach.umbrella.fill", old: "drop.fill")
        case .brewery: return supportedIcon161(new: "mug.fill", old: defaultIcon)
        case .cafe: return "cup.and.saucer.fill"
        case .campground: return supportedIcon160(new: "tent.fill", old: defaultIcon)
        case .carRental: return "car.2.fill"
        case .evCharger: return "powerplug.fill"
        case .fireStation: return "flame.fill"
        case .fitnessCenter: return supportedIcon160(new: "dumbbell.fill", old: "sportscourt.fill")
        case .foodMarket: return supportedIcon160(new: "basket.fill", old: "cart.fill")
        case .gasStation: return "fuelpump.fill"
        case .hospital: return "cross.fill"
        case .hotel: return "bed.double.fill"
        case .laundry: return supportedIcon160(new: "washer.fill", old: "tshirt.fill")
        case .library: return "books.vertical.fill"
        case .marina: return supportedIcon160(new: "sailboat.fill", old: "ferry.fill")
        case .movieTheater: return supportedIcon160(new: "popcorn.fill", old: "theatermasks.fill")
        case .museum: return "building.columns.fill"
        case .nationalPark, .park: return supportedIcon161(new: "tree.fill", old: "leaf.fill")
        case .nightlife: return supportedIcon160(new: "figure.dance", old: "music.mic")
        case .parking: return "parkingsign"
        case .pharmacy: return "pills.fill"
        case .police: return "checkerboard.shield"
        case .postOffice: return "mail.fill"
        case .publicTransport: return "tram.fill"
        case .restaurant: return "fork.knife"
        case .restroom: return supportedIcon160(new: "toilet.fill", old: defaultIcon)
        case .school: return "graduationcap.fill"
        case .stadium: return "sportscourt.fill"
        case .store: return "bag.fill"
        case .theater: return "theatermasks.fill"
        case .university: return "graduationcap.fill"
        case .winery: return supportedIcon160(new: "wineglass.fill", old: defaultIcon)
        case .zoo: return supportedIcon160(new: "lizard.fill", old: "tortoise.fill")
        default: return defaultIcon
        }
    }
    
    var color: Color {
        switch self {
        case .bakery, .brewery, .cafe, .restaurant:
            return .orange
        case .foodMarket, .laundry, .store:
            return .yellow
        case .amusementPark, .aquarium, .movieTheater, .museum, .theater, .winery, .zoo, .nightlife:
            return .pink
        case .atm, .bank, .carRental, .police, .postOffice:
            return .gray
        case .airport, .gasStation, .parking, .publicTransport:
            return .blue
        case .fitnessCenter, .beach, .marina:
            return .cyan
        case .campground, .evCharger, .nationalPark, .park, .stadium:
            return .green
        case .fireStation, .hospital, .pharmacy:
            return .red
        case .hotel, .restroom:
            return .purple
        case .library, .school, .university:
            return .brown
        default:
            return .red
        }
    }
}
