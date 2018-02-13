
#library(SparkR, lib.loc= c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
#sc <- sparkR.init()

rdd <- SparkR:::textFile(sc, "mobydick.txt")
words <- SparkR:::flatMap(rdd, function(x) { unlist(strsplit(x, " ")) });

#wordCount <- SparkR:::lapply(words, function(word) { list(word, 1L) });
#counts <- SparkR:::reduceByKey(wordCount, "+", 2L);
#sortCount <- SparkR:::sortByKey(counts);
#output <- SparkR:::collectRDD(sortCount);

wordCount <- as.DataFrame(words);
counts <- count(groupBy(wordCount, "_1"));
sortCount <- orderBy(counts, "count")
output <- collect(sortCount);


sink("wc-result.data"); for(i in output) cat(i[[1]], ":", i[[2]], "\n"); sink();

