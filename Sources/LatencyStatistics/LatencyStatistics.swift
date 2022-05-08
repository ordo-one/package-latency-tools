import Foundation
import Numerics

public let defaultPercentiles = [50.0, 80.0, 99.0, 99.9, 100.0]

public struct LatencyStatistics
{
    public let bucketCount = 32
    public let linearBucketCount: Int
    public let percentiles: [Double] // current percentiles we calculate
    public var percentileResults: [Int?]
    public var measurementBucketsPowerOfTwo: [Int] // we do 1, 2, 4, 8, ... bucketCount - histogram
    public var measurementBuckets: [Int] // 1..bucketCount - histogram

    public init(linearBucketCount:Int = 100, percentiles:[Double] = defaultPercentiles)
    {
        self.linearBucketCount = linearBucketCount > 0 ? linearBucketCount : 1
        self.percentiles = percentiles
        measurementBucketsPowerOfTwo = [Int](repeating: 0, count: bucketCount)
        measurementBuckets = [Int](repeating: 0, count: self.linearBucketCount)
        percentileResults = [Int?](repeating: nil, count: self.percentiles.count)
    }

    
    @inlinable
    @inline(__always)
    public mutating func add(_ measurement: Int)
    {
        let bucket = measurement > 0 ? Int(ceil(log2(Double(measurement)))) : 0

        assert(bucket < bucketCount, "bucket >= \(bucketCount)")

        if bucket < bucketCount {
            measurementBucketsPowerOfTwo[bucket] += 1
        } else {
            measurementBucketsPowerOfTwo[bucketCount-1] += 1
        }

        let validBucketRange = 0..<linearBucketCount

        if validBucketRange.contains(measurement) {
            measurementBuckets[measurement] += 1
        } else {
            measurementBuckets[linearBucketCount-1] += 1
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

        // Let's do percentiles for out linear buckets as far as possible
        // then we fall back to power of two for remainders
        for currentBucket in 0 ..< (linearBucketCount-1) {
            accumulatedSamples += Int(measurementBuckets[currentBucket])

            for percentile in 0 ..< percentiles.count {
                if percentileResults[percentile] == nil &&
                    Double(accumulatedSamples)/Double(totalSamples) >= (percentiles[percentile] / 100) {
                    percentileResults[percentile] = currentBucket
                }
            }
        }
        for currentBucket in 0 ..< bucketCount {
            accumulatedSamplesPowerOfTwo += Int(measurementBucketsPowerOfTwo[currentBucket])

            for percentile in 0 ..< percentiles.count {
                if percentileResults[percentile] == nil &&
                    Double(accumulatedSamplesPowerOfTwo)/Double(totalSamples) >= (percentiles[percentile] / 100) {
                    percentileResults[percentile] = 1 << currentBucket
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
