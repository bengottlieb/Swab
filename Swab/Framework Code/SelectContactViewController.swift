//
//  SelectContactViewController.swift
//  Swab
//
//  Created by Ben Gottlieb on 4/29/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import AddressBook

public class SelectContactViewController: UITableViewController {
	var sections: [(title: String, records: [SwabRecord])] = []
	var sortOrder = ABPersonSortOrdering(kABPersonSortByLastName)
	
	class func loadedController(completion: (SelectContactViewController) -> Void) {
		var controller = SelectContactViewController()
		
		controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: controller, action: "cancel")
		controller.load {
			completion(controller)
		}
	}
	
	func load(completion: () -> Void) {
		Swab.instance.fetchAllRecords(fields: SwabRecord.nameProperties) { records in
			var sectionDict: [String: [SwabRecord]] = [:]
			
			for record in records {
				var sort = record.sortFieldForOrdering(self.sortOrder) as NSString
				var sortKey = sort.length > 0 ? sort.substringToIndex(1).uppercaseString : "-"
				
				if var current = sectionDict[sortKey] {
					current.append(record)
					sectionDict[sortKey] = current
				} else {
					sectionDict[sortKey] = [record]
				}
			}
			
			var array = sectionDict.keys.map({( title: $0, records: sectionDict[$0]! )})
			self.sections = sorted(array, { $0.title < $1.title })
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
			cell.textLabel?.text = record.displayName
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
		
		return section.records[indexPath.row]
	}
	
	func cancel() {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}
