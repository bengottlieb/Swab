//
//  SwabRecord.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/25/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import UIKit
import AddressBook

public let kABPersonImageProperty: ABPropertyID = 50411

public class SwabRecord: NSObject {
	public static var allProperties = [kABPersonFirstNameProperty, kABPersonMiddleNameProperty, kABPersonLastNameProperty, kABPersonOrganizationProperty, kABPersonJobTitleProperty, kABPersonDepartmentProperty, kABPersonNoteProperty, kABPersonBirthdayProperty, kABPersonPhoneProperty, kABPersonEmailProperty, kABPersonURLProperty, kABPersonInstantMessageProperty, kABPersonSocialProfileProperty, kABPersonAddressProperty, kABPersonImageProperty]
	
	public struct servicesAndLabels {
		public static let emailLabels = [kABWorkLabel as String, kABHomeLabel as String, kABOtherLabel as String]
		public static let phoneLabels = [kABPersonPhoneMainLabel as String, kABPersonPhoneIPhoneLabel as String, kABPersonPhoneHomeFAXLabel as String, kABPersonPhoneWorkFAXLabel as String, kABPersonPhoneOtherFAXLabel as String, kABPersonPhonePagerLabel as String]
		public static let socialServices = [kABPersonSocialProfileServiceTwitter as String, kABPersonSocialProfileServiceSinaWeibo as String, kABPersonSocialProfileServiceFacebook as String, kABPersonSocialProfileServiceGameCenter as String, kABPersonSocialProfileServiceMyspace as String, kABPersonSocialProfileServiceFlickr as String, kABPersonSocialProfileServiceLinkedIn as String]
		public static let imServices = [kABPersonInstantMessageServiceYahoo as String, kABPersonInstantMessageServiceJabber as String, kABPersonInstantMessageServiceMSN as String, kABPersonInstantMessageServiceICQ as String, kABPersonInstantMessageServiceAIM as String, kABPersonInstantMessageServiceQQ as String, kABPersonInstantMessageServiceGoogleTalk as String, kABPersonInstantMessageServiceSkype as String, kABPersonInstantMessageServiceFacebook as String, kABPersonInstantMessageServiceGaduGadu as String]
	}
	
	public static var nameProperties = [kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonImageProperty]
	
	public var ref: ABRecord?
	
	public var recordID: ABRecordID?
	public var firstName = "" { didSet { self.fieldChanged(kABPersonFirstNameProperty) } }
	public var middleName = "" { didSet { self.fieldChanged(kABPersonMiddleNameProperty) } }
	public var lastName = "" { didSet { self.fieldChanged(kABPersonLastNameProperty) } }
	public var companyName = "" { didSet { self.fieldChanged(kABPersonOrganizationProperty) } }
	public var title = "" { didSet { self.fieldChanged(kABPersonJobTitleProperty) } }
	public var department = "" { didSet { self.fieldChanged(kABPersonDepartmentProperty) } }
	public var notes = "" { didSet { self.fieldChanged(kABPersonNoteProperty) } }
	public var birthday: NSDate? { didSet { self.fieldChanged(kABPersonBirthdayProperty) } }
	public var image: UIImage? { didSet { self.fieldChanged(kABPersonImageProperty) } }
	
	public var phoneNumbers: [SwabRecordPhoneNumber] = []
	public var emailAddresses: [SwabRecordEmailAddress] = []
	public var URLs: [SwabRecordURL] = []
	public var IMServices: [SwabRecordIMService] = []
	public var socialNetworks: [SwabRecordSocialNetwork] = []
	public var streetAddresses: [SwabRecordStreetAddress] = []
	
	public func generateVCard(completion: (NSData?) -> Void) {
		Swab.instance.fetchAddressBook { book in
			if let record: ABRecord = self.ref {
				let data = ABPersonCreateVCardRepresentationWithPeople([record]).takeRetainedValue()
				completion(data)
			} else {
				completion(nil)
			}
		}
	}
	
	public class func generateVCard(records: [SwabRecord], completion: (NSData?) -> Void) {
		Swab.instance.fetchAddressBook { book in
			let refs = records.map { $0.ref! }
			let data = ABPersonCreateVCardRepresentationWithPeople(refs).takeRetainedValue()
			completion(data)
		}
	}
	
	public var displayName: String {
		self.load(Set([kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonOrganizationProperty]))
			
		let string = "\(self.firstName) \(self.lastName)"
		if string.characters.count > 1 { return string }
		
		return self.companyName
	}
	
	public func attributedDisplayNameForSortField(order: ABPersonSortOrdering) -> NSAttributedString {
		self.load(Set([kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonOrganizationProperty]))
		let sortField = self.sortFieldForOrdering(order)
		let size: CGFloat = 15.0
		let plainAttr = [ NSFontAttributeName: UIFont.systemFontOfSize(size)]
		let boldAttr = [ NSFontAttributeName: UIFont.boldSystemFontOfSize(size)]
		let string = NSMutableAttributedString()
		
		if sortField == kABPersonFirstNameProperty {
			string.appendAttributedString(NSAttributedString(string: self.firstName, attributes: boldAttr))
			if string.length > 0 { string.appendAttributedString(NSAttributedString(string: " ")) }
			string.appendAttributedString(NSAttributedString(string: self.lastName, attributes: plainAttr))
		} else if sortField == kABPersonLastNameProperty {
			string.appendAttributedString(NSAttributedString(string: self.firstName, attributes: plainAttr))
			if string.length > 0 { string.appendAttributedString(NSAttributedString(string: " ")) }
			string.appendAttributedString(NSAttributedString(string: self.lastName, attributes: boldAttr))
		} else {
			return NSAttributedString(string: self.companyName, attributes: boldAttr)
		}

		return string
	}
	
	public func isDuplicateOf(other: SwabRecord) -> Bool {
		self.load()
		other.load()
		
		if self.displayName != other.displayName { return false }
		
		return true
	}

	public func sortFieldForOrdering(order: ABPersonSortOrdering) -> ABPropertyID {
		var checkOrder: [ABPropertyID] = []
		
		switch Int(order) {
		case kABPersonSortByFirstName: checkOrder = [kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonOrganizationProperty]
		case kABPersonSortByLastName: checkOrder = [kABPersonLastNameProperty, kABPersonFirstNameProperty, kABPersonOrganizationProperty]
		default:
			assert(false, "illegal sort order: \(order)")
			break
		}
		
		for prop in checkOrder {
			if let string = self[prop] where !string.isEmpty {
				return prop
			}
		}
		return kABPersonLastNameProperty
	}
	
	public func sortStringForOrdering(order: ABPersonSortOrdering) -> String {
		return self[self.sortFieldForOrdering(order)]?.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet()) ?? ""
	}
	
	public var primaryEmail: SwabRecordEmailAddress? {
		self.load(Set([kABPersonEmailProperty]))
		
		for email in self.emailAddresses {
			if email.label == "E-mail" { return email; }
		}
		
		if self.emailAddresses.count > 0 { return self.emailAddresses[0] }
		return nil
	}
	
	public var primaryPhone: SwabRecordPhoneNumber? {
		self.load(Set([kABPersonPhoneProperty]))
		
		for phone in self.phoneNumbers { if phone.label == (kABPersonPhoneMainLabel as String) { return phone } }
		for phone in self.phoneNumbers { if phone.label == (kABPersonPhoneIPhoneLabel as String) { return phone } }
		
		if self.phoneNumbers.count > 0 { return self.phoneNumbers[0] }
		return nil
	}
	
	//=============================================================================================
	//MARK: Loading
	public func load(fields: Set<ABPropertyID> = Set(SwabRecord.allProperties)) {
		let fieldsToLoad = fields.subtract(self.loadedFields)
		if fieldsToLoad.count == 0 || self.ref == nil { return }
		
		self.isLoading = true
		for field in fieldsToLoad { self.loadField(field) }
		
		self.loadedFields.unionInPlace(fieldsToLoad)
		self.isLoading = false
	}
	
	var loadedFields = Set<ABPropertyID>()
	var isLoading = false
	
	subscript(key: ABPropertyID) -> String? {
		get {
			switch key {
			case kABPersonFirstNameProperty: return self.firstName
			case kABPersonLastNameProperty: return self.lastName
			case kABPersonMiddleNameProperty: return self.middleName
			case kABPersonOrganizationProperty: return self.companyName
			case kABPersonJobTitleProperty: return self.title
			case kABPersonDepartmentProperty: return self.department
			default: return nil
			}
		}
	}
	
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
	
	public func save() -> NSError? {
		for field in self.changedFields {
			if let error = self.writeField(field) {
				return error
			}
		}
		return nil
	}
	
	func writeField(field: ABPropertyID) -> NSError? {
		var errors: [NSError?] = []
		
		switch (field) {
		case kABPersonImageProperty:
			if let image = self.image {
				var error: Unmanaged<CFError>?
				ABPersonSetImageData(self.ref, UIImageJPEGRepresentation(image, 1.0), &error)
			}
			
		case kABPersonFirstNameProperty: return self.writeString(self.firstName, toProperty: field)
		case kABPersonMiddleNameProperty: return self.writeString(self.middleName, toProperty: field)
		case kABPersonLastNameProperty: return self.writeString(self.lastName, toProperty: field)
		case kABPersonOrganizationProperty: return self.writeString(self.companyName, toProperty: field)
		case kABPersonJobTitleProperty: return self.writeString(self.title, toProperty: field)
		case kABPersonNoteProperty: return self.writeString(self.notes, toProperty: field)
		case kABPersonDepartmentProperty: return self.writeString(self.department, toProperty: field)
		case kABPersonBirthdayProperty: return self.writeDate(self.birthday, toProperty: field)
		
		case kABPersonPhoneProperty: errors = self.phoneNumbers.map { $0.writeToRecord() }
		case kABPersonEmailProperty: errors = self.emailAddresses.map { $0.writeToRecord() }
		case kABPersonURLProperty: errors = self.URLs.map { $0.writeToRecord() }
		case kABPersonInstantMessageProperty: errors = self.IMServices.map { $0.writeToRecord() }
		case kABPersonSocialProfileProperty: errors = self.socialNetworks.map { $0.writeToRecord() }
		case kABPersonAddressProperty: errors = self.streetAddresses.map { $0.writeToRecord() }
		default: break
		}
		
		if errors.count > 0 { return errors[0] }
		return nil
	}
	
	func writeString(string: String, toProperty prop: ABPropertyID) -> NSError? {
		var error: Unmanaged<CFError>?
		if !ABRecordSetValue(self.ref, prop, string, &error) {
			print("Problem saving \(string) to \(prop): \(error)")
		}
		return nil
	}
	
	func writeDate(date: NSDate?, toProperty prop: ABPropertyID) -> NSError? {
		var error: Unmanaged<CFError>?
		ABRecordSetValue(self.ref, prop, date, &error)
		return nil
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
		
		var string = "\(self.firstName) \(self.lastName), (\(self.companyName))\n"
		
		for phone in self.phoneNumbers { string += "  " + phone.description + "\n" }
		for email in self.emailAddresses { string += "  " + email.description + "\n"  }
		for url in self.URLs { string += "  " + url.description + "\n"  }
		for im in self.IMServices { string += "  " + im.description + "\n"  }
		for social in self.socialNetworks { string += "  " + social.description + "\n"  }
		for address in self.streetAddresses { string += "  " + address.description + "\n"  }
		return string
	}
}
