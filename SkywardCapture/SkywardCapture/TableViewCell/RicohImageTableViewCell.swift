//
//  RicohImageTableViewCell.swift
//  SkywardCapture
//
//  Created by Rahul Umap on 11/04/19.
//  Copyright © 2019 Rahul Umap. All rights reserved.
//

import UIKit

class RicohImageTableViewCell: UITableViewCell {
    @IBOutlet weak var ricohImageView: UIImageView!
    @IBOutlet weak var imageNameLabel: UILabel!
    @IBOutlet weak var capturedDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
