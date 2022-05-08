import Foundation
import Numerics

public let defaultPercentilesToCalculate = [50.0, 80.0, 99.0, 99.9, 100.0]

public struct LatencyStatistics
{
    public let bucketCountLinear: Int
    public let bucketCountPowerOfTwo = 32
    public var measurementBucketsLinear: [Int] // 1..bucketCount - histogram
    public var measurementBucketsPowerOfTwo: [Int] // we do 1, 2, 4, 8, ... bucketCount - histogram
    public let percentilesToCalculate: [Double] // current percentiles we calculate
    public var percentileResults: [Int?]
    public var bucketOverflowLinear = 0
    public var bucketOverflowPowerOfTwo = 0

    public init(bucketCount:Int = 100, percentiles:[Double] = defaultPercentilesToCalculate)
    {
        bucketCountLinear = bucketCount < 1 ? 1 : bucketCount + 1 // we don't use the zero bucket, so add one
        percentilesToCalculate = percentiles
        measurementBucketsPowerOfTwo = [Int](repeating: 0, count: bucketCountPowerOfTwo)
        measurementBucketsLinear = [Int](repeating: 0, count: bucketCountLinear)
        percentileResults = [Int?](repeating: nil, count: percentilesToCalculate.count)
    }

    
    @inlinable
    @inline(__always)
    public mutating func add(_ measurement: Int)
    {
        let validBucketRangePowerOfTwo = 0..<bucketCountPowerOfTwo
        let bucket = measurement > 0 ? Int(ceil(log2(Double(measurement)))) : 0

        if validBucketRangePowerOfTwo.contains(bucket) {
            measurementBucketsPowerOfTwo[bucket] += 1
        } else {
            bucketOverflowPowerOfTwo += 1
        }

        let validBucketRangeLinear = 0..<bucketCountLinear

        if validBucketRangeLinear.contains(measurement) {
            measurementBucketsLinear[measurement] += 1
        } else {
            bucketOverflowLinear += 1
        }

    }
    
    public mutating func reset()
    {
        bucketOverflowLinear = 0
        bucketOverflowPowerOfTwo = 0
        percentileResults.removeAll(keepingCapacity: true)
        measurementBucketsPowerOfTwo.removeAll(keepingCapacity: true)
        measurementBucketsLinear.removeAll(keepingCapacity: true)
    }

    public mutating func calculate()
    {
        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) // grand total all sample count
        var accumulatedSamples = 0 // current accumulation of sample during processing
        var accumulatedSamplesPowerOfTwo = 0

        // Let's do percentiles for out linear buckets as far as possible
        // then we fall back to power of two for remainders
        for currentBucket in 0 ..< bucketCountLinear {
            accumulatedSamples += Int(measurementBucketsLinear[currentBucket])

            for percentile in 0 ..< percentilesToCalculate.count {
                if percentileResults[percentile] == nil &&
                    Double(accumulatedSamples)/Double(totalSamples) >= (percentilesToCalculate[percentile] / 100) {
                    percentileResults[percentile] = currentBucket
                }
            }
        }
        for currentBucket in 0 ..< bucketCountPowerOfTwo {
            accumulatedSamplesPowerOfTwo += Int(measurementBucketsPowerOfTwo[currentBucket])

            for percentile in 0 ..< percentilesToCalculate.count {
                if percentileResults[percentile] == nil &&
                    Double(accumulatedSamplesPowerOfTwo)/Double(totalSamples) >= (percentilesToCalculate[percentile] / 100) {
                    percentileResults[percentile] = 1 << currentBucket
                }
            }
        }
    }

    public func histogramPowerOfTwo() -> String {
        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) // grand total all sample count
        var histogram = ""
        var firstNonEmptyBucket = bucketCountPowerOfTwo

        for currentBucket in 1 ..< bucketCountPowerOfTwo {
            if measurementBucketsPowerOfTwo[bucketCountPowerOfTwo - currentBucket] > 0 {
                firstNonEmptyBucket = bucketCountPowerOfTwo - currentBucket
                break
            }
        }

        for currentBucket in 0 ..< firstNonEmptyBucket {
            var histogramMarkers = "\(currentBucket) = "
            for _ in 0 ..< Int(((Double(measurementBucketsPowerOfTwo[currentBucket]) / Double(totalSamples)) * 80.0)) {
                histogramMarkers += "*"
            }
            histogram += histogramMarkers + "\n"
        }
        return histogram
    }

    public func output() -> String
    {
        var result = ""

        for percentile in 0 ..< percentilesToCalculate.count {
            result += "\(percentilesToCalculate[percentile]) <= \(percentileResults[percentile] ?? 0)μs \n"
        }

        if bucketOverflowPowerOfTwo > 0 {
            result += "Warning: discarded out of bound samples with time > \(1 << bucketCountPowerOfTwo) = \(bucketOverflowPowerOfTwo)\n"
        }

        return result + histogramPowerOfTwo()
    }
}
