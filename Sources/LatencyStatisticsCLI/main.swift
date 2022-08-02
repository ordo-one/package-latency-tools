import LatencyStatistics

func main() {
    let argc = CommandLine.argc
    guard argc == 2 else {
        print("There should be one argument - file name")
        return
    }

//    let fileName = CommandLine.arguments[1]

//    var statistics = LatencyStatistics()
//    statistics.process(fileName: fileName)
//    statistics.printStatistics();
}

main()
