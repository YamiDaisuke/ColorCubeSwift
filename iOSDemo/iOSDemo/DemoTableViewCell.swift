//
//  DemoTableViewCell.swift
//  iOSDemo
//
//  Created by Franklin Cruz on 8/1/19.
//  Copyright © 2019 SYSoft. All rights reserved.
//

import UIKit

class DemoTableViewCell: UITableViewCell {

    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var stackView: UIView!

    @IBOutlet weak var colorView1: UIView!
    @IBOutlet weak var colorView2: UIView!
    @IBOutlet weak var colorView3: UIView!
    @IBOutlet weak var colorView4: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Nothing to do here
    }

    public func fill(colors: (UIColor,UIColor,UIColor,UIColor)?, image: UIImage) {
        self.mainImageView.image = image


        if let colors = colors {
            self.colorView1.backgroundColor = colors.0
            self.colorView2.backgroundColor = colors.1
            self.colorView3.backgroundColor = colors.2
            self.colorView4.backgroundColor = colors.3
        } else {
            self.colorView1.backgroundColor = UIColor.clear
            self.colorView2.backgroundColor = UIColor.clear
            self.colorView3.backgroundColor = UIColor.clear
            self.colorView4.backgroundColor = UIColor.clear
        }

    }

}
