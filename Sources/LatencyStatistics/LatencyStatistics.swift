import Foundation
import Numerics

public let defaultPercentilesToCalculate = [50.0, 80.0, 99.0, 99.9, 100.0]
private let numberPadding = 10

/// A type that provides distribution / percentile calculations of latency measurements
public struct LatencyStatistics {
    public let bucketCountLinear: Int
    public let bucketCountPowerOfTwo = 32
    public var measurementBucketsLinear: [Int] // 1..bucketCount - histogram
    public var measurementBucketsPowerOfTwo: [Int] // we do 1, 2, 4, 8, ... bucketCount - histogram
    public let percentilesToCalculate: [Double] // current percentiles we calculate
    public var percentileResults: [Int?]
    public var bucketOverflowLinear = 0
    public var bucketOverflowPowerOfTwo = 0
    public var averageMeasurement = 0.0
    public var measurementCount = 0

    public init(bucketCount: Int = 100, percentiles: [Double] = defaultPercentilesToCalculate) {
        bucketCountLinear = bucketCount < 1 ? 1 : bucketCount + 1 // we don't use the zero bucket, so add one
        percentilesToCalculate = percentiles
        measurementBucketsPowerOfTwo = [Int](repeating: 0, count: bucketCountPowerOfTwo)
        measurementBucketsLinear = [Int](repeating: 0, count: bucketCountLinear)
        percentileResults = [Int?](repeating: nil, count: percentilesToCalculate.count)
    }

    /// Add a measurement for inclusion in statistics
    /// - Parameter measurement: A measurement expressed in microseconds
    @inlinable
    @inline(__always)
    public mutating func add(_ measurement: Int) {
        let validBucketRangePowerOfTwo = 0..<bucketCountPowerOfTwo
        let bucket = measurement > 0 ? Int(ceil(log2(Double(measurement)))) : 0

        averageMeasurement = (Double(measurementCount) * averageMeasurement + Double(measurement))
                            / Double(measurementCount + 1)
        measurementCount += 1

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

    /// Reset all acummulated statistics
    public mutating func reset() {
        averageMeasurement = 0.0
        measurementCount = 0
        bucketOverflowLinear = 0
        bucketOverflowPowerOfTwo = 0
        percentileResults.removeAll(keepingCapacity: true)
        measurementBucketsPowerOfTwo.removeAll(keepingCapacity: true)
        measurementBucketsLinear.removeAll(keepingCapacity: true)
    }

    /// Perform percentile calculations based on the accumulated statistics
    public mutating func calculateStatistics() {
        func calculatePercentiles(for measurementBuckets: [Int], totalSamples: Int, powerOfTwo: Bool) {
            var accumulatedSamples = 0 // current accumulation of sample during processing

            for currentBucket in 0 ..< measurementBuckets.count {
                accumulatedSamples += Int(measurementBuckets[currentBucket])

                for percentile in 0 ..< percentilesToCalculate.count {
                    if percentileResults[percentile] == nil &&
                        Double(accumulatedSamples)/Double(totalSamples) >= (percentilesToCalculate[percentile] / 100) {
                        percentileResults[percentile] = powerOfTwo ? 1 << currentBucket  : currentBucket
                    }
                }
            }
        }

        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) + bucketOverflowPowerOfTwo

        // Let's do percentiles for out linear buckets as far as possible, then fall back to power of two
        calculatePercentiles(for: measurementBucketsLinear, totalSamples: totalSamples, powerOfTwo: false)
        calculatePercentiles(for: measurementBucketsPowerOfTwo, totalSamples: totalSamples, powerOfTwo: true)
    }

    private func generateHistogram(for measurementBuckets: [Int], totalSamples: Int, powerOfTwo: Bool) -> String {
        var histogram = ""
        let bucketCount = measurementBuckets.count

        guard bucketCount > 0 else {
            return ""
        }

        let firstNonEmptyBucket = measurementBuckets.firstIndex(where: {$0 > 0}) ?? 0
        let lastNonEmptyBucket = measurementBuckets.lastIndex(where: {$0 > 0}) ?? 0

        for currentBucket in firstNonEmptyBucket ... lastNonEmptyBucket {
            var histogramMarkers = "\((powerOfTwo ? 1 << currentBucket : currentBucket).paddedString(to: numberPadding)) = "
            var markerCount = Int(((Double(measurementBuckets[currentBucket]) / Double(totalSamples)) * 100.0))
            // always print a single * if there's any samples in the bucket
            if measurementBuckets[currentBucket] > 0 && markerCount == 0 {
                markerCount = 1
            }

            for _ in 0 ..<  markerCount {
                histogramMarkers += "*"
            }
            histogram += histogramMarkers + "\n"

            if firstNonEmptyBucket == lastNonEmptyBucket && measurementBuckets[currentBucket] == 0 {
                histogram = ""
            }
        }
        return histogram
    }

    /// A printable text-based histogram suitable for display in a fixed-size font
    /// - Returns: The histogram - linear buckets
    public func histogramLinear() -> String {
        let totalSamples = measurementBucketsLinear.reduce(0, +) + bucketOverflowLinear
        var histogram = ""

        assert(measurementCount == totalSamples, "measurementCount != totalSamples")

        guard totalSamples > 0 else {
            return "Zero samples, no linear histogram available.\n"
        }

        if measurementBucketsLinear.count > 1 {
            histogram += "Linear histogram (\(totalSamples) samples): \n" + generateHistogram(for: measurementBucketsLinear,
                                                                       totalSamples: totalSamples,
                                                                       powerOfTwo: false)
            if bucketOverflowLinear > 0 {
                var histogramMarkers = ""
                for _ in 0 ..<  Int(((Double(bucketOverflowLinear) / Double(totalSamples)) * 100.0)) {
                    histogramMarkers += "*"
                }
                if histogramMarkers.count == 0 {
                    histogramMarkers += "*"
                }
                histogram += "\((measurementBucketsLinear.count - 1).paddedString(to: numberPadding)) > \(histogramMarkers)\n"
            }
            histogram += "\n"
        }

        return histogram
    }

    /// A printable text-based histogram suitable for display in a fixed-size font
    /// - Returns: The histogram - power of two buckets
    public mutating func histogramPowerOfTwo() -> String {
        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) + bucketOverflowPowerOfTwo
        var histogram = ""

        assert(measurementCount == totalSamples, "measurementCount != totalSamples")

        guard totalSamples > 0 else {
            return "Zero samples, no power of two histogram available.\n"
        }

        histogram += "Power of Two histogram (\(totalSamples) samples):\n" +
        generateHistogram(for: measurementBucketsPowerOfTwo,
                          totalSamples: totalSamples,
                          powerOfTwo: true)

        if bucketOverflowPowerOfTwo > 0 {
            var histogramMarkers = ""
            for _ in 0 ..<  Int(((Double(bucketOverflowPowerOfTwo) / Double(totalSamples)) * 100.0)) {
                histogramMarkers += "*"
            }
            if histogramMarkers.count == 0 {
                histogramMarkers += "*"
            }
            histogram += "\((1 << measurementBucketsPowerOfTwo.count).paddedString(to: numberPadding)) > \(histogramMarkers)\n"
        }

        return histogram

    }


    /// A printable text-based  percentile statistics suitable for display in a fixed-size font
    /// - Returns: The percentiles
    public mutating func percentileStatistics() -> String {
        let totalSamples = measurementBucketsPowerOfTwo.reduce(0, +) + bucketOverflowPowerOfTwo

        assert(measurementCount == totalSamples, "measurementCount != totalSamples")

        var result = "Percentile measurements (\(totalSamples) samples," +
                     " average \(String(format: "%.2f", averageMeasurement))):\n"

        guard totalSamples > 0 else {
            return "Zero samples, no percentile distribution available.\n"
        }

        calculateStatistics()

        for percentile in 0 ..< percentilesToCalculate.count {
            if percentileResults[percentile] != nil {
                result += "\((percentilesToCalculate[percentile]).paddedString(to: numberPadding)) <= \(percentileResults[percentile] ?? 0)μs \n"
            } else {
                result += "\((percentilesToCalculate[percentile]).paddedString(to: numberPadding))  > \(1 << bucketCountPowerOfTwo)μs \n"
            }
        }

        if bucketOverflowPowerOfTwo > 0 {
            result += "Warning: discarded out of bound samples with time > \(1 << bucketCountPowerOfTwo) = \(bucketOverflowPowerOfTwo)\n"
        }

        return result
    }

    /// A printable text-based histogram+percentiles suitable for display in a fixed-size font
    /// - Returns: All collected statistics
    public mutating func output() -> String {
        return percentileStatistics() + "\n" + histogramLinear() + "\n" + histogramPowerOfTwo()
    }
}

extension Int {
     func paddedString(to: Int) -> String {
        var result = String(self)
         for _ in 0 ..< (to - result.count) {
            result = " " + result
        }
        return result
    }
}

extension Double {
    func paddedString(to: Int) -> String {
        var result = String(self)
        for _ in 0 ..< (to - result.count) {
            result = " " + result
        }
        return result
    }
}
