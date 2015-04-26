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
		if self.isAuthorized { completion(self.addressBook); return }
		
		self.authorize { success in completion(self.addressBook) }
	}
	
	public func save(completion: () -> Void) {
		self.queue.addOperationWithBlock({
			if ABAddressBookHasUnsavedChanges(self.addressBook) {
				var error: Unmanaged<CFError>?
				if !ABAddressBookSave(self.addressBook, &error) { println("Failed to save address book: \(error)") }
			}
		})
	}
	
	public func findAllPeopleWith(firstName: String? = nil, lastName: String? = nil, company: String? = nil, fields: Set<ABPropertyID>? = SwabRecord.allProperties, completion: ([SwabRecord]) -> Void) {
		self.fetchAddressBook { book in
			var empty = ""
			var full: String = "\(firstName ?? empty) \(lastName ?? empty)".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
			var records: [SwabRecord] = []
			
			for string in [full, company] {
				if let searchString = string {
					if let found = ABAddressBookCopyPeopleWithName(book, searchString).takeRetainedValue() as? [ABRecord] {
						for record in found {
							let swab = self.recordWithABRecord(record)
							if let fields = fields { swab.load(fields: fields) }
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
	
	public func refresh() {
		self.fetchAddressBook { book in ABAddressBookRevert(book) }
	}
	
	//=============================================================================================
	//MARK: Private stuff
	
	var authorizationInProgress = false
	var pendingAuthorizations: [(Bool) -> Void] = []
	let queue: NSOperationQueue = { var queue = NSOperationQueue(); queue.maxConcurrentOperationCount = 1; return queue }()
	internal var addressBook: ABAddressBook!
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
		return record
	}

}

}