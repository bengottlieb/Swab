//
//  SelectContactViewController.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/29/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

public class SelectContactViewController: UITableViewController {
	var sections: [(title: String, records: [(sort: String, record: SwabRecord)])] = []
	var sortOrder = ABPersonSortOrdering(kABPersonSortByLastName)
	var completion: ((SwabRecord?) -> Void)?
	
	init(selected: ((SwabRecord?) -> Void)?) {
		super.init(nibName: nil, bundle: nil)
		
		self.completion = selected
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
		self.load { }
	}

	public required init!(coder aDecoder: NSCoder!) { fatalError("init(coder:) has not been implemented") }
	
	func load(completion: () -> Void) {
		Swab.instance.fetchAllRecords(fields: [kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonOrganizationProperty]) { records in
			var sectionDict: [String: [(sort: String, record: SwabRecord)]] = [:]
			
			for record in records {
				var sort = record.sortStringForOrdering(self.sortOrder) as NSString
				var sortKey = sort.length > 0 ? sort.substringToIndex(1).uppercaseString : "-"
				
				if var current = sectionDict[sortKey] {
					current.append((sort: sort as String, record: record))
					sectionDict[sortKey] = sorted(current, { $0.sort < $1.sort })
				} else {
					sectionDict[sortKey] = [(sort: sort as String, record: record)]
				}
			}
			
			var array = sectionDict.keys.map({( title: $0, records: sectionDict[$0]! )})
			self.sections = sorted(array, { $0.title < $1.title })
			dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData()	}
			completion()
		}
	}
	
	public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.sections[section].records.count
	}
	
	public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return count(sections)
	}
	
	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? UITableViewCell ?? UITableViewCell(style: .Value1, reuseIdentifier: "cell")
		
		if let record = self.recordAtIndexPath(indexPath) {
			cell.textLabel?.attributedText = record.attributedDisplayNameForSortField(self.sortOrder)
			
			cell.accessoryType = .DetailButton
		}
		
		return cell
	}
	
	public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section].title
	}
	
	func recordAtIndexPath(indexPath: NSIndexPath) -> SwabRecord? {
		if indexPath.section >= self.sections.count { return nil }
		
		var section = self.sections[indexPath.section]
		
		if indexPath.row >= section.records.count { return nil }
		
		return section.records[indexPath.row].record
	}
	
	func cancel() {
		self.completion?(nil)
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.completion?(self.recordAtIndexPath(indexPath))
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	public override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
		return self.sections.map({ return $0.title })
	}
	
	public override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
		if let record = self.recordAtIndexPath(indexPath) {
			var controller = ABPersonViewController()
		
			controller.displayedPerson = record.ref
			controller.allowsEditing = false
			controller.allowsActions = false
			controller.title = record.displayName
			
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
}
