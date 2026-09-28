# Read a win-builder check log and print its notes/warnings/errors.
for (id in c("AlNVLcddV6AM", "AINVLcddV6AM")) {
  x <- tryCatch(readLines(paste0("https://win-builder.r-project.org/", id, "/00check.log"), warn = FALSE),
                error = function(e) NULL)
  if (is.null(x)) next
  cat("log", id, "\n")
  for (j in grep("NOTE|WARNING|ERROR", x)) cat(x[j:min(length(x), j + 10)], sep = "\n")
  cat(tail(x, 2), sep = "\n")
  break
}
