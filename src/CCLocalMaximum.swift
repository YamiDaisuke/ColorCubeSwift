//
//  CCLocalMaximum.swift
//  ColorCubeSwift
//
//  Created by Franklin Cruz on 7/1/19.
//  Copyright © 2019 SYSoft. All rights reserved.
//

import Foundation

public class CCLocalMaximum: NSObject {

    // Hit count of the cell
    var hitCount: Int = 0

    // Linear index of the cell
    var cellIndex: Int = 0

    // Average color of cell
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0

    // Maximum color component value of average color
    var brightness: CGFloat = 0.0
}
