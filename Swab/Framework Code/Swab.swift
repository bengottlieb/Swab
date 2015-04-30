//
//  Swab.swift
//  Swab
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI
import UIKit

public class Swab: NSObject {
	public class var instance: Swab { struct s { static let manager = Swab() }; return s.manager }
	
	public var isAuthorized = false
	
	public override class func initialize() {
		var error: Unmanaged<CFError>?
		var tempAddressBook = ABAddressBookCreateWithOptions(nil, &error)
	}
	
	public func authorize(completion: (Bool) -> Void) {
		self.queue.addOperationWithBlock {
			self.isAuthorized = ABAddressBookGetAuthorizationStatus() == .Authorized
		
			if !self.isAuthorized {
				self.pendingAuthorizations.append(completion)
				if self.authorizationInProgress { return }
				
				self.authorizationInProgress = true

				ABAddressBookRequestAccessWithCompletion(nil) { success, error in
					if success {
						var error: Unmanaged<CFError>?
						self.addressBook = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
					}
					
					for completion in self.pendingAuthorizations { completion(success) }
					self.pendingAuthorizations = []
				}
			} else {
				if self.addressBook == nil {
					var error: Unmanaged<CFError>?
					self.addressBook = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
				}
				completion(true)
			}
		}
	}
	
	public func fetchAddressBook(completion: (ABAddressBook?) -> Void) {
		if self.isAuthorized {
			self.queueBlock {  completion(self.addressBook) }
		} else {
			self.authorize { success in completion(self.addressBook) }
		}
	}
	
	public func save(completion: (() -> Void)? = nil) {
		self.fetchAddressBook { book in
			if ABAddressBookHasUnsavedChanges(book) {
				var error: Unmanaged<CFError>?
				if !ABAddressBookSave(book, &error) { println("Failed to save address book: \(error)") }
			}
			completion?()
		}
	}
	
	public func findAllPeopleWith(firstName: String? = nil, lastName: String? = nil, company: String? = nil, fields: [ABPropertyID]? = SwabRecord.allProperties, completion: ([SwabRecord]) -> Void) {
		self.fetchAddressBook { book in
			var empty = ""
			var fieldSet = Set(fields ?? [])
			var full: String = "\(firstName ?? empty) \(lastName ?? empty)".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
			var records: [SwabRecord] = []
			
			for string in [full, company] {
				if let searchString = string {
					if let found = ABAddressBookCopyPeopleWithName(book, searchString).takeRetainedValue() as? [ABRecord] {
						for record in found {
							let swab = self.recordWithABRecord(record)
							if let fields = fields { swab.load(fields: fieldSet) }
							records.append(swab)
						}
					}
				}
			}
			completion(records)
		}
	}
	
	public func findRecordWithID(recordID: ABRecordID, completion: (SwabRecord?) -> Void) {
		self.fetchAddressBook { book in
			var record: ABRecord? = ABAddressBookGetPersonWithRecordID(book, recordID)?.takeRetainedValue()
			completion(record == nil ? nil : self.recordWithABRecord(record!))
		}
	}
	
	public func fetchAllRecords(fields: [ABPropertyID] = [], completion: ([SwabRecord]) -> Void) {
		self.fetchAddressBook { book in
			var records: [SwabRecord] = []
			if let found = ABAddressBookCopyArrayOfAllPeople(book).takeRetainedValue() as? [ABRecord] {
				for record in found {
					let swab = self.recordWithABRecord(record)
					if fields.count > 0 { swab.load(fields: Set(fields)) }
					records.append(swab)
				}
			}
			completion(records)
		}
	}
	
	public func refresh() {
		self.fetchAddressBook { book in ABAddressBookRevert(book) }
	}
	
	public func importVCardData(data: NSData, filterDuplicates: Bool = true, completion: (([SwabRecord]) -> Void)? = nil) {
		self.fetchAddressBook { book in
			var created: [SwabRecord] = []
			var source: ABRecord = ABAddressBookCopyDefaultSource(book).takeUnretainedValue()
			
			if let newRecords = ABPersonCreatePeopleInSourceWithVCardRepresentation(source, data).takeRetainedValue() as? [ABRecord] {
				for card in newRecords {
					var record = self.recordWithABRecord(card)
					
					if filterDuplicates {
						var matching = self.findRecordsMatching(record)
						if matching.count > 0 { continue }
					}
					
					ABAddressBookAddRecord(book, card, nil)
					created.append(record)
				}
				self.save()
			}
			completion?(created)
		}
	}
	
	//=============================================================================================
	//MARK: Private stuff
	
	var authorizationInProgress = false
	var pendingAuthorizations: [(Bool) -> Void] = []
	let queue: NSOperationQueue = { var queue = NSOperationQueue(); queue.maxConcurrentOperationCount = 1; return queue }()
	internal var addressBook: ABAddressBook!
	internal var selectContactCompletion: ((SwabRecord?) -> Void)?
	internal var recordCache: [ABRecordID: SwabRecord] = [:]
	
	internal func recordWithABRecordID(id: ABRecordID) -> SwabRecord? {
		if let record = self.recordCache[id] { return record }
		return nil
	}
	
	internal func recordWithABRecord(rec: ABRecord) -> SwabRecord {
		let recordID = ABRecordGetRecordID(rec)
		if let existing = self.recordWithABRecordID(recordID) { return existing }
		
		let record = SwabRecord()
		record.ref = rec
		self.recordCache[recordID] = record
		record.recordID = recordID
		return record
	}
	
	internal func findRecordsMatching(card: SwabRecord) -> [SwabRecord] {
		var records: [SwabRecord] = []
		
		card.load()
		self.findAllPeopleWith(firstName: card.firstName, lastName: card.lastName, company: card.companyName) { found in
			for record in found {
				if record.isDuplicateOf(card) { records.append(record) }
			}
		}
		
		return records
	}
	
	internal func queueBlock(block: () -> Void) {
		if NSOperationQueue.currentQueue() == self.queue {
			block();
		} else {
			self.queue.addOperationWithBlock(block)
		}
	}
}

extension Swab: ABPeoplePickerNavigationControllerDelegate {
	public func selectContactInViewController(parent: UIViewController, animated: Bool = true, completion: (SwabRecord?) -> Void) {
		var nav = UINavigationController(rootViewController: SelectContactViewController(selected: { record in
			completion(record)
		}))
		parent.presentViewController(nav, animated: true, completion: nil)

//		var controller = ABPeoplePickerNavigationController()
//		
//		controller.peoplePickerDelegate = self
//		self.selectContactCompletion = completion
//		parent.presentViewController(controller, animated: true, completion: nil)
	}

	public func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecord!) {
		var recordID = ABRecordGetRecordID(person)
		
		self.findRecordWithID(recordID) { record in
			self.selectContactCompletion?(record)
		}
	}
	
	public func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
		self.selectContactCompletion?(nil)
	}


}