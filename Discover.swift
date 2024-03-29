//
//  Discover.swift
//  Cusp
//
//  Created by keyOfVv on 2/15/16.
//  Copyright © 2016 com.keyang. All rights reserved.
//

import Foundation

// MARK: ServiceDiscoveringRequest

/// request of discovering services of specific peripheral
internal class ServiceDiscoveringRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// UUID array of service to be discovered
	internal var serviceUUIDs: [UUID]?

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter serviceUUIDs: UUID array of service to be discovered, all services will be discovered if passed nil
	- parameter peripheral:   a CBPeripheral instance of which the services to be discovered
	- parameter success:      a closure called when discovering succeed
	- parameter failure:      a closure called when discovering failed

	- returns: a ServiceDiscoveringRequest instance
	*/
	internal convenience init(serviceUUIDs: [UUID]?, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
        self.serviceUUIDs = serviceUUIDs
        self.success      = success
        self.failure      = failure
	}

	override internal var hash: Int {
		// if service uuid array is nil, return hash value of empty string
		guard let uuids = serviceUUIDs else {
			return "".hashValue
		}
		// sort the uuids
		let array = uuids.sort { (a, b) -> Bool in
			return a.UUIDString <= b.UUIDString
		}
		// assemble uuid strings
		var string = ""
		for uuid in array {
			string += uuid.UUIDString
		}
		return string.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? ServiceDiscoveringRequest {
			return hashValue == other.hashValue
		}
		return false
	}
}

// MARK: CharacteristicDiscoveringRequest

/// request of discovering characteristics of specific service
internal class CharacteristicDiscoveringRequest: PeripheralOperationRequest {

	// MARK: Stored Properties

	/// UUID array of characteristic to be discovered
	internal var characteristicUUIDs: [UUID]?

	/// a CBService object of which the characteristics to be discovered
	internal var service: Service!

	// MARK: Initializer

	private override init() {
		super.init()
	}

	/**
	Convenient initializer

	- parameter characteristicUUIDs: UUID array of characteristic to be discovered
	- parameter service:             a CBService object of which the characteristics to be discovered
	- parameter peripheral:          a CBPeripheral instance of which the characteristics to be discovered
	- parameter success:             a closure called when discovering succeed
	- parameter failure:             a closure called when discovering failed

	- returns: a CharacteristicDiscoveringRequest instance
	*/
	internal convenience init(characteristicUUIDs: [UUID]?, service: Service, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		self.init()
        self.characteristicUUIDs = characteristicUUIDs
        self.service             = service
        self.success             = success
        self.failure             = failure
	}

	override internal var hash: Int {
		// if characteristic uuid array is nil, return hash value of service uuid
		guard let uuids = characteristicUUIDs else {
			return service.UUID.hashValue
		}
		// sort the uuids
		let array = uuids.sort { (a, b) -> Bool in
			return a.UUIDString <= b.UUIDString
		}
		// assemble uuid strings
		var string = service.UUID.UUIDString
		for uuid in array {
			string += uuid.UUIDString
		}
		return string.hashValue
	}

	override internal func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? CharacteristicDiscoveringRequest {
			return hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - Discovering service/characteristic
extension Peripheral {
	/**
	Discover specific or all services of a peripheral.
	发现从设备的部分或全部服务.

	- parameter serviceUUIDs: an UUID array of services to be discovered, all services will be discovered if passed nil. 服务UUID数组, 传nil则扫描所有服务.
	- parameter success:      a closure called when discovering succeed. 发现服务成功的闭包.
	- parameter failure:      a closure called when discovering failed. 发现服务失败的闭包.
	*/
	public func discover(serviceUUIDs: [UUID]?, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create request object
		let req = ServiceDiscoveringRequest(serviceUUIDs: serviceUUIDs, success: success, failure: failure)
		// 2. add request
		dispatch_async(requestQ, { () -> Void in
			self.serviceDiscoveringRequests.insert(req)
		})
		// 3. start discovering service(s)
		dispatch_async(operationQ, { () -> Void in
			self.core.discoverServices(serviceUUIDs)
		})
		// 4. set time out closure
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), operationQ) { () -> Void in
			if req.timedOut {
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					let error = NSError(domain: "connect operation timed out", code: Cusp.Error.TimedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				// since req timed out, don't need it any more...
				dispatch_async(self.requestQ, { () -> Void in
					self.serviceDiscoveringRequests.remove(req)
				})
			}
		}
	}

	/**
	Discover specific or all characteristics of a peripheral's specific service.
	发现从设备某项服务的部分或全部特征.

	- parameter characteristicUUIDs: an UUID array of characteristics to be discovered, all characteristics will be discovered if passed nil. 特征UUID数组, 传nil则扫描所有特征;
	- parameter service:             a CBService object of which the characteristics to be discovered. 待发现特征的服务.
	- parameter success:             a closure called when discovering succeed. 发现特征成功的闭包.
	- parameter failure:             a closure called when discovering failed. 发现特征失败的闭包.
	*/
	public func discover(characteristicUUIDs: [UUID]?, ofService service: Service, success: ((Response?) -> Void)?, failure: ((NSError?) -> Void)?) {
		// 0. check if ble is available
		if let error = Cusp.central.assertAvailability() {
			failure?(error)
			return
		}
		// 1. create request object
		let req = CharacteristicDiscoveringRequest(characteristicUUIDs: characteristicUUIDs, service: service, success: success, failure: failure)
		// 2. add request
		dispatch_async(requestQ, { () -> Void in
			self.characteristicDiscoveringRequests.insert(req)
		})
		// 3. start discovering characteristic(s)
		dispatch_async(operationQ, { () -> Void in
			self.core.discoverCharacteristics(characteristicUUIDs, forService: service)
		})
		// 4. set time out closure
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(req.timeoutPeriod * Double(NSEC_PER_SEC))), operationQ) { () -> Void in
			if req.timedOut {
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					let error = NSError(domain: "connect operation timed out", code: Cusp.Error.TimedOut.rawValue, userInfo: nil)
					failure?(error)
				})
				// since req timed out, don't need it any more
				dispatch_async(self.requestQ, { () -> Void in
					self.characteristicDiscoveringRequests.remove(req)
				})
			}
		}
	}

	/**
	check if services of specific UUID(s) discovered already

	- parameter uuids: an array of service UUID

	- returns: return true if every service of specific UUID(s) discovered already, otherwise false
	*/
	func areServicesAvailable(uuids uuids: [UUID]) -> Bool {
		for uuid in uuids {
			if let _ = core.serviceWith(UUIDString: uuid.UUIDString) {
				continue
			}
			return false
		}
		return true
	}

	/**
	check if services of specific UUID string(s) discovered

	- parameter uuidStrings: an array of service UUID string

	- returns: return true if every service of specific UUID string(s) discovered already, otherwise false
	*/
	func areServicesAvailable(uuidStrings uuidStrings: [String]) -> Bool {
		for string in uuidStrings {
			if let _ = core.serviceWith(UUIDString: string) {
				continue
			}
			return false
		}
		return true
	}

	/**
	check if characteristic of specific UUID(s) discovered already

	- parameter uuids: an array of characteristic UUID

	- returns: return true if every characteristic of specific UUID(s) discovered already, otherwise false
	*/
	func areCharacteristicsAvailable(uuids uuids: [UUID]) -> Bool {
		for uuid in uuids {
			if let _ = core.characteristicWith(UUIDString: uuid.UUIDString) {
				continue
			}
			return false
		}
		return true
	}

	/**
	check if characteristic of specific UUID string(s) discovered already

	- parameter uuidStrings: an array of characteristic UUID string

	- returns: return true if every characteristic of specific UUID string(s) discovered already, otherwise false
	*/
	func areCharacteristicsAvailable(uuidStrings uuidStrings: [String]) -> Bool {
		for string in uuidStrings {
			if let _ = core.characteristicWith(UUIDString: string) {
				continue
			}
			return false
		}
		return true
	}

}





