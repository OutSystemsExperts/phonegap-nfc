//
//  Utils.swift
//
//  Created by André Gonçalves on 13/04/2020.
//

import Foundation
import CoreNFC

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
        dict.setObject(record.typeNameFormat.rawValue, forKey: "tnf" as NSString)
        dict.setObject([UInt8](record.type), forKey: "type" as NSString)
        dict.setObject([UInt8](record.identifier), forKey: "id" as NSString)
        dict.setObject([UInt8](record.payload), forKey: "payload" as NSString)
        
        return dict
    }
}

@available(iOS 13.0, *)
func jsonToNdefRecords(ndefMessage: NSDictionary) -> NFCNDEFPayload{
    var id = ndefMessage.object(forKey: "id")
    let tnf = ndefMessage.object(forKey: "tnf") as! UInt8
    let payload2 = ndefMessage.object(forKey: "payload") as! NSArray
    let type = ndefMessage.object(forKey: "type") as! NSArray
    var dataType = Data.init();
    dataType.append(contentsOf: type as! [UInt8])
    var dataPayload = Data.init()
    dataPayload.append(contentsOf: payload2 as! [UInt8])
    let message = NFCNDEFPayload.init(
        format: NFCTypeNameFormat.init(rawValue: tnf)!,
        //type: "T".data(using: .utf8)!,
        type: dataType,
        identifier: Data.init(count: 0),
        payload: dataPayload,
        chunkSize: 0)
    
    return message;
}
