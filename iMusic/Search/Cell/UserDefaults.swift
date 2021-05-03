//
//  UserDefaults.swift
//  iMusic
//
//  Created by MacBookPro on 02.03.2021.
//

import Foundation

extension UserDefaults {
    
    static let favouriteTrackKey = "avouriteTrackKey"
    
    func savedTracks() -> [SearchViewModel.Cell] {
        
        let defaults = UserDefaults.standard
        
        guard let savedTracks = defaults.object(forKey: UserDefaults.favouriteTrackKey) as? Data else { return [] }
        guard let decodeTracks = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedTracks) as? [SearchViewModel.Cell] else { return [] }
        
        return decodeTracks
    }
    
}
