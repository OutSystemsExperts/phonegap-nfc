//
//  NFCNDEFDelegate.swift
//  NFC
//
//  Created by dev@iotize.com on 05/08/2019.
//  Copyright © 2019 dev@iotize.com. All rights reserved.
//

import Foundation
import CoreNFC

class NFCNDEFWriterDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    
    
    var session: NFCNDEFReaderSession?
    var completed: ([AnyHashable : Any]?, Error?) -> ()
    var textToWrite: String
    
    init(completed: @escaping ([AnyHashable: Any]?, Error?) -> (), message: String?, textToWrite: String) {
        self.completed = completed
        self.textToWrite = textToWrite;
        super.init()
        
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
        if (self.textToWrite == ""){
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
                /*let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
                    string: "no value passed",
                    locale: Locale.init(identifier: "en")
                )!*/
                
                var payloadData = Data([0x02,0x65,0x6E]) // 0x02 + 'en' = Locale Specifier
                payloadData.append(self.textToWrite.data(using: .utf8)!)
                
                let payload = NFCNDEFPayload.init(
                    format: NFCTypeNameFormat.nfcWellKnown,
                    type: "T".data(using: .utf8)!,
                    identifier: Data.init(count: 0),
                    payload: payloadData,
                    chunkSize: 0
                )
                
                let messge = NFCNDEFMessage.init(
                    records: [
                        payload
                    ]
                )
               // 4
               currentTag.writeNDEF(messge) { error in
                   
                   if error != nil {
                        self.completed(nil, "Failed to write message" as? Error)
                        session.invalidate(errorMessage: "Failed to write message.")
                   } else {
                        self.completed(nil, nil)
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
        //do nothing
    }
    
    func readerSession(_: NFCNDEFReaderSession, didInvalidateWithError _: Error) {
        completed(nil, "NFCNDEFReaderSession error" as? Error)
    }
    
    func readerSessionDidBecomeActive(_: NFCNDEFReaderSession) {
        print("NDEF Reader session active")
    }
}
