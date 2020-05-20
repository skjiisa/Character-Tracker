//
//  PhoneConnectivityProvider.swift
//  Character Tracker Watch Extension
//
//  Created by Isaac Lyons on 4/22/20.
//  Copyright © 2020 Isaac Lyons. All rights reserved.
//

import WatchConnectivity

protocol PhoneConnectivityProviderDelegate {
    func refresh()
}

final class PhoneConnectivityProvider: NSObject {
    
    //MARK: Properties
    
    private let session: WCSession
    private let decoder = JSONDecoder()
    
    var delegate: PhoneConnectivityProviderDelegate?
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        session.delegate = self
    }
    
    //MARK: Managing connection
    
    func connect() {
        guard WCSession.isSupported() else {
            return NSLog("Phone session is not supported")
        }
        
        print("Activating phone session")
        session.activate()
    }
    
    //MARK: Sending data to watch
    
    func refreshAllCharacters(completion: @escaping ([CharacterRepresentation]?) -> Void) {
        guard session.activationState == .activated else {
            return NSLog("Session is not active")
        }
        
        print("Requesting characters from phone")
        let message = [WatchCommunication.requestKey: WatchCommunication.Content.allCharacters.rawValue]
        session.sendMessage(message, replyHandler: { (payload: [String : Any]) in
            guard let charactersDictionary = payload[WatchCommunication.responseKey] as? [[String: Any]] else { return NSLog("Could not decode response") }
            print("Received \(charactersDictionary.count) characters")
            
            do {
                let data = try JSONSerialization.data(withJSONObject: charactersDictionary, options: .fragmentsAllowed)
                let characters = try self.decoder.decode([CharacterRepresentation].self, from: data)
                
                DispatchQueue.main.async {
                    completion(characters)
                }
            } catch {
                NSLog("\(error)")
                completion(nil)
            }
        }) { error in
            NSLog("\(error)")
        }
    }
    
}

//MARK: Watch Connectivity session delegate

extension PhoneConnectivityProvider: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation complete")
        delegate?.refresh()
    }
}
