//
//  SwabRecord.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/25/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import AddressBook

public class SwabRecord: NSObject {
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
	
	init?(record: ABRecord?) {
		super.init()
		
		if record == nil { return nil }
		self.ref = record
	}
	
	var isLoaded = false
	
	//=============================================================================================
	//MARK: Loading
	func load() {
		if self.isLoaded || self.ref == nil { return }
		if let imageData = ABPersonCopyImageDataWithFormat(self.ref, kABPersonImageFormatOriginalSize)?.takeRetainedValue() as? NSData { self.image = UIImage(data: imageData) }
		
		self.firstName = self.copyStringProperty(kABPersonFirstNameProperty) ?? ""
		self.lastName = self.copyStringProperty(kABPersonLastNameProperty) ?? ""
		self.middleName = self.copyStringProperty(kABPersonMiddleNameProperty) ?? ""
		self.companyName = self.copyStringProperty(kABPersonOrganizationProperty) ?? ""
		self.title = self.copyStringProperty(kABPersonJobTitleProperty) ?? ""
		self.department = self.copyStringProperty(kABPersonDepartmentProperty) ?? ""
		self.notes = self.copyStringProperty(kABPersonNoteProperty) ?? ""
		
		self.birthday = self.copyDateProperty(kABPersonBirthdayProperty)
		
		self.phoneNumbers = SwabRecordPhoneNumber.loadMultiplesFrom(self.ref!) as? [SwabRecordPhoneNumber] ?? []
		self.emailAddresses = SwabRecordEmailAddress.loadMultiplesFrom(self.ref!) as? [SwabRecordEmailAddress] ?? []
		self.URLs = SwabRecordURL.loadMultiplesFrom(self.ref!) as? [SwabRecordURL] ?? []
		self.IMServices = SwabRecordIMService.loadMultiplesFrom(self.ref!) as? [SwabRecordIMService] ?? []
		self.socialNetworks = SwabRecordSocialNetwork.loadMultiplesFrom(self.ref!) as? [SwabRecordSocialNetwork] ?? []
		self.streetAddresses = SwabRecordStreetAddress.loadMultiplesFrom(self.ref!) as? [SwabRecordStreetAddress] ?? []
		
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