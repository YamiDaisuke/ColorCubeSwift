//
//  ViewController.swift
//  iOSDemo
//
//  Created by Franklin Cruz on 7/1/19.
//  Copyright © 2019 SYSoft. All rights reserved.
//

import UIKit
import ColorCubeSwift

class ViewController: UIViewController {

    var colorCube = CCColorCube()
    var images: [(image: UIImage, colors: (UIColor,UIColor,UIColor,UIColor)?)] = []


    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.images.removeAll()

        self.images.append( (image: UIImage(named: "schnee")!, colors: nil) )
        self.images.append( (image: UIImage(named: "berlin")!, colors: nil) )
        self.images.append( (image: UIImage(named: "markt")!, colors: nil) )
        self.images.append( (image: UIImage(named: "melone")!, colors: nil) )
        self.images.append( (image: UIImage(named: "xberg")!, colors: nil) )
        self.images.append( (image: UIImage(named: "glotze")!, colors: nil) )
        self.images.append( (image: UIImage(named: "streetart")!, colors: nil) )
        self.images.append( (image: UIImage(named: "club")!, colors: nil) )
        self.images.append( (image: UIImage(named: "museum")!, colors: nil) )
        self.images.append( (image: UIImage(named: "strand")!, colors: nil) )

        self.tableView.reloadData()

        self.computeColors(mode: 0)
    }

    @IBAction func segmentedChanged(sender: Any?) {
        self.segmentedControl.isEnabled = false
        self.computeColors(mode: self.segmentedControl.selectedSegmentIndex)
    }

    func computeColors(mode: Int) {

        DispatchQueue.global(qos: .userInitiated).async {

            let rgbWhite = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            let rgbBlue = UIColor(red: 0.3, green: 0.3, blue: 1, alpha: 1)

            var newImages:[(image: UIImage, colors: (UIColor,UIColor,UIColor,UIColor)?)] = []
            for var image in self.images {

                var colors = (UIColor.clear, UIColor.clear, UIColor.clear, UIColor.clear)
                var extracted: [UIColor] = []
                switch mode {
                case 0:
                    extracted = self.colorCube.extractBrightColors(fromImage: image.image, avoidColor: nil, count: 4)
                case 1:
                    extracted = self.colorCube.extractBrightColors(fromImage: image.image, avoidColor: rgbWhite, count: 4)
                case 2:
                    extracted = self.colorCube.extractBrightColors(fromImage: image.image, avoidColor: rgbBlue, count: 4)
                default:
                    extracted = []
                }

                colors.0 = extracted.count > 0 ? extracted[0] : UIColor.clear
                colors.1 = extracted.count > 1 ? extracted[1] : colors.0
                colors.2 = extracted.count > 2 ? extracted[2] : colors.1
                colors.3 = extracted.count > 3 ? extracted[3] : colors.2

                image.colors = colors
                newImages.append(image)
            }

            DispatchQueue.main.async {
                self.images = newImages
                self.segmentedControl.isEnabled = true
                self.tableView.reloadData()
            }

        }

    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.images.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DemoTableViewCell

        cell.fill(colors: self.images[indexPath.row].colors, image: self.images[indexPath.row].image)

        return cell
    }

}

