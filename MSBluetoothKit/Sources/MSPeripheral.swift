//
//  MSPeripheral.swift
//  UnionThree
//
//  Created by sun on 2019/9/3.
//  Copyright © 2019 ascleway. All rights reserved.
//

import CoreBluetooth
// NSObject already conforms to Equatable https://stackoverflow.com/questions/37390172/redundant-conformance-of-generic-to-protocol-equatable-in-swift-2-2
class MSPeripheral: NSObject {
    private var updateName:(()->Void)?
    private var rssiHandle:((NSNumber, Error?)->Void)?
    private var readHandle : ((Data?, Error?)->Void)?
    private var completeHandle : (() ->Void)?
    private var peripheralReadyHandle : ((Bool)->Void)!
    final var rawPeripheral : CBPeripheral!
    final var advertisementData : [String : Any]!
    final var rssi : NSNumber!
    private final var  aCentralConfig : MSBluetoothConfig!
    private var characteristicMap : [CBUUID : CBCharacteristic] = [CBUUID : CBCharacteristic]()
    private var descriptorMap : [CBUUID : CBDescriptor] = [CBUUID : CBDescriptor]()
    
    var localName : String? {
        return rawPeripheral.name
    }
    var identifier : UUID{
        return rawPeripheral.identifier
    }
    var state : CBPeripheralState{
        return rawPeripheral.state
    }
    
    convenience init(Peripheral peripheral : CBPeripheral, AdvertisementData advertisementData : [String : Any] , RSSI rssi:NSNumber, Config config : MSBluetoothConfig) {
        self.init()
        self.rawPeripheral = peripheral
        self.rawPeripheral.delegate = self
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.aCentralConfig = config
    }
}

extension MSPeripheral{
    func monitorRSSI(RSSIHandle rssiHandle : @escaping(NSNumber, Error?)->Void) {
        self.rssiHandle = rssiHandle
        rawPeripheral.readRSSI()
    }
/**
     自动扫描服务并根据配置文件读取相应的服务
     According to config auto regist server
     */
    func discoverServices(PeripheralReadyHandle readyHandle:@escaping (Bool)->Void)->Void{
        peripheralReadyHandle = readyHandle
        rawPeripheral.discoverServices(nil)
    }
    
    func sendData(Data data:Data, CharacterUUID characterUUID:String, ReadHandle readHandle:@escaping (Data?, Error?)->Void, Compelete completeHandle :@escaping()->Void) -> Void {
        self.readHandle = readHandle
        self.completeHandle = completeHandle
        let uuid = CBUUID(string: characterUUID)
        let characteristic = characteristicMap[uuid]
        guard characteristic != nil  && rawPeripheral.canSendWriteWithoutResponse else {
            return
        }
        var writeType : CBCharacteristicWriteType!
        switch characteristic!.properties {
        case .writeWithoutResponse:
            writeType = .withoutResponse
            break
        default:
            writeType = .withResponse
            break
        }
        rawPeripheral.writeValue(data, for: characteristic!, type: writeType)
    }
    
    func sendData(Data data:Data, DescriptorUUID descriptorUUID:String, ReadHandle readHandle:@escaping (Data?, Error?)->Void, Compelete completeHandle : @escaping ()->Void) -> Void {
        self.readHandle = readHandle
        self.completeHandle = completeHandle
        let uuid = CBUUID(string: descriptorUUID)
        let descriptor = descriptorMap[uuid]
        guard descriptor != nil  && rawPeripheral.canSendWriteWithoutResponse else {
            return
        }
        rawPeripheral.writeValue(data, for: descriptor!)
    }
    
    func readValue(CharacterUUID cuuid : String, ReadHandle readHandle:@escaping (Data?, Error?)->Void) -> Void {
        self.readHandle = readHandle
        let uuid = CBUUID(string: cuuid)
        let characteristic = characteristicMap[uuid]
        guard characteristic != nil  else {
            return
        }
        rawPeripheral.readValue(for: characteristic!)
    }
    
    func readValue(DescriptorUUID dcuuid : String, ReadHandle readHandle:@escaping (Data?, Error?)->Void) -> Void {
        self.readHandle = readHandle
        let uuid = CBUUID(string: dcuuid)
        let descriptor = descriptorMap[uuid]
        guard descriptor != nil  else {
            return
        }
        rawPeripheral.readValue(for: descriptor!)
    }
}

extension MSPeripheral : CBPeripheralDelegate {

    func peripheralDidUpdateName(_ peripheral: CBPeripheral){
        updateName?()
    }
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?){
        peripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?){
        rssiHandle?(rssi, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        guard peripheral.services != nil else {
            return
        }
        for service in peripheral.services! {
            if aCentralConfig.containService(UUID: service.uuid){
                rawPeripheral.discoverCharacteristics(aCentralConfig.charectersForServiceUUID(UUID: service.uuid), for: service)
            }
        }
    }
    
     func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        guard service.characteristics != nil  else {
            peripheralReadyHandle!(false)
            return
        }
        for characteristic in service.characteristics! {
            peripheral.setNotifyValue(true, for: characteristic)
            peripheral.discoverDescriptors(for: characteristic)
            characteristicMap[characteristic.uuid] = characteristic
        }
        peripheralReadyHandle?(true)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        readHandle?(characteristic.value, error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        print("MSBluetooth write  characteristic : \(characteristic), error : \(error?.localizedDescription ?? "")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        readHandle?(characteristic.value, error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?){
        guard characteristic.descriptors != nil else {
            return
        }
        for descriptor in characteristic.descriptors! {
            descriptorMap[characteristic.uuid] = descriptor
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?){
        self.readHandle?(descriptor.value as? Data, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?){
        print("MSBluetooth write descriptor: \(descriptor), error : \(error?.localizedDescription ?? "")")
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral){
        completeHandle?()
    }
}

extension MSPeripheral {
    override func isEqual(_ object: Any?) -> Bool {
        let another = object as! MSPeripheral
        return self.identifier == another.identifier
    }
}
