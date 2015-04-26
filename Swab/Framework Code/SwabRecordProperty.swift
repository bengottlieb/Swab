//
//  SwabRecordProperty.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/25/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import AddressBook

public class SwabRecordProperty: NSObject {
	var label: String = ""
	var prettyLabel: String = ""
	var record: SwabRecord?
	class var propertyID: ABPropertyID { return kABPersonPhoneProperty }
	init(label labelString: String) {
		super.init()
		self.label = labelString
	}
	
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		record = inRecord
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
}

public class SwabRecordPhoneNumber: SwabRecordProperty {
	var number: NSString = ""
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
}

public class SwabRecordEmailAddress: SwabRecordProperty {
	var email: NSString = ""
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
}

public class SwabRecordURL: SwabRecordProperty {
	var url: NSString = ""
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
}

public class SwabRecordIMService: SwabRecordProperty {
	var service: NSString = ""
	var username: NSString = ""
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
}

public class SwabRecordSocialNetwork: SwabRecordIMService {
	override class var propertyID: ABPropertyID { return kABPersonSocialProfileProperty }
	
	public required init(index: Int, ofProperty: ABMultiValueRef, inRecord: SwabRecord) {
		super.init(index: index, ofProperty: ofProperty, inRecord: inRecord)
	}
}


public class SwabRecordStreetAddress: SwabRecordProperty {
	var street = ""
	var city = ""
	var state = ""
	var postalCode = ""
	var country = ""
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
}

