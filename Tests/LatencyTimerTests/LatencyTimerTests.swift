import XCTest
@testable import LatencyTimer
@testable import LatencyStatistics

final class LatencyTimerTests: XCTestCase {
    func testThatLatencyStatisticsCalculatesCorrectPercentilesWithLinear() throws {
        var latencyStats = LatencyStatistics.init(bucketCount: 10_000,
                                                  percentiles: [1.0, 33.0, 50.0, 100.0])
        for n in 0..<1_000 {
            latencyStats.add(n)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }

    func testThatLatencyStatisticsCalculatesCorrectPercentilesWithFPowerOfTwo() throws {
        var latencyStats = LatencyStatistics.init(bucketCount: 0,
                                                  percentiles: [1.0, 20.0, 33.0, 50.0, 100.0])
        for n in 0..<500 {
            latencyStats.add(n)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }

    func testThatLatencyStatisticsCalculatesCorrectPercentilesWithMixed() throws {
        var latencyStats = LatencyStatistics.init(bucketCount: 5,
                                                  percentiles: [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0])

        latencyStats.add(1) // 1
        latencyStats.add(2) // 2
        latencyStats.add(3) // 3
        latencyStats.add(4) // 4
        latencyStats.add(5) // 5
        latencyStats.add(6) // 8
        latencyStats.add(14) // 16
        latencyStats.add(30) // 32
        latencyStats.add(2500) // 4096
        latencyStats.add(400_000) // 524288
        latencyStats.add(400_000_000_000) // 524288

        latencyStats.calculate()
        print(latencyStats.output())
    }

    func testThatLatencyStatisticsCalculatesCorrectWith100Buckets() throws {
        var percentiles :[Double] = []
        for n in 1...100 {
            percentiles.append(Double(n))
        }
        var latencyStats = LatencyStatistics.init(bucketCount: 100,
                                                  percentiles: percentiles)
        for n in 1...100 {
            latencyStats.add(n)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }

    func testThatLatencyStatisticsCalculatesCorrectWith11Buckets() throws {
        var latencyStats = LatencyStatistics.init(bucketCount: 1)
        for _ in 1...100_000 {
            latencyStats.add(1)
        }
        latencyStats.calculate()
        print(latencyStats.output())
    }

}
