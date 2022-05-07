import LatencyStatistics

func main()
{
    let argc = CommandLine.argc
    guard argc == 2 else {
        print("There should be one argument - file name")
        return
    }

    let fileName = CommandLine.arguments[1];

    var ls = LatencyStatistics()
//    ls.process(fileName: fileName)
//    ls.printStatistics();
}

main()
