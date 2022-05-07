import Foundation
import Numerics

public let defaultPercentiles = [50.0, 80.0, 99.0, 99.9, 100.0]

public struct LatencyStatistics
{
    public let bucketCount = 64
    public let percentiles: [Double] // current percentiles we calculate
    public var percentileResults: [Int]
    public var measurementBucketsPowerOfTwo: [Int] // we do 1, 2, 4, 8, ... bucketCount - histogram
    public var measurementBuckets: [Int] // 1..bucketCount - histogram

    public init(_ percentiles:[Double] = defaultPercentiles)
    {
        self.percentiles = percentiles
        measurementBucketsPowerOfTwo = [Int](repeating: 0, count: bucketCount)
        measurementBuckets = [Int](repeating: 0, count: bucketCount)
        percentileResults = [Int](repeating: 0, count: self.percentiles.count)
    }

    
    @inlinable
    @inline(__always)
    public mutating func add(_ measurement: Int)
    {
        let validBucketRange = 0..<bucketCount
        let bucket = Int(ceil(log2(Double(measurement))))
        measurementBucketsPowerOfTwo[bucket] += 1

        if validBucketRange.contains(measurement) {
            measurementBuckets[measurement] += 1
        } else {
            measurementBuckets[bucketCount-1] += 1
        }

    }
    
    public mutating func reset()
    {
        percentileResults.removeAll(keepingCapacity: true)
        measurementBucketsPowerOfTwo.removeAll(keepingCapacity: true)
        measurementBuckets.removeAll(keepingCapacity: true)
    }

    internal func updatePercentile(percentile: inout Int?,
                                   currentBucket: Int,
                                   accumulatedSamples: Int,
                                   totalSamples: Int,
                                   threshold: Double) {
        if percentile == nil && Double(accumulatedSamples)/Double(totalSamples) >= (threshold / 100) {
            percentile = 1 << currentBucket
        }
    }

    public mutating func calculate()
    {
        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) // grand total all sample count
        var accumulatedSamples = 0 // current accumulation of sample during processing
        var currentPercentiles = [Int?](repeating: 0, count: self.percentiles.count)

        for currentBucket in 0 ..< bucketCount {
            accumulatedSamples += Int(measurementBucketsPowerOfTwo[currentBucket])

            for percentile in 0 ..< percentiles.count {
                updatePercentile(percentile: &currentPercentiles[percentile],
                                 currentBucket: currentBucket,
                                 accumulatedSamples: accumulatedSamples,
                                 totalSamples: totalSamples,
                                 threshold: percentiles[percentile])
            }
        }
    }
    
    public func output() -> String
    {
        var result = ""
        for percentile in 0 ..< percentiles.count {
            result += "\(percentiles[percentile]) <= \(percentileResults[percentile])μs \n"
        }
        return result
    }
}
