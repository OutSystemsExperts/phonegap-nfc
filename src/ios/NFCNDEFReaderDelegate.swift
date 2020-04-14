//
//  NFCNDEFReaderDelegate.swift
//  NFC
//

import Foundation
import CoreNFC

class NFCNDEFReaderDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?
    var completed: ([AnyHashable : Any]?, Error?) -> ()
    
    init(completed: @escaping ([AnyHashable: Any]?, Error?) -> (), message: String?) {
        self.completed = completed
        super.init()
        
        self.session = NFCNDEFReaderSession.init(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        if (self.session == nil) {
            self.completed(nil, "NFC is not available" as? Error);
            return
        }
        self.session!.alertMessage = message ?? ""
        self.session!.begin()
    }
    
    @available(iOS 13.0, *)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if case let NFCTag.miFare(tag) = tags.first!{
            print(tag.identifier);
        }
    }
    
    /*@available(iOS 13.0, *)
    private func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
      if case let NFCTag.miFare(tag) = tags.first! {
        print(tag.identifier as NSData)
      }
    }*/
    
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        /*let foundTags = session.value(forKey: "_tagsRead") as? [AnyHashable]
        let tag = foundTags?[0] as? NSObject
        let uid = tag?.value(forKey: "_tagID") as? Data
        */
        let foundTags = session.value(forKey: "_tagsRead");
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

