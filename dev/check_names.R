pkgs <- c("decisionfacets", "retestR", "coldstart", "driftwatch", "throughyear", "transDIF")
cran <- tools::CRAN_package_db()$Package
arch <- tryCatch({
  x <- readLines("https://cran.r-project.org/src/contrib/Archive/", warn = FALSE)
  m <- regmatches(x, regexpr('href="[^"/]+/"', x))
  gsub('href="|/"', "", m)
}, error = function(e) NA_character_)
bioc <- tryCatch(rownames(available.packages(repos = "https://bioconductor.org/packages/release/bioc")),
                 error = function(e) NA_character_)
cat("CRAN:", length(cran), "| CRAN archive:", length(arch), "| Bioconductor:", length(bioc), "\n\n")
for (p in pkgs) {
  hit <- function(v) { h <- v[tolower(v) == tolower(p)]; if (length(h)) paste(h, collapse = ",") else "-" }
  near <- unique(c(cran, arch))[agrepl(p, unique(c(cran, arch)), max.distance = 1, ignore.case = TRUE) &
                                  abs(nchar(unique(c(cran, arch))) - nchar(p)) <= 1]
  cat(sprintf("%-15s CRAN: %-12s archive: %-12s Bioc: %-10s similar: %s\n", p, hit(cran), hit(arch),
              hit(bioc), if (length(near)) paste(head(near, 5), collapse = ", ") else "-"))
}
