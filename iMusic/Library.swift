//
//  Library.swift
//  iMusic
//
//  Created by MacBookPro on 01.03.2021.
//

import SwiftUI
import URLImage

struct Library: View {
    
    @State var tracks = UserDefaults.standard.savedTracks()
    @State private var showingAlert = false
    @State private var track: SearchViewModel.Cell!
    
    var tabBardelegate: MainTabBarControllerDelegate?
    
    var body: some View {
        NavigationView {
            
            VStack(spacing: 20) {
                GeometryReader { geometry in
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            self.track = self.tracks[0]
                            self.tabBardelegate?.maximizedTrackDetailController(viewModel: self.track)
                        }, label: {
                            Image(systemName: "play.fill")
                                .frame(width: geometry.size.width / 2 - 10, height: 50)
                                .accentColor(Color.init(#colorLiteral(red: 1, green: 0.1769100455, blue: 0.6213266765, alpha: 1)))
                                .background(Color(#colorLiteral(red: 0.900646807, green: 0.900646807, blue: 0.900646807, alpha: 1)))
                                .cornerRadius(10)
                        })
                        Button(action: {
                            self.tracks = UserDefaults.standard.savedTracks()
                        }, label: {
                            Image(systemName: "arrow.2.circlepath")
                                .frame(width: geometry.size.width / 2 - 10, height: 50)
                                .accentColor(Color.init(#colorLiteral(red: 1, green: 0.1769100455, blue: 0.6213266765, alpha: 1)))
                                .background(Color(#colorLiteral(red: 0.900646807, green: 0.900646807, blue: 0.900646807, alpha: 1)))
                                .cornerRadius(10)
                        })
                    }
                    
                }.padding().frame(height: 50)
                
                Divider().padding(.leading).padding(.trailing)
                //Spacer()
                
                List {
                    ForEach(tracks) { track in
                        LibraryCell(cell: track)
                            .gesture(LongPressGesture().onEnded({ _ in
                                print("pressed")
                                self.track = track
                                self.showingAlert = true
                            })
                            .simultaneously(with: TapGesture()
                                                .onEnded { _ in
                                                    let keyWindow = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive
                                                    }).map({ $0 as? UIWindowScene }).compactMap({ $0
                                                    }).first?.windows.filter({ $0.isKeyWindow}).first
                                                    let tabBarVC = keyWindow?.rootViewController as? MainTabBarController
                                                    tabBarVC?.trackDetailView.delegate = self
                                                    self.track = track
                                                    self.tabBardelegate?.maximizedTrackDetailController(viewModel: self.track)
                                                }))
                    }
                    .onDelete(perform: delete)
                }
            }.actionSheet(isPresented: $showingAlert, content: { ActionSheet(title: Text("Are you sure you want to delete this track?"), buttons: [.destructive(Text("Delete"), action: {
                print("deleting: \(self.track.trackName)")
                self.delete(track: self.track)
            }), .cancel()
            ])
            
            })
            
            .navigationBarTitle("Library")
        }
        
    }
    func delete(at ofsets: IndexSet) {
        tracks.remove(atOffsets: ofsets)
        if let saveData = try? NSKeyedArchiver.archivedData(withRootObject: tracks, requiringSecureCoding: false) {
            let defaults = UserDefaults.standard
            defaults.set(saveData, forKey: UserDefaults.favouriteTrackKey)
        }
    }
    func delete(track: SearchViewModel.Cell) {
        let index = tracks.firstIndex(of: track)
        guard let myIndex = index else { return }
        tracks.remove(at: myIndex)
        if let saveData = try? NSKeyedArchiver.archivedData(withRootObject: tracks, requiringSecureCoding: false) {
            let defaults = UserDefaults.standard
            defaults.set(saveData, forKey: UserDefaults.favouriteTrackKey)
        }
    }
    
}

struct LibraryCell: View {
    var cell: SearchViewModel.Cell
    var body: some View {
        HStack {
            
            
            
            URLImage(url: URL(string: cell.iconUrlString ?? "")!) { image in
                image
                    .resizable()
                    .frame(width: 60, height: 60)
                    .cornerRadius(2)
            }
            
            VStack(alignment: .leading) {
                Text("\(cell.trackName)")
                Text("\(cell.artistName)")
            }
        }
    }
    
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}

extension Library: TrackMovingDelegate {
    func moveBackForPreviousTrack() -> SearchViewModel.Cell? {
        let index = tracks.firstIndex(of: track)
        guard let myIndex = index else { return nil }
        var nextTrack: SearchViewModel.Cell
        if myIndex - 1 == -1 {
            nextTrack = tracks[tracks.count - 1]
        } else {
            nextTrack = tracks[myIndex - 1]
            
        }
        self.track = nextTrack
        return nextTrack
    }
    
    func moveForwardForPreviousTrack() -> SearchViewModel.Cell? {
        let index = tracks.firstIndex(of: track)
        guard let myIndex = index else { return nil }
        var nextTrack: SearchViewModel.Cell
        if myIndex + 1 == tracks.count {
            nextTrack = tracks[0]
        } else {
            nextTrack = tracks[myIndex + 1]
            
        }
        self.track = nextTrack
        return nextTrack
    }
    
    
}
