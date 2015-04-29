//
//  ViewController.swift
//  Swab
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import Swab

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		Swab.instance.allRecords { all in
			SwabRecord.generateVCard(all) { data in
				
			}
		}
		
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewDidAppear(animated: Bool) {
		
		Swab.instance.selectContactInViewController(self, animated: true) { record in
			record?.generateVCard { data in
				if let data = data {
					Swab.instance.importVCardData(data)
				}
			}
			
//			println("result: \(record)")
//			
//			record?.firstName = "James"
//			record?.lastName = "Frederick"
//			
//			record?.phoneNumbers[0].number = "123-123-1234"
//			record?.save()
//			
//			Swab.instance.save()
			
		}
	}
}

