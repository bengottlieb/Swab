//
//  SwabRecordProperty.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/25/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import UIKit
import AddressBook

public class SwabRecordProperty: NSObject {
	public var label: String = ""
	public var prettyLabel: String {
		var label = self.label
		if let pretty = ABAddressBookCopyLocalizedLabel(label)?.takeRetainedValue() as? String { return pretty }
		return label
	}
	var record: SwabRecord?
	public var index = -1
	class var propertyID: ABPropertyID { return kABPersonPhoneProperty }
	class var propertyType: ABPropertyType { return ABPropertyType(kABMultiStringPropertyType) }
	init(label labelString: String) {
		super.init()
		self.label = labelString
	}
	
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		record = inRecord
		self.index = index
	}
	
	class func loadMultiplesFrom(record: SwabRecord) -> [SwabRecordProperty] {
		var results: [SwabRecordProperty] = []
		if let properties: ABMultiValueRef = ABRecordCopyValue(record.ref, self.propertyID)?.takeRetainedValue() {
			var count = ABMultiValueGetCount(properties)
			
			for i in 0..<count {
				results.append(self(index: i, ofProperty: properties, inRecord: record))
			}
		}
		
		return results
	}

	func copyMultiLabel(index: Int, ofProperty: ABMultiValueRef) -> String? { return ABMultiValueCopyLabelAtIndex(ofProperty, index)?.takeRetainedValue() as? String }
	func copyMultiValue(index: Int, ofProperty: ABMultiValueRef) -> String? { return ABMultiValueCopyValueAtIndex(ofProperty, index)?.takeRetainedValue() as? String }
	func copyMultiDictionary(index: Int, ofProperty: ABMultiValueRef) -> [NSObject: AnyObject]? { return ABMultiValueCopyValueAtIndex(ofProperty, index)?.takeRetainedValue() as? [NSObject: AnyObject] }
	
	func wasModified() {
		var type = self.dynamicType.propertyID
		self.record?.fieldChanged(type)
	}
	
	func writeToRecord() -> NSError? {
		var mutable: ABMutableMultiValue!
		if let properties: ABMultiValueRef = ABRecordCopyValue(self.record!.ref, self.dynamicType.propertyID)?.takeRetainedValue() {
			mutable = ABMultiValueCreateMutableCopy(properties).takeRetainedValue()
		} else {
			mutable = ABMultiValueCreateMutable(self.dynamicType.propertyType).takeRetainedValue()
		}
		
		if self.index == -1 {
			ABMultiValueAddValueAndLabel(mutable, self.value, self.label, nil)
		} else {
			ABMultiValueReplaceValueAtIndex(mutable, self.value, self.index)
			ABMultiValueReplaceLabelAtIndex(mutable, self.label, self.index)
		}
		
		var error: Unmanaged<CFError>?
		if !ABRecordSetValue(self.record!.ref, self.dynamicType.propertyID, mutable, &error) {
			println("Error saving \(self): \(error)")
		}
		return nil
	}
	
	var value: NSObject? { return nil }
}

public class SwabRecordPhoneNumber: SwabRecordProperty {
	public var number: NSString = ""
	override class var propertyID: ABPropertyID { return kABPersonPhoneProperty }
	init(label: String, number phone: String) {
		super.init(label: label)
		self.number = phone
	}
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
		
		self.label = self.copyMultiLabel(index, ofProperty: ofProperty) ?? ""
		self.number = self.copyMultiValue(index, ofProperty: ofProperty) ?? ""
	}
	override var value: NSObject? { return self.number }
	public override var description: String { return "\(self.label): \(self.number)" }
}

public class SwabRecordEmailAddress: SwabRecordProperty {		//	[_$!<Work>!$_, _$!<Home>!$_, E-mail, _$!<Other>!$_ ]
	public var email: NSString = ""
	override class var propertyID: ABPropertyID { return kABPersonEmailProperty }
	init(label: String, email address: String) {
		super.init(label: label)
		self.email = address
	}
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
		
		self.label = self.copyMultiLabel(index, ofProperty: ofProperty) ?? ""
		self.email = self.copyMultiValue(index, ofProperty: ofProperty) ?? ""
	}
	override var value: NSObject? { return self.email }
	public override var description: String { return "\(self.label): \(self.email)" }
}

public class SwabRecordURL: SwabRecordProperty {
	public var url: NSString = ""
	override class var propertyID: ABPropertyID { return kABPersonURLProperty }
	init(label: String, url address: String) {
		super.init(label: label)
		self.url = address
	}
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
		
		self.label = self.copyMultiLabel(index, ofProperty: ofProperty) ?? ""
		self.url = self.copyMultiValue(index, ofProperty: ofProperty) ?? ""
	}
	override var value: NSObject? { return self.url }
	public override var description: String { return "\(self.label): \(self.url)" }
}

public class SwabRecordIMService: SwabRecordProperty {
	public var service: String = ""
	public var username: String = ""
	override class var propertyID: ABPropertyID { return kABPersonInstantMessageProperty }
	init(label: String, service serviceName: String? = nil, username user: String? = nil) {
		super.init(label: label)
		self.username = user ?? ""
		self.service = serviceName ?? ""
	}
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
		
		self.label = self.copyMultiLabel(index, ofProperty: ofProperty) ?? ""
		if let dict = self.copyMultiDictionary(index, ofProperty: ofProperty) {
			self.username = dict[kABPersonInstantMessageUsernameKey] as? String ?? ""
			self.service = dict[kABPersonInstantMessageServiceKey] as? String ?? ""
		}
	}
	override var value: NSObject? {
		var dict = NSMutableDictionary()
		
		if count(self.username) > 0 { dict[kABPersonInstantMessageUsernameKey as String] = self.username as NSString }
		if count(self.service) > 0 { dict[kABPersonInstantMessageServiceKey as String] = self.service as NSString }
		return dict
	}

	public override var description: String { return "\(self.label): \(self.service); \(self.username)" }
}

public class SwabRecordSocialNetwork: SwabRecordIMService {
	override class var propertyID: ABPropertyID { return kABPersonSocialProfileProperty }
	
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
	}
}


public class SwabRecordStreetAddress: SwabRecordProperty {
	public var street = ""
	public var city = ""
	public var state = ""
	public var postalCode = ""
	public var country = ""
	override class var propertyID: ABPropertyID { return kABPersonAddressProperty }
	
	init(label: String, street sString: String? = nil, city cString: String? = nil, state rString: String? = nil, postalCode zString: String? = nil, country coString: String? = nil) {
		super.init(label: label)
		city = cString ?? ""
		state = rString ?? ""
		street = sString ?? ""
		postalCode = zString ?? ""
		country = coString ?? ""
	}
	
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
		self.label = self.copyMultiLabel(index, ofProperty: ofProperty) ?? ""
		
		if let dict = self.copyMultiDictionary(index, ofProperty: ofProperty) {
			self.city = dict[kABPersonAddressCityKey] as? String ?? ""
			self.state = dict[kABPersonAddressStateKey] as? String ?? ""
			self.postalCode = dict[kABPersonAddressZIPKey] as? String ?? ""
			self.country = dict[kABPersonAddressCountryKey] as? String ?? ""
			self.street = dict[kABPersonAddressStreetKey] as? String ?? ""
		}
	}

	override var value: NSObject? {
		var dict = NSMutableDictionary()
		
		if count(self.street) > 0 { dict[kABPersonAddressStreetKey as String] = self.street as NSString }
		if count(self.city) > 0 { dict[kABPersonAddressCityKey as String] = self.city as NSString }
		return dict
	}
	
	public override var description: String { return "\(self.label): \(self.street) \(self.city) \(self.state) \(self.postalCode) \(self.country)" }
}

