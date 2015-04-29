//
//  ViewController.swift
//  Swab
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import Swab
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewDidAppear(animated: Bool) {
		
	}
	
	@IBAction func chooseContact() {
		Swab.instance.selectContactInViewController(self, animated: true) { record in
			record?.generateVCard { data in
				if let data = data {
					Swab.instance.importVCardData(data)
				}
			}
		}
	}
	
	@IBAction func shareContactsDB() {
		Swab.instance.fetchAllRecords(fields: SwabRecord.noProperties) { records in
			SwabRecord.generateVCard(records) { data in
				dispatch_async(dispatch_get_main_queue()) {
					var controller = MFMailComposeViewController()
					
					controller.setSubject("Contacts.vcard")
					controller.addAttachmentData(data, mimeType: "text/x-vcard", fileName: "contacts.vcf")
					controller.mailComposeDelegate = self
					
					self.presentViewController(controller, animated: true, completion: nil)
					
				}
			}

		}
	}
	
	
	func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

}

