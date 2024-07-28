# Load in required package
library(plumber)
# Run the API
api <- plumb("API.R")
api$run(host = "0.0.0.0", port = 8000)

