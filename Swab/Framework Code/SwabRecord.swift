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
	
	var firstName = "" { didSet { self.fieldChanged(kABPersonFirstNameProperty) } }
	var middleName = "" { didSet { self.fieldChanged(kABPersonMiddleNameProperty) } }
	var lastName = "" { didSet { self.fieldChanged(kABPersonLastNameProperty) } }
	var companyName = "" { didSet { self.fieldChanged(kABPersonOrganizationProperty) } }
	var title = "" { didSet { self.fieldChanged(kABPersonJobTitleProperty) } }
	var department = "" { didSet { self.fieldChanged(kABPersonDepartmentProperty) } }
	var notes = "" { didSet { self.fieldChanged(kABPersonNoteProperty) } }
	var birthday: NSDate? { didSet { self.fieldChanged(kABPersonBirthdayProperty) } }
	var image: UIImage? { didSet { self.fieldChanged(kABPersonImageProperty) } }
	
	var phoneNumbers: [SwabRecordPhoneNumber] = []
	var emailAddresses: [SwabRecordEmailAddress] = []
	var URLs: [SwabRecordURL] = []
	var IMServices: [SwabRecordIMService] = []
	var socialNetworks: [SwabRecordSocialNetwork] = []
	var streetAddresses: [SwabRecordStreetAddress] = []
	
	//=============================================================================================
	//MARK: Loading
	func load(fields: Set<ABPropertyID> = SwabRecord.allProperties) {
		var fieldsToLoad = fields.subtract(self.loadedFields)
		if fieldsToLoad.count == 0 || self.ref == nil { return }
		
		self.isLoading = true
		for field in fieldsToLoad { self.loadField(field) }
		
		self.loadedFields.unionInPlace(fieldsToLoad)
		self.isLoading = true
	}
	
	var loadedFields = Set<ABPropertyID>()
	var isLoading = false
	
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
			
		case kABPersonPhoneProperty: self.phoneNumbers = SwabRecordPhoneNumber.loadMultiplesFrom(self) as? [SwabRecordPhoneNumber] ?? []
		case kABPersonEmailProperty: self.emailAddresses = SwabRecordEmailAddress.loadMultiplesFrom(self) as? [SwabRecordEmailAddress] ?? []
		case kABPersonURLProperty: self.URLs = SwabRecordURL.loadMultiplesFrom(self) as? [SwabRecordURL] ?? []
		case kABPersonInstantMessageProperty: self.IMServices = SwabRecordIMService.loadMultiplesFrom(self) as? [SwabRecordIMService] ?? []
		case kABPersonSocialProfileProperty: self.socialNetworks = SwabRecordSocialNetwork.loadMultiplesFrom(self) as? [SwabRecordSocialNetwork] ?? []
		case kABPersonAddressProperty: self.streetAddresses = SwabRecordStreetAddress.loadMultiplesFrom(self) as? [SwabRecordStreetAddress] ?? []
		default: break
		}
	}
	
	func writeField(field: ABPropertyID) {
		switch (field) {
		case kABPersonFirstNameProperty: self.writeString(self.firstName, toProperty: field)
		case kABPersonMiddleNameProperty: self.writeString(self.middleName, toProperty: field)
		case kABPersonLastNameProperty: self.writeString(self.lastName, toProperty: field)
		case kABPersonOrganizationProperty: self.writeString(self.companyName, toProperty: field)
		case kABPersonJobTitleProperty: self.writeString(self.title, toProperty: field)
		case kABPersonNoteProperty: self.writeString(self.notes, toProperty: field)
		case kABPersonDepartmentProperty: self.writeString(self.department, toProperty: field)
		case kABPersonBirthdayProperty: self.writeDate(self.birthday, toProperty: field)
		
//		case kABPersonFirstNameProperty: self.writeString(self.firstName, toProperty: field)
//		case kABPersonFirstNameProperty: self.writeString(self.firstName, toProperty: field)
//		case kABPersonFirstNameProperty: self.writeString(self.firstName, toProperty: field)
//		case kABPersonFirstNameProperty: self.writeString(self.firstName, toProperty: field)
		default: break
		}
	}
	
	func writeString(string: String, toProperty prop: ABPropertyID) {
		var error: Unmanaged<CFError>?
		ABRecordSetValue(self.ref, prop, string, &error)
	}
	
	func writeDate(date: NSDate?, toProperty prop: ABPropertyID) {
		var error: Unmanaged<CFError>?
		ABRecordSetValue(self.ref, prop, date, &error)
	}
	
	func copyStringProperty(property: ABPropertyID) -> String? {
		return ABRecordCopyValue(self.ref, property)?.takeRetainedValue() as? String
	}
	
	func copyDateProperty(property: ABPropertyID) -> NSDate? {
		return ABRecordCopyValue(self.ref, property)?.takeRetainedValue() as? NSDate
	}
	
	func fieldChanged(field: ABPropertyID) {
		if !self.isLoading {
			changedFields.insert(field)
		}
	}
	var changedFields = Set<ABPropertyID>()
	
	public override var description: String {
		self.load()
		
		return "\(self.firstName) \(self.lastName), (\(self.companyName)) "
	}
}