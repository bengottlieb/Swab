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
		var fieldsToLoad = fields.subtract(self.loadedFields)
		if fieldsToLoad.count == 0 || self.ref == nil { return }
		
		for field in fieldsToLoad { self.loadField(field) }
		
		self.loadedFields.unionInPlace(fieldsToLoad)
		self.isLoaded = true
	}
	
	var loadedFields = Set<ABPropertyID>()
	
	func loadField(field: ABPropertyID) {
		switch (field) {
		case kABPersonImageProperty: if let imageData = ABPersonCopyImageDataWithFormat(self.ref, kABPersonImageFormatOriginalSize)?.takeRetainedValue() as? NSData { self.image = UIImage(data: imageData) }
			
		case kABPersonFirstNameProperty: self.firstName = self.copyStringProperty(kABPersonFirstNameProperty) ?? ""
		case kABPersonLastNameProperty: self.lastName = self.copyStringProperty(kABPersonLastNameProperty) ?? ""
		case kABPersonMiddleNameProperty: self.middleName = self.copyStringProperty(kABPersonMiddleNameProperty) ?? ""
		case kABPersonOrganizationProperty: self.companyName = self.copyStringProperty(kABPersonOrganizationProperty) ?? ""
		case kABPersonJobTitleProperty: self.title = self.copyStringProperty(kABPersonJobTitleProperty) ?? ""
		case kABPersonDepartmentProperty: self.department = self.copyStringProperty(kABPersonDepartmentProperty) ?? ""
		case kABPersonNoteProperty: self.notes = self.copyStringProperty(kABPersonNoteProperty) ?? ""
			
		case kABPersonBirthdayProperty: self.birthday = self.copyDateProperty(kABPersonBirthdayProperty)
			
		case kABPersonPhoneProperty: self.phoneNumbers = SwabRecordPhoneNumber.loadMultiplesFrom(self.ref!) as? [SwabRecordPhoneNumber] ?? []
		case kABPersonEmailProperty: self.emailAddresses = SwabRecordEmailAddress.loadMultiplesFrom(self.ref!) as? [SwabRecordEmailAddress] ?? []
		case kABPersonURLProperty: self.URLs = SwabRecordURL.loadMultiplesFrom(self.ref!) as? [SwabRecordURL] ?? []
		case kABPersonInstantMessageProperty: self.IMServices = SwabRecordIMService.loadMultiplesFrom(self.ref!) as? [SwabRecordIMService] ?? []
		case kABPersonSocialProfileProperty: self.socialNetworks = SwabRecordSocialNetwork.loadMultiplesFrom(self.ref!) as? [SwabRecordSocialNetwork] ?? []
		case kABPersonAddressProperty: self.streetAddresses = SwabRecordStreetAddress.loadMultiplesFrom(self.ref!) as? [SwabRecordStreetAddress] ?? []
		default: break
		}
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