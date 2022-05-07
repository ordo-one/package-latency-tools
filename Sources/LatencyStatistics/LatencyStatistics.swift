import Foundation
import Numerics

public let defaultPercentiles = [50.0, 80.0, 99.0, 99.9, 100.0]

public struct LatencyStatistics
{
    public let bucketCount = 64
    public let percentiles: [Double] // current percentiles we calculate
    public var percentileResults: [Int?]
    public var measurementBucketsPowerOfTwo: [Int] // we do 1, 2, 4, 8, ... bucketCount - histogram
    public var measurementBuckets: [Int] // 1..bucketCount - histogram

    public init(_ percentiles:[Double] = defaultPercentiles)
    {
        self.percentiles = percentiles
        measurementBucketsPowerOfTwo = [Int](repeating: 0, count: bucketCount)
        measurementBuckets = [Int](repeating: 0, count: bucketCount)
        percentileResults = [Int?](repeating: nil, count: self.percentiles.count)
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

    public mutating func calculate()
    {
        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) // grand total all sample count
        var accumulatedSamples = 0 // current accumulation of sample during processing
        var accumulatedSamplesPowerOfTwo = 0

        for currentBucket in 0 ..< bucketCount {
            accumulatedSamples += Int(measurementBuckets[currentBucket])
            accumulatedSamplesPowerOfTwo += Int(measurementBucketsPowerOfTwo[currentBucket])

            // Let's do percentiles for out linear buckets as far as possible
            // then we fall back to power of two for remainders
            for percentile in 0 ..< percentiles.count {
                if percentileResults[percentile] == nil {
                    if Double(accumulatedSamples)/Double(totalSamples) >= (percentiles[percentile] / 100) {
                        percentileResults[percentile] = currentBucket
                    } else if Double(accumulatedSamplesPowerOfTwo)/Double(totalSamples) >= (percentiles[percentile] / 100) {
                        percentileResults[percentile] = 1 << currentBucket
                    }
                }
            }
        }
    }
    
    public func output() -> String
    {
        var result = ""
        for percentile in 0 ..< percentiles.count {
            result += "\(percentiles[percentile]) <= \(percentileResults[percentile] ?? 0)μs \n"
        }
        return result
    }
}
