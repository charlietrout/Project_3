# Use a base R image from Rocker
FROM rocker/r-ver:4.2.2

# Install system dependencies for R packages and plumber
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install R packages required for the API
RUN R -e "install.packages(c('plumber', 'caret', 'dplyr', 'readr'))"

# Set the working directory
WORKDIR /app

# Copy the R script and dataset into the container
COPY API.R /app/API.R
COPY Run_API.R /app/Run_API.R
COPY diabetes_binary_health_indicators_BRFSS2015.csv /app/diabetes_binary_health_indicators_BRFSS2015.csv

# Expose the port that the API will run on
EXPOSE 8000

# Command to run the API script
CMD ["Rscript", "Run_API.R"]
