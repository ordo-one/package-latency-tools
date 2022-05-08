import XCTest
@testable import LatencyTimer
@testable import LatencyStatistics

final class LatencyTimerTests: XCTestCase {
    func testThatLatencyStatisticsCalculatesCorrectPercentilesWithLinear() throws {
        var latencyStats = LatencyStatistics.init(linearBucketCount: 10_000,
                                                  percentiles: [1.0, 33.0, 50.0, 100.0])
        for n in 0..<1_000 {
            latencyStats.add(n)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }
    func testThatLatencyStatisticsCalculatesCorrectPercentilesWithFPowerOfTwo() throws {
        var latencyStats = LatencyStatistics.init(linearBucketCount: 0,
                                                  percentiles: [1.0, 20.0, 33.0, 50.0, 100.0])
        for n in 0..<500 {
            latencyStats.add(n)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }
    func testThatLatencyStatisticsCalculatesCorrectPercentilesWithMixed() throws {
        var latencyStats = LatencyStatistics.init(linearBucketCount: 600,
                                                  percentiles: [1.0, 5.0, 33.0, 50.0, 80.0, 99.0, 99.9, 100.0])
        for n in 0..<1000 {
            latencyStats.add(n)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }
}
