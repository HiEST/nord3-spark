val textFile = sc.textFile("mobydick.txt")
val counts = textFile.flatMap(line => line.split(" ")).map(word => (word, 1)).reduceByKey(_ + _)
val ranking = counts.sortBy(_._2, false)
ranking.saveAsTextFile("wc-result.data")
