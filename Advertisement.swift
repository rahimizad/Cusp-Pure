//
//  Advertisement.swift
//  Pods
//
//  Created by Ke Yang on 3/15/16.
//
//

import Foundation

// MARK: - AdvertisementInfo

/// advertisement info after scan.
public class Advertisement: NSObject {

	// MARK: Stored Properties

	/// peripheral 从设备
	public private(set) var peripheral: Peripheral!

	/// advertisement data dictionary 广播信息
	private private(set) var advertisementData: Dictionary<String, AnyObject>!

	/// is peripheral connectable or not
	public var isConnectable: Bool {
		return advertisementData["kCBAdvDataIsConnectable"] as! Bool
	}

	/// a UUID array contains advertising UUID of peripheral
	public var advertisingUUIDs: [UUID]? {
		return advertisementData["kCBAdvDataServiceUUIDs"] as? [UUID]
	}

	/// a UUIDString array contains advertising UUIDStrig of peripheral
	public var advertisingUUIDStrings: [String] {
		var UUIDStrings = [String]()
		if let UUIDs = self.advertisingUUIDs {
			for uuid in UUIDs {
				let UUIDString = uuid.UUIDString
				UUIDStrings.append(UUIDString)
			}
		}
		return UUIDStrings
	}

	/// signal strength 信号强度
	public private(set) var RSSI: NSNumber!

	private override init() {
		super.init()
	}

	internal convenience init(peripheral: Peripheral, advertisementData: Dictionary<String, AnyObject>, RSSI: NSNumber) {
		self.init()
		self.peripheral        = peripheral
		self.advertisementData = advertisementData
		self.RSSI              = RSSI
	}

	public override var hash: Int {
		return self.peripheral.hashValue
	}

	public override func isEqual(object: AnyObject?) -> Bool {
		if let other = object as? Advertisement {
			return self.hashValue == other.hashValue
		}
		return false
	}
}

// MARK: - CustomStringConvertible
extension Advertisement {

	public override var description: String {
		return "\n{\n\t\(peripheral),\n\tadvertisingUUIDs = \(advertisingUUIDStrings),\n\tRSSI = \(RSSI)\n}"
	}
}