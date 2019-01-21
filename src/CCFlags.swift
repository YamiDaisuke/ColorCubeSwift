//
//  CCFlags.swift
//  ColorCubeSwift
//
//  Created by Franklin Cruz on 7/1/19.
//  Copyright © 2019 SYSoft. All rights reserved.
//

import Foundation
import UIKit

public enum CCFlags: UInt8 {
    // This ignores all pixels that are darker than a threshold
    case onlyBrightColors   = 1

    // This ignores all pixels that are brighter than a threshold
    case onlyDarkColors     = 2

    // This filters the result array so that only distinct colors are returned
    case onlyDistinctColors = 4

    // This orders the result array by color brightness (first color has highest brightness). If not set,
    // colors are ordered by frequency (first color is "most frequent").
    case orderByBrightness  = 8

    // This orders the result array by color darkness (first color has lowest brightness). If not set,
    // colors are ordered by frequency (first color is "most frequent").
    case orderByDarkness    = 16

    // Removes colors from the result if they are too close to white
    case avoidWhite         = 32

    // Removes colors from the result if they are too close to black
    case avoidBlack         = 64

}
