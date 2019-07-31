//
//  TestViewController.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/3/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "VideoCell", bundle: nil), forCellReuseIdentifier: "VideoCell")
        tableView.register(UINib(nibName: "StandartCell", bundle: nil), forCellReuseIdentifier: "StandartCell")
        tableView.reloadData()
    }

}

extension TestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2 {
            return self.view.frame.width * 0.5625
        }
        
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 2 {
            let videoCell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
            videoCell.setupVideo()
            return videoCell
        } else {
            let standart = tableView.dequeueReusableCell(withIdentifier: "StandartCell", for: indexPath) as! StandartCell
            return standart
        }
    }
}
