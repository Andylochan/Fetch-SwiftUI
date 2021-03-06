//
//  HomeViewModel.swift
//  Fetch
//
//  Created by Andy Lochan on 6/9/21.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var fetchedEvents: [Event]? = nil
    @Published var events: Set<Int>
    
    let defaults = UserDefaults.standard
    var searchCancellable: AnyCancellable? = nil
    
    init() {
        //Favorites data store
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: "Favorites") {
            let eventData = try? decoder.decode(Set<Int>.self, from: data)
            self.events = eventData ?? []
        } else {
            self.events = []
        }
        
        //Wait 0.6 sec after user is done typing, then fetch
        searchCancellable = $searchQuery
            .removeDuplicates()
            .debounce(for: 0.6, scheduler: RunLoop.main)
            .sink(receiveValue: { str in
                if str == "" {
                    //Reset Data
                    self.fetchedEvents = nil
                }
                else {
                    self.searchEvents()
                }
            })
    }

    func searchEvents() {
        let originalQuery = searchQuery.replacingOccurrences(of: " ", with: "+")
        
        DataHandler.shared.fetchEvents(with: originalQuery) { [unowned self] (result, events) in
            if let res = result {
                self.fetchedEvents = events
                print(res ? "Fetch Success" : "Fetch Error")
            }
        }
    }
}

// MARK:-  Favorites Methods
extension HomeViewModel {
    func getEventIds() -> Set<Int> {
        return self.events
    }
    
    func isEmpty() -> Bool {
        events.count < 1
    }
    
    func contains(_ event: Event) -> Bool {
        events.contains(event.id)
    }
    
    func add(_ event: Event) {
        objectWillChange.send()
        events.insert(event.id)
        save()
    }
    
    func remove(_ event: Event) {
        objectWillChange.send()
        events.remove(event.id)
        save()
    }
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(events) {
            defaults.set(encoded, forKey: "Favorites")
        }
    }
}

// MARK:-  Date Formatter
extension HomeViewModel {
    func formatDate(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        dateFormatter.locale = Locale(identifier: "zzz")
        let convertedDate = dateFormatter.date(from: date)

        guard dateFormatter.date(from: date) != nil else {
            assert(false, "no date from string")
            return ""
        }

        //DAY MONTH DATE, YEAR HOUR:MIN AM/PM
        dateFormatter.dateFormat = "EEEE MMM d, yyyy h:mm a"
        dateFormatter.timeZone = NSTimeZone(name: "EST") as TimeZone?
        let timeStamp = dateFormatter.string(from: convertedDate!)

        return timeStamp
    }
}
