//
//  NFCNDEFDelegate.swift
//  NFC
//
//  Created by dev@iotize.com on 05/08/2019.
//  Copyright © 2019 dev@iotize.com. All rights reserved.
//

import Foundation
import CoreNFC

class NFCNDEFDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?
    var completed: ([AnyHashable : Any]?, Error?) -> ()
    var textToWrite: String?
    
    init(completed: @escaping ([AnyHashable: Any]?, Error?) -> (), message: String?, textToWrite: String) {
        self.completed = completed
        self.textToWrite = textToWrite;
        super.init()
        initialize(completed: completed, message: message);
    }
    
    init(completed: @escaping ([AnyHashable: Any]?, Error?) -> (), message: String?) {
        self.completed = completed
        super.init()
        initialize(completed: completed, message: message);
    }
    
    func initialize(completed: @escaping ([AnyHashable: Any]?, Error?) -> (), message: String?){
        
        self.session = NFCNDEFReaderSession.init(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        if (self.session == nil) {
            self.completed(nil, "NFC is not available" as? Error);
            return
        }
        self.session!.alertMessage = message ?? ""
        self.session!.begin()
    }
    
    @available(iOS 13.0, *)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if (textToWrite == ""){
            return;
        }
        // 1
           guard tags.count == 1 else {
               session.invalidate(errorMessage: "Can not write to more than one tag.")
               return
           }
           let currentTag = tags.first!
           
           // 2
           session.connect(to: currentTag) { error in
               
               guard error == nil else {
                   session.invalidate(errorMessage: "Could not connect to tag.")
                   return
               }
               
               // 3
               currentTag.queryNDEFStatus { status, capacity, error in
                   
                   guard error == nil else {
                       session.invalidate(errorMessage: "Could not query status of tag.")
                       return
                   }
                   
                   switch status {
                   case .notSupported: session.invalidate(errorMessage: "Tag is not supported.")
                   case .readOnly:     session.invalidate(errorMessage: "Tag is only readable.")
                   case .readWrite:

                    // 2
                    let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
                        string: self.textToWrite ?? "no value passed",
                        locale: Locale.init(identifier: "en")
                    )!
                    
                    let messge = NFCNDEFMessage.init(
                        records: [
                            textPayload
                        ]
                    )
                       // 4
                       currentTag.writeNDEF(messge) { error in
                           
                           if error != nil {
                               session.invalidate(errorMessage: "Failed to write message.")
                           } else {
                               session.alertMessage = "Successfully wrote data to tag!"
                               session.invalidate()
                           }
                       }
                       
                   @unknown default:   session.invalidate(errorMessage: "Unknown status of tag.")
                   }
               }
           }
    }
    
    func readerSession(_: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            self.fireNdefEvent(message: message)
        }
        self.session?.invalidate()
    }
    
    func readerSession(_: NFCNDEFReaderSession, didInvalidateWithError _: Error) {
        completed(nil, "NFCNDEFReaderSession error" as? Error)
    }
    
    func readerSessionDidBecomeActive(_: NFCNDEFReaderSession) {
        print("NDEF Reader session active")
    }
    
    func fireNdefEvent(message: NFCNDEFMessage) {
        let response = message.ndefMessageToJSON()
        completed(response, nil)
    }
    
    
    
}

extension NFCNDEFMessage {
    func ndefMessageToJSON() -> [AnyHashable: Any] {
        let array = NSMutableArray()
        for record in self.records {
            let recordDictionary = self.ndefToNSDictionary(record: record)
            array.add(recordDictionary)
        }
        let wrapper = NSMutableDictionary()
        wrapper.setObject(array, forKey: "ndefMessage" as NSString)
        
        let returnedJSON = NSMutableDictionary()
        returnedJSON.setValue("ndef", forKey: "type")
        returnedJSON.setObject(wrapper, forKey: "tag" as NSString)

        return returnedJSON as! [AnyHashable : Any]
    }
    
    func ndefToNSDictionary(record: NFCNDEFPayload) -> NSDictionary {
        let dict = NSMutableDictionary()
        dict.setObject([record.typeNameFormat.rawValue], forKey: "tnf" as NSString)
        dict.setObject([UInt8](record.type), forKey: "type" as NSString)
        dict.setObject([UInt8](record.identifier), forKey: "id" as NSString)
        dict.setObject([UInt8](record.payload), forKey: "payload" as NSString)
        
        return dict
    }
}
