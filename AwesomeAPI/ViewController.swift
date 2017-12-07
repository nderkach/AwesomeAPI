//
//  ViewController.swift
//  AwesomeAPI
//
//  Created by Nikolay Derkach on 12/6/17.
//  Copyright © 2017 Nikolay Derkach. All rights reserved.
//

import Siesta

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        AwesomeAPI.expenses().addObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AwesomeAPI.login("test", "test", onSuccess: {
            AwesomeAPI.expenses().loadIfNeeded()
        }, onFailure: { error in
            print(error)
        })
    }
}

extension ViewController: ResourceObserver {
    func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        if let expenses: [Expense] = resource.typedContent() {
            print(expenses)
        }
    }
}

