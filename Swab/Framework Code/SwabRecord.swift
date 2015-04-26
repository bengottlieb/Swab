//
//  SwabRecord.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/25/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import AddressBook

public let kABPersonImageProperty: ABPropertyID = 50411

public class SwabRecord: NSObject {
	static  var allProperties = Set([kABPersonFirstNameProperty, kABPersonMiddleNameProperty, kABPersonLastNameProperty, kABPersonOrganizationProperty, kABPersonJobTitleProperty, kABPersonDepartmentProperty, kABPersonNoteProperty, kABPersonBirthdayProperty, kABPersonPhoneProperty, kABPersonEmailProperty, kABPersonURLProperty, kABPersonInstantMessageProperty, kABPersonSocialProfileProperty, kABPersonAddressProperty, kABPersonImageProperty])
	
	var ref: ABRecord?
	
	var firstName = "", middleName = "", lastName = ""
	var companyName = "", title = "", department = "", notes = ""
	var birthday: NSDate?
	var image: UIImage?
	
	var phoneNumbers: [SwabRecordPhoneNumber] = []
	var emailAddresses: [SwabRecordEmailAddress] = []
	var URLs: [SwabRecordURL] = []
	var IMServices: [SwabRecordIMService] = []
	var socialNetworks: [SwabRecordSocialNetwork] = []
	var streetAddresses: [SwabRecordStreetAddress] = []
	
	var isLoaded = false
	
	//=============================================================================================
	//MARK: Loading
	func load(fields: Set<ABPropertyID> = SwabRecord.allProperties) {
		if self.isLoaded || self.ref == nil { return }
		
		var all = fields == SwabRecord.allProperties
		if all || contains(fields, kABPersonImageProperty) { if let imageData = ABPersonCopyImageDataWithFormat(self.ref, kABPersonImageFormatOriginalSize)?.takeRetainedValue() as? NSData { self.image = UIImage(data: imageData) } }
		
		if all || contains(fields, kABPersonFirstNameProperty) { self.firstName = self.copyStringProperty(kABPersonFirstNameProperty) ?? "" }
		if all || contains(fields, kABPersonLastNameProperty) { self.lastName = self.copyStringProperty(kABPersonLastNameProperty) ?? "" }
		if all || contains(fields, kABPersonMiddleNameProperty) { self.middleName = self.copyStringProperty(kABPersonMiddleNameProperty) ?? "" }
		if all || contains(fields, kABPersonOrganizationProperty) { self.companyName = self.copyStringProperty(kABPersonOrganizationProperty) ?? "" }
		if all || contains(fields, kABPersonJobTitleProperty) { self.title = self.copyStringProperty(kABPersonJobTitleProperty) ?? "" }
		if all || contains(fields, kABPersonDepartmentProperty) { self.department = self.copyStringProperty(kABPersonDepartmentProperty) ?? "" }
		if all || contains(fields, kABPersonNoteProperty) { self.notes = self.copyStringProperty(kABPersonNoteProperty) ?? "" }
		
		if all || contains(fields, kABPersonBirthdayProperty) { self.birthday = self.copyDateProperty(kABPersonBirthdayProperty) }
		
		if all || contains(fields, kABPersonPhoneProperty) { self.phoneNumbers = SwabRecordPhoneNumber.loadMultiplesFrom(self.ref!) as? [SwabRecordPhoneNumber] ?? [] }
		if all || contains(fields, kABPersonEmailProperty) { self.emailAddresses = SwabRecordEmailAddress.loadMultiplesFrom(self.ref!) as? [SwabRecordEmailAddress] ?? [] }
		if all || contains(fields, kABPersonURLProperty) { self.URLs = SwabRecordURL.loadMultiplesFrom(self.ref!) as? [SwabRecordURL] ?? [] }
		if all || contains(fields, kABPersonInstantMessageProperty) { self.IMServices = SwabRecordIMService.loadMultiplesFrom(self.ref!) as? [SwabRecordIMService] ?? [] }
		if all || contains(fields, kABPersonSocialProfileProperty) { self.socialNetworks = SwabRecordSocialNetwork.loadMultiplesFrom(self.ref!) as? [SwabRecordSocialNetwork] ?? [] }
		if all || contains(fields, kABPersonAddressProperty) { self.streetAddresses = SwabRecordStreetAddress.loadMultiplesFrom(self.ref!) as? [SwabRecordStreetAddress] ?? [] }
		
		self.isLoaded = true
	}
	
	func copyStringProperty(property: ABPropertyID) -> String? {
		return ABRecordCopyValue(self.ref, property)?.takeRetainedValue() as? String
	}
	
	func copyDateProperty(property: ABPropertyID) -> NSDate? {
		return ABRecordCopyValue(self.ref, property)?.takeRetainedValue() as? NSDate
	}
	
	
	
	public override var description: String {
		self.load()
		
		return "\(self.firstName) \(self.lastName), (\(self.companyName)) "
	}
}