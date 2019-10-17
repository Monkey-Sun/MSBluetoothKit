//
//  MSBluetoothConfig.swift
//  UnionThree
//
//  Created by sun on 2019/9/3.
//  Copyright © 2019 ascleway. All rights reserved.
//

import CoreBluetooth

protocol MSBluetoothConfig: NSObjectProtocol {
    /**
     key service uuid
     value  [charecter_uuid]
     */
    func servicesMap() -> [String : Array<String>]
    
    func containService(UUID uuid:CBUUID) -> Bool
    
    func charectersForServiceUUID(UUID uuid : CBUUID) -> [CBUUID]
}

// optional func
extension MSBluetoothConfig {
    /**
     key charecter uuid
     value  [descriptor_uuid]
     */
    func charectersMap() -> [String : Array<String>]{
        return [:]
    }
    
    func containCharecter(UUID uuid:CBUUID) -> Bool{
        return false
    }
    
    func descriptorsForServiceUUID(UUID uuid : CBUUID) -> [CBUUID]{
        return []
    }
}
