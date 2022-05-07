import Foundation
import Numerics

public struct LatencyStatistics
{
    var l50, l80, l99, l99d9, l100: Int
    var measurementBuckets: [Int] // we do 1, 2, 4, 8, ... buckets
    let bucketCount = 64

    public init()
    {
        l50 = 0
        l80 = 0
        l99 = 0
        l99d9 = 0
        l100 = 0
        measurementBuckets = [Int](repeating: 0, count: bucketCount)
    }

    
    public mutating func add(_ measurement: Int64)
    {
        let bucket = Int(ceil(log2(Double(measurement))))
        measurementBuckets[bucket] += 1
    }
    
    public mutating func reset()
    {
        l50 = 0
        l80 = 0
        l99 = 0
        l99d9 = 0
        l100 = 0
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
        let totalSamples = measurementBuckets.reduce(0, +) // grand total all sample count
        var accumulatedSamples = 0 // current accumulation of sample during processing
        var p50: Int? = nil
        var p80: Int? = nil
        var p99: Int? = nil
        var p99d9: Int? = nil
        var p100: Int? = nil

        for currentBucket in 0 ..< bucketCount {
            accumulatedSamples += measurementBuckets[currentBucket]

            updatePercentile(percentile: &p50,
                             currentBucket: currentBucket,
                             accumulatedSamples: accumulatedSamples,
                             totalSamples: totalSamples,
                             threshold: 50)
            updatePercentile(percentile: &p80,
                             currentBucket: currentBucket,
                             accumulatedSamples: accumulatedSamples,
                             totalSamples: totalSamples,
                             threshold: 80)
            updatePercentile(percentile: &p99,
                             currentBucket: currentBucket,
                             accumulatedSamples: accumulatedSamples,
                             totalSamples: totalSamples,
                             threshold: 99)
            updatePercentile(percentile: &p99d9,
                             currentBucket: currentBucket,
                             accumulatedSamples: accumulatedSamples,
                             totalSamples: totalSamples,
                             threshold: 99.9)
            updatePercentile(percentile: &p100,
                             currentBucket: currentBucket,
                             accumulatedSamples: accumulatedSamples,
                             totalSamples: totalSamples,
                             threshold: 100)
        }

        l50 = p50 ?? 0
        l80 = p80 ?? 0
        l99 = p99 ?? 0
        l99d9 = p99d9 ?? 0
        l100 = p100 ?? 0
    }
    

    public func output() -> String
    {
        return "  50% <= \(l50)\n  80% <= \(l80)\n  99% <= \(l99)\n99.9% <= \(l99d9)\n 100% <= \(l100)"
    }
    
    private func format(_ number: Int) -> String
    {
        return "\(number) μs"
    }
    
    public func printStatistics()
    {
        print("  50% <= \(format(l50))")
        print("  80% <= \(format(l80))")
        print("  99% <= \(format(l99))")
        print("99.9% <= \(format(l99d9))")
        print(" 100% <= \(format(l100))")
    }
    
}
