//
//  CCColorCube.swift
//  ColorCubeSwift
//
//  Created by Franklin Cruz on 7/1/19.
//  Copyright © 2019 SYSoft. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

public class CCColorCube: NSObject {

    // The cell resolution in each color dimension
    private static let COLOR_CUBE_RESOLUTION: Int = 30
    private static let COLOR_CUBE_RESOLUTION_TIMES_3: Int = 30 * 30 * 30
    private static let COLOR_CUBE_RESOLUTION_GCFLOAT: CGFloat = 30

    // Threshold used to filter bright colors
    private static let BRIGHT_COLOR_THRESHOLD: CGFloat = 0.6

    // Threshold used to filter dark colors
    private static let DARK_COLOR_THRESHOLD = 0.4

    // Threshold (distance in color space) for distinct colors
    private static let DISTINCT_COLOR_THRESHOLD: CGFloat = 0.2

    // Helper macro to compute linear index for cells
    // private class func CELL_INDEX(r,g,b) (r+g*COLOR_CUBE_RESOLUTION+b*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION)

    // Helper macro to get total count of cells
    // let CELL_COUNT COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION


    // Indices for neighbour cells in three dimensional grid
    private static let neighbourIndices: [[Int]] = [
        [ 0, 0, 0],
        [ 0, 0, 1],
        [ 0, 0,-1],

        [ 0, 1, 0],
        [ 0, 1, 1],
        [ 0, 1,-1],

        [ 0,-1, 0],
        [ 0,-1, 1],
        [ 0,-1,-1],

        [ 1, 0, 0],
        [ 1, 0, 1],
        [ 1, 0,-1],

        [ 1, 1, 0],
        [ 1, 1, 1],
        [ 1, 1,-1],

        [ 1,-1, 0],
        [ 1,-1, 1],
        [ 1,-1,-1],

        [-1, 0, 0],
        [-1, 0, 1],
        [-1, 0,-1],

        [-1, 1, 0],
        [-1, 1, 1],
        [-1, 1,-1],

        [-1,-1, 0],
        [-1,-1, 1],
        [-1,-1,-1],
    ]

    private var cells: [CCCubeCell] = []

    public override init() {
        cells = [CCCubeCell](
            repeating: CCCubeCell(),
            count: CCColorCube.COLOR_CUBE_RESOLUTION_TIMES_3
        )
    }

    // Extracts and returns dominant colors of the image (the array contains UIColor objects). Result might be empty.
    public func extractColors(fromImage image:UIImage, withFlags flags: UInt8 ) -> [UIColor] {
        // Get maxima
        let sortedMaxima = self.extractAndFilterMaxima(fromImage: image, flags: flags)

        // Return color array
        return self.colors(fromMaxima: sortedMaxima)
    }

    // Same as above but avoids colors too close to the specified one.
    // IMPORTANT: The avoidColor must be in RGB, so create it with colorWithRed method of UIColor!
    public func extractColors(fromImage image:UIImage, withFlags flags: UInt8, avoidColor: UIColor ) -> [UIColor] {
        // Get maxima
        var sortedMaxima = self.extractAndFilterMaxima(fromImage: image, flags: flags)

        // Filter out colors that are too close to the specified color
        sortedMaxima = self.filter(maxima: sortedMaxima, tooCloseToColor: avoidColor)

        // Return color array
        return self.colors(fromMaxima: sortedMaxima)
    }

    // Tries to get count bright colors from the image, avoiding the specified one (only if avoidColor is non-nil).
    // IMPORTANT: The avoidColor (if set) must be in RGB, so create it with colorWithRed method of UIColor!
    // Might return less than count colors!
    public func extractBrightColors(fromImage image: UIImage, avoidColor: UIColor?, count: Int ) -> [UIColor] {
        
        // Get maxima (bright only)
        var sortedMaxima = self.findAndSortMaxima(inImage: image, flags: CCFlags.onlyBrightColors.rawValue)

        if let avoidColor = avoidColor {
            // Filter out colors that are too close to the specified color
            sortedMaxima = self.filter(maxima: sortedMaxima, tooCloseToColor: avoidColor)
        }

        // Do clever distinct color filtering
        sortedMaxima = self.performAdaptiveDistinctFiltering(forMaxima: sortedMaxima, count: count)

        // Return color array
        return self.colors(fromMaxima: sortedMaxima)
    }

    // Tries to get count dark colors from the image, avoiding the specified one (only if avoidColor is non-nil).
    // IMPORTANT: The avoidColor (if set) must be in RGB, so create it with colorWithRed method of UIColor!
    // Might return less than count colors!
    public func extractDarkColors(fromImage image: UIImage, avoidColor: UIColor, count: Int ) -> [UIColor] {
        // Get maxima (bright only)
        var sortedMaxima = self.findAndSortMaxima(inImage: image, flags: CCFlags.onlyDarkColors.rawValue)

        // Filter out colors that are too close to the specified color
        sortedMaxima = self.filter(maxima: sortedMaxima, tooCloseToColor: avoidColor)

        // Do clever distinct color filtering
        sortedMaxima = self.performAdaptiveDistinctFiltering(forMaxima: sortedMaxima, count: count)

        // Return color array
        return self.colors(fromMaxima: sortedMaxima)
    }

    // Tries to get count colors from the image
    // Might return less than count colors!
    public func extractColors(fromImage image: UIImage, withFlags flags: UInt8,  count: Int) -> [UIColor] {
        // Get maxima
        var sortedMaxima = self.extractAndFilterMaxima(fromImage: image, flags: flags)

        // Do clever distinct color filtering
        sortedMaxima = self.performAdaptiveDistinctFiltering(forMaxima: sortedMaxima, count: count)

        // Return color array
        return self.colors(fromMaxima: sortedMaxima)
    }


    // Returns array of raw pixel data (needs to be freed)
    private func rawPixelData(fromImage image: UIImage) -> (data: [CUnsignedChar], pixelCount: Int) {
        // Get cg image and its size
        let cgImage = image.cgImage!

        let width = cgImage.width
        let height = cgImage.height

        var rawData:[CUnsignedChar] = [CUnsignedChar](repeating: 0, count: height * width * 4)

        // Create the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        let context = CGContext.init(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        )

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (data: rawData, pixelCount: width * height)
    }

    // Resets all cells
    private func clearCells(array: UnsafeMutableBufferPointer<CCCubeCell>) {
        for i in 0..<CCColorCube.COLOR_CUBE_RESOLUTION_TIMES_3 {
            array[i].hitCount = 0
            array[i].redAcc = 0
            array[i].greenAcc = 0
            array[i].blueAcc = 0
        }
    }

    // private class func CELL_INDEX(r,g,b) (r+g*COLOR_CUBE_RESOLUTION+b*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION)
    private func cellIndexFrom(r: Int, g: Int, b: Int) -> Int {
        return ( r + g * CCColorCube.COLOR_CUBE_RESOLUTION + b * CCColorCube.COLOR_CUBE_RESOLUTION * CCColorCube.COLOR_CUBE_RESOLUTION)
    }

    // Returns array of CCLocalMaximum objects
    private func findLocalMaxima(inImage image: UIImage, flags: UInt8) -> [CCLocalMaximum] {


        // We collect local maxima in here
        var localMaxima: [CCLocalMaximum] = []
        localMaxima.reserveCapacity(CCColorCube.COLOR_CUBE_RESOLUTION_TIMES_3)

        self.cells.withUnsafeMutableBufferPointer { cellsPointer in
            var raw = self.rawPixelData(fromImage: image)
            self.clearCells(array: cellsPointer)
            // TODO: raw.data can be nil

            // Helper variables
            var red: CGFloat
            var green: CGFloat
            var blue: CGFloat

            var redIndex: Int
            var greenIndex: Int
            var blueIndex: Int
            var cellIndex: Int
            var localHitCount: Int

            var isLocalMaximum: Bool
            let kLimit = raw.pixelCount - 1
            for k in 0...kLimit {

                // Get color components as floating point value in [0,1]
                red = (CGFloat)(raw.data[k * 4 + 0]) / 255.0
                green = (CGFloat)(raw.data[k * 4 + 1]) / 255.0
                blue = (CGFloat)(raw.data[k * 4 + 2]) / 255.0

                // If we only want bright colors and this pixel is dark, ignore it
                if (flags & CCFlags.onlyBrightColors.rawValue) > 0 {
                    if red < CCColorCube.BRIGHT_COLOR_THRESHOLD && green < CCColorCube.BRIGHT_COLOR_THRESHOLD && blue < CCColorCube.BRIGHT_COLOR_THRESHOLD {
                        continue
                    }
                } else if (flags & CCFlags.onlyDarkColors.rawValue) > 0 {
                    if red >= CCColorCube.BRIGHT_COLOR_THRESHOLD || green >= CCColorCube.BRIGHT_COLOR_THRESHOLD || blue >= CCColorCube.BRIGHT_COLOR_THRESHOLD {
                        continue
                    }
                }

                // Map color components to cell indices in each color dimension
                redIndex   = (Int)(red * (CCColorCube.COLOR_CUBE_RESOLUTION_GCFLOAT - 1.0));
                greenIndex = (Int)(green * (CCColorCube.COLOR_CUBE_RESOLUTION_GCFLOAT - 1.0));
                blueIndex  = (Int)(blue * (CCColorCube.COLOR_CUBE_RESOLUTION_GCFLOAT - 1.0));

                // Compute linear cell index
                // cellIndex = CELL_INDEX(redIndex, greenIndex, blueIndex);
                cellIndex = cellIndexFrom(r: redIndex, g: greenIndex, b: blueIndex)


                // Increase hit count of cell
                cellsPointer[cellIndex].hitCount += 1;

                // Add pixel colors to cell color accumulators
                cellsPointer[cellIndex].redAcc   += red;
                cellsPointer[cellIndex].greenAcc += green;
                cellsPointer[cellIndex].blueAcc  += blue;
            }

            let neighbourIndices = CCColorCube.neighbourIndices

            // Find local maxima in the grid
            for r in 0..<CCColorCube.COLOR_CUBE_RESOLUTION {
                for g in 0..<CCColorCube.COLOR_CUBE_RESOLUTION {
                    for b in 0..<CCColorCube.COLOR_CUBE_RESOLUTION {

                        // Get hit count of this cell
                        localHitCount = cellsPointer[cellIndexFrom(r: r, g: g, b: b)].hitCount;

                        // If this cell has no hits, ignore it (we are not interested in zero hits)
                        if localHitCount == 0 { continue }

                        // It is local maximum until we find a neighbour with a higher hit count
                        isLocalMaximum = true;

                        // Check if any neighbour has a higher hit count, if so, no local maxima
                        for n in 0...26 {
                            redIndex = r + neighbourIndices[n][0]
                            greenIndex = g + neighbourIndices[n][1]
                            blueIndex = b + neighbourIndices[n][2]

                            // Only check valid cell indices (skip out of bounds indices)
                            if redIndex >= 0 && greenIndex >= 0 && blueIndex >= 0 {
                                if (redIndex < CCColorCube.COLOR_CUBE_RESOLUTION && greenIndex < CCColorCube.COLOR_CUBE_RESOLUTION && blueIndex < CCColorCube.COLOR_CUBE_RESOLUTION) {
                                    if (cellsPointer[cellIndexFrom(r: redIndex, g: greenIndex, b: blueIndex)].hitCount > localHitCount) {
                                        // Neighbour hit count is higher, so this is NOT a local maximum.
                                        isLocalMaximum = false;
                                        // Break inner loop
                                        break;
                                    }
                                }
                            }
                        }

                        // If this is not a local maximum, continue with loop.
                        if !isLocalMaximum { continue }

                        // Otherwise add this cell as local maximum
                        let maximum = CCLocalMaximum()
                        maximum.cellIndex = cellIndexFrom(r: r, g: g, b: b)

                        maximum.hitCount = cellsPointer[maximum.cellIndex].hitCount

                        maximum.red   = cellsPointer[maximum.cellIndex].redAcc /
                            (CGFloat)(cellsPointer[maximum.cellIndex].hitCount)

                        maximum.green = cellsPointer[maximum.cellIndex].greenAcc /
                            (CGFloat)(cellsPointer[maximum.cellIndex].hitCount)

                        maximum.blue  = cellsPointer[maximum.cellIndex].blueAcc /
                            (CGFloat)(cellsPointer[maximum.cellIndex].hitCount)

                        maximum.brightness = fmax(fmax(maximum.red, maximum.green), maximum.blue)
                        localMaxima.append(maximum)
                    }
                }
            }


            // Finally sort the array of local maxima by hit count
            //        let sortedMaxima = [localMaxima sortedArrayUsingComparator:^NSComparisonResult(CCLocalMaximum *m1, CCLocalMaximum *m2){
            //            if (m1.hitCount == m2.hitCount) return NSOrderedSame;
            //            return m1.hitCount > m2.hitCount ? NSOrderedAscending : NSOrderedDescending;
            //            }];
            localMaxima.sort { $0.hitCount > $1.hitCount }
        }

        return localMaxima;
    }

    // Returns array of CCLocalMaximum objects
    private func findAndSortMaxima(inImage image: UIImage, flags: UInt8) -> [CCLocalMaximum] {

        // First get local maxima of image
        var sortedMaxima = self.findLocalMaxima(inImage: image, flags: flags)

        // Filter the maxima if we want only distinct colors
        if (flags & CCFlags.onlyDistinctColors.rawValue) > 0 {
            sortedMaxima = self.filterDistinct(maxima: sortedMaxima, threshold: CCColorCube.DISTINCT_COLOR_THRESHOLD)
        }

        // If we should order the result array by brightness, do it
        if (flags & CCFlags.orderByBrightness.rawValue) > 0 {
            sortedMaxima = self.orderByBrightness(maxima: sortedMaxima)
        } else if (flags & CCFlags.orderByDarkness.rawValue) > 0 {
            sortedMaxima = self.orderByDarkness(maxima: sortedMaxima)
        }


        return sortedMaxima
    }

    // Returns array of CCLocalMaximum objects
    private func extractAndFilterMaxima(fromImage image: UIImage, flags: UInt8) -> [CCLocalMaximum] {
        // Get maxima
        var sortedMaxima = self.findAndSortMaxima(inImage: image, flags: flags)

        // Filter out colors too close to black
        if (flags & CCFlags.avoidBlack.rawValue) > 0 {
            sortedMaxima = self.filter(maxima: sortedMaxima, tooCloseToColor: UIColor(red: 0, green: 0, blue: 0, alpha: 1))
        }

        // Filter out colors too close to white
        if (flags & CCFlags.avoidWhite.rawValue) > 0 {
            sortedMaxima = self.filter(maxima: sortedMaxima, tooCloseToColor: UIColor(red: 1, green: 1, blue: 1, alpha: 1))
        }

        // Return maxima array
        return sortedMaxima;
    }

    // Returns array of UIColor objects
    private func colors(fromMaxima maxima: [CCLocalMaximum]) -> [UIColor] {
        var new: [UIColor] = []
        new.reserveCapacity(maxima.count)

        for m in maxima {
            new.append(UIColor(red: m.red, green: m.green, blue: m.blue, alpha: 1))
        }

        return new //maxima.map({UIColor(red: $0.red, green: $0.green, blue: $0.blue, alpha: 1) })
    }

    // Returns new array with only distinct maxima
    private func filterDistinct(maxima: [CCLocalMaximum], threshold: CGFloat) -> [CCLocalMaximum] {
        var filteredMaxima: [CCLocalMaximum] = [];

        // Check for each maximum
        for k in 0..<maxima.count {
            // Get the maximum we are checking out
            let max1 = maxima[k]

            // This color is distinct until a color from before is too close
            var isDistinct = true

            // Go through previous colors and look if any of them is too close

            if k > 0 {
                for n in 0..<k {
                    // Get the maximum we compare to
                    let max2 = maxima[n]

                    // Compute delta components
                    let redDelta   = max1.red - max2.red
                    let greenDelta = max1.green - max2.green
                    let blueDelta  = max1.blue - max2.blue

                    // Compute delta in color space distance
                    let delta = sqrt(redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta)

                    // If too close mark as non-distinct and break inner loop
                    if delta < threshold {
                        isDistinct = false
                        break
                    }
                }
            }

            // Add to filtered array if is distinct
            if isDistinct {
                filteredMaxima.append(max1)
            }
        }

        return filteredMaxima;
    }

    // Removes maxima too close to specified color
    private func filter(maxima: [CCLocalMaximum], tooCloseToColor color: UIColor) -> [CCLocalMaximum] {
        // Get color components
        let components = color.cgColor.components ?? []

        var filteredMaxima: [CCLocalMaximum] = []

        // Check for each maximum
        for k in 0..<maxima.count {
            // Get the maximum we are checking out
            let max1 = maxima[k]

            // Compute delta components
            let redDelta   = max1.red - components[0]
            let greenDelta = max1.green - components[1]
            let blueDelta  = max1.blue - components[2]

            // Compute delta in color space distance
            let delta = sqrt(redDelta*redDelta + greenDelta*greenDelta + blueDelta*blueDelta)

            // If not too close add it
            if delta >= 0.5 {
                filteredMaxima.append(max1)
            }
        }

        return filteredMaxima
    }

    // Tries to get count distinct maxima
    private func performAdaptiveDistinctFiltering(forMaxima maxima: [CCLocalMaximum], count: Int) -> [CCLocalMaximum] {

        var maxima = maxima

        // If the count of maxima is higher than the requested count, perform distinct thresholding
        if maxima.count > count {

            var tempDistinctMaxima = maxima
            var distinctThreshold: CGFloat = 0.1

            // Decrease the threshold ten times. If this does not result in the wanted count
            for _ in 0...9 {
                // Get array with current distinct threshold
                tempDistinctMaxima = self.filterDistinct(maxima: maxima, threshold: distinctThreshold)

                // If this array has less than count, break and take the current sortedMaxima
                if tempDistinctMaxima.count <= count {
                    break;
                }

                // Keep this result (length is > count)
                maxima = tempDistinctMaxima;

                // Increase threshold by 0.05
                distinctThreshold += 0.05;
            }

            // Only take first count maxima
            maxima = Array(maxima.prefix(count))
        }

        return maxima;

    }

    // Orders maxima by brightness
    private func orderByBrightness(maxima: [CCLocalMaximum]) -> [CCLocalMaximum] {
        return maxima.sorted(by: { $0.brightness > $1.brightness })
    }

    // Orders maxima by darkness
    private func orderByDarkness(maxima: [CCLocalMaximum]) -> [CCLocalMaximum] {
        return maxima.sorted(by: { $0.brightness < $1.brightness })
    }
}
