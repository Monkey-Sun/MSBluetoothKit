//
//  BlutoothCentral.swift
//  UnionThree
//
//  Created by sun on 2019/9/3.
//  Copyright © 2019 ascleway. All rights reserved.
//

import CoreBluetooth

enum ConnectState {
    case didConnect
    case didFailToConnect
    case didDisconnect
}

class MSBlutoothCentral : NSObject{
    private final var central : CBCentralManager!
    private var peripherals : Array<MSPeripheral> = Array()
    private var currentState : CBManagerState!
    private var timer : Timer?
    private var sleepTimer : Timer?
    private var completeHandle : ((NSError?)->Void)?
    private var connectHandle:((ConnectState, Error?)->Void)?
    private final var  aCentralConfig : MSBluetoothConfig!
    
    var centralStatuUpdateHandle : ((CBManagerState)->Void)!
//    这个属性主要用来决定刷新表格的间隔时间，太短或太长都不合适
    var updateTimeOut : Int!{
        willSet{
           assert(newValue >= 2 && newValue < 10, "updateTimeOut must >= 2 and <10")
            self.updateTimeOut = newValue
        }
    }
    
    var isScanning : Bool{
        return central.isScanning
    }
    
    convenience init(Config config : MSBluetoothConfig) {
        self.init()
        central = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: nil)
        currentState = .unknown
        updateTimeOut = 2
        aCentralConfig = config
    }
    
    deinit {
        interruptScan()
    }
}

// oprarion
extension MSBlutoothCentral{
    /**
     duration : 扫描时间
     */
    func scanDuration(Duration duration:Int,  FindHandle findHandle : @escaping (Array<MSPeripheral>)->Void, CompleteHandle completeHandle : (( NSError?)->Void)?) -> Void {
        doScan(Duration: duration, FindHandle: findHandle, CompleteHandle: completeHandle)
    }
    
    func scanContinuously(Duration duration:Int, Sleep sleep : Int , FindHandle findHandle : @escaping (Array<MSPeripheral>)->Void, CompleteHandle completeHandle : (( NSError?)->Void)?) -> Void {
        sleepTimer = Timer.scheduledTimer(withTimeInterval: Double(sleep + duration), repeats: true, block: { [weak self](timer) in
            self?.doScan(Duration: duration,  FindHandle: findHandle, CompleteHandle: completeHandle)
        })
        RunLoop.current.add(sleepTimer!, forMode: .common)
        sleepTimer?.fire()
    }
    
    private func doScan(Duration duration:Int,  FindHandle findHandle : @escaping (Array<MSPeripheral>)->Void, CompleteHandle completeHandle : (( NSError?)->Void)?) -> Void {
        self.completeHandle = completeHandle
        self.peripherals.removeAll()
        if central.isScanning == false {
            if currentState == .poweredOn{
                self.central!.scanForPeripherals(withServices: nil, options: nil)
                var scanSecend = 0
                var updateTime = 0
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self](timer) in
                    guard self != nil else{ return }
                    scanSecend += 1
                    updateTime += 1
                    if scanSecend >= duration{
                        timer.invalidate()
                        self!.central.stopScan()
                        findHandle(self!.peripherals)
                        self!.completeHandle?(nil)
                    }
                    
                    if updateTime >= self!.updateTimeOut{
                        updateTime = 0
                        findHandle(self!.peripherals)
                    }
                }
                RunLoop.current.add(timer!, forMode: .common)
                timer?.fire()
            }
        }
    }
    
    func connect(Peripheral peripheral:MSPeripheral, Options options:[String : Any]?, ConnectHandle connectHandle : ((ConnectState, Error?)->Void)?) -> Void {
        self.connectHandle = connectHandle
        central.connect(peripheral.rawPeripheral, options: options)
    }
    
    func interruptScan() -> Void {
        sleepTimer?.invalidate()
        timer?.invalidate()
        central.stopScan()
    }
}

extension MSBlutoothCentral : CBCentralManagerDelegate{
    
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        assert(centralStatuUpdateHandle != nil, "centralStatuUpdateHandle can't be nill")
        currentState = central.state
        
        if central.state != .poweredOn {
            interruptScan()
            completeHandle?(NSError(domain: "\(currentState!)", code: currentState.rawValue, userInfo: nil))
        }
        
        centralStatuUpdateHandle!(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        if peripheral.name != nil {
            let findPeripheral = MSPeripheral(Peripheral: peripheral, AdvertisementData: advertisementData, RSSI: RSSI, Config: aCentralConfig)
            if peripherals.contains(findPeripheral)  == false{
                peripherals.append(findPeripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        connectHandle?(ConnectState.didConnect, nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        connectHandle?(ConnectState.didFailToConnect, error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        connectHandle?(ConnectState.didDisconnect, error)
    }
}
