# Adapted from the approaches used by Qi et al. Br J Gen Pract. 2023 Apr 27;73(730):e332-e339; and Schaffer et al. BMC Med Res Methodol 2021;21(1): 58.

# install.packages("doBy")
# install.packages("astsa")
# install.packages("ggplot2")
# install.packages("sweep")
# install.packages("forecast")
# install.packages("timetk")
# install.packages("recipes")
# install.packages("fs")
# install.packages("here")
# install.packages("svglite")
# install.packages("gridExtra")
# install.packages("stringr")
# install.packages("lubridate")
# install.packages("strucchange")
# install.packages("prophet")

library(dplyr)
library(ggplot2)
library(fs)
library(zoo)
library(svglite)
library(here)
library(doBy)
library(astsa)
library(sweep)
library(forecast)
library(timetk)
library(gridExtra)
library(stringr)
library(lubridate)

sessionInfo()

# Create directories if needed
dir_create(here::here("output/figures"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output/tables"), showWarnings = FALSE, recurse = TRUE)

sink("logs/sarima_log.txt")

# Incidence data - use rounded age and sex-standardised rates for incidence rates
df <-read.csv("output/tables/arima_standardised.csv")

# Rename variables in the data and ensure dates in correct format
names(df)[names(df) == "numerator"] <- "count"
df<- df %>% select(disease, year, mo_year_diagn, incidence, count) 
df$month <- substr(df$mo_year_diagn, 1, 3)
df$mo_year_diagn <- gsub("-", " ", df$mo_year_diagn)
df$mon_year <- df$mo_year_diagn
df$mo_year_diagn <- as.Date(paste0("01 ", df$mo_year_diagn), format = "%d %b %Y")
month_lab <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

# Extract list of diseases from data
disease_list <- unique(df$disease)

# Initialize index for axis labelling
index_axis <- 1

# Define start and end dates from the data
start_date <- min(df$mo_year_diagn, na.rm = TRUE)
end_date   <- max(df$mo_year_diagn, na.rm = TRUE)

# Generate vectors from the above
start <- c(year(start_date), month(start_date))
end <- c(year(end_date), month(end_date))

# Define intervention date (March 2020)
intervention <- c(2020, 3)
intervention_date <- as.Date(paste0(intervention[1], "-", intervention[2], "-01"), format = "%Y-%m-%d")

# Define number of months before intervention
n_preintervention <- (intervention[1] - start[1]) * 12 + (intervention[2] - start[2])
print(n_preintervention)

# Define max number of months and years (rounded up) in series
max_index <- (end[1] - start[1]) * 12 + (end[2] - start[2]) + 1
print(max_index)
max_years <- ceiling(max_index / 12)

# Define the variables to loop over
variables <- c("incidence")

# Loop through diseases
for (j in 1:length(disease_list)) {
  
  dis <- disease_list[j]
  df_dis <- df[df$disease == dis, ]
  df_dis <- df_dis %>%  mutate(index=1:n()) #create an index variable
  
  # Set titles based on the disease abbreviation
  if (dis == "rheumatoid") {
    dis_title <- "Rheumatoid Arthritis"
  } else if (dis == "copd") {
    dis_title <- "COPD"
  } else if (dis == "crohns_disease") {
    dis_title <- "Crohn's Disease"
  } else if (dis == "dm_type2") {
    dis_title <- "Diabetes Mellitus Type 2"
  } else if (dis == "chd") {
    dis_title <- "Coronary Heart Disease"
  } else if (dis == "ckd") {
    dis_title <- "Chronic Kidney Disease"
  } else if (dis == "coeliac") {
    dis_title <- "Coeliac Disease"
  } else if (dis == "pmr") {
    dis_title <- "Polymyalgia Rheumatica"
  } else if (dis == "depression_broad") {
    dis_title <- "Depression and depressive symptoms"
  } else if (dis == "stroke") {
    dis_title <- "Stroke and TIA"
  } else {
    dis_title <- str_to_title(str_replace_all(dis, "_", " "))
  }
  
  # Label y-axis (for combined graph)
  if (index_axis %in% c(1, 6, 11, 16)) {
    y_label <- "Monthly incidence rate per 100,000"
  } else {
    y_label <- ""
  }
  
  # Label x-axis (for combined graph)
  if (index_axis %in% c(16, 17, 18, 19)) {
    #x_label <- "Year"
    x_label <- ""
  } else {
    x_label <- ""
  }

  # Keep data from before intervention date (March 2020)
  df_obs <- df_dis[which(df_dis$index<=n_preintervention),]
  
  # Loop through incidence (+/- counts if needed)
  for (i in 1:length(variables)) {
    var <- variables[i]

    # Convert to time series object 
    df_obs_rate <- ts(df_obs[[var]], frequency=12, start=start)
    assign(paste0("ts_", var), df_obs_rate)
    
    # Plot time series for raw data; 1st order difference; 1st order seasonal difference
    svg(filename = paste0("output/figures/raw_pre_covid_", var, "_", dis, ".svg"), width = 8, height = 6)
    plot(df_obs_rate, ylim=c(), type='l', col="blue", xlab="Year", ylab=y_label)
    dev.off()
    svg(filename = paste0("output/figures/differenced_pre_covid_", var, "_", dis, ".svg"), width = 8, height = 6)
    plot(diff(df_obs_rate),type = "l");abline(h=0,col = "red")
    dev.off()
    svg(filename = paste0("output/figures/seasonal_pre_covid_", var, "_", dis, ".svg"), width = 8, height = 6)
    plot(diff(diff(df_obs_rate),12),type = "l");abline(h=0,col = "red")
    dev.off()

    # Use auto.arima to fit the initial SARIMA model (identifying terms that optimise BIC/AIC); then for models with sub-optimal fit on visual inspection/diagnostics, explore different terms (optimal terms shown)
    if (dis == "asthma") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1))
    } else if (dis == "atopic_dermatitis") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,1,1), seasonal = c(0,1,1))
    } else if (dis == "chd") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(1,0,0), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "ckd") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,1), seasonal = c(0,1,2))
    } else if (dis == "coeliac") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(1,1,1), include.drift = TRUE)
    } else if (dis == "copd") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "crohns_disease") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "dementia") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(3,0,0), seasonal = c(0,1,1))
    } else if (dis == "depression") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "dm_type2") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(4,0,1), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "epilepsy") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(1,1,1))
    } else if (dis == "heart_failure") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(3,0,0), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "multiple_sclerosis") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(1,0,0), seasonal = c(1,1,0))
    } else if (dis == "osteoporosis") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1))
    } else if (dis == "pmr") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,1), seasonal = c(1,1,0), include.drift = TRUE)
    } else if (dis == "psoriasis") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1), include.drift = TRUE)
    } else if (dis == "rheumatoid") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1))
    } else if (dis == "stroke") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,2), seasonal = c(1,1,0))
    } else if (dis == "ulcerative_colitis") {
      suggested.rate <- forecast::Arima(df_obs_rate, order = c(0,0,0), seasonal = c(0,1,1))
    } else {
     suggested.rate<- auto.arima(df_obs_rate, max.p = 5, max.q = 5,  max.P = 2,  max.Q = 2, stepwise=FALSE, trace=TRUE)
    }
      
    print(dis)  
    print(suggested.rate)
    
    # Non-seasonal differences suggested by KPSS; then explore diagnostics to see if this is appropriate; also explore alternative models that include drift constants
    d <- ndiffs(df_obs_rate) 
    print(paste("Non-seasonal differences:", d))

    # AIC
    aic_value <- AIC(suggested.rate)
    print(paste("AIC:", round(aic_value, 2)))
    
    # BIC
    bic_value <- BIC(suggested.rate)
    print(paste("BIC:", round(bic_value, 2)))
    
    # Sigma2 (residual variance)
    sigma2_value <- suggested.rate$sigma2
    print(paste("Sigma^2:", round(sigma2_value, 2)))
    
    # Log-likelihood
    loglik_value <- logLik(suggested.rate)
    print(paste("Log Likelihood:", round(as.numeric(loglik_value), 2)))
    
    m1.rate <-suggested.rate
    m1.rate

    # Check residual diagnostics
    res <- residuals(m1.rate)
    
    par(mfrow = c(2,2))
    plot(res, main = "Residuals", ylab = "Residuals")
    acf(res, main = "Residuals ACF", ylab = "ACF")
    pacf(res, main = "Residuals PACF", ylab = "PACF")
    hist(res, main = "Residuals Histogram", xlab = "Residuals", ylab = "Density", col = "lightgray")
    par(mfrow = c(1,1))
    dev.off()
    
    theme_centered <- theme(plot.title = element_text(hjust = 0.5))
    
    p1 <- autoplot(ts(res)) +
      ggtitle("Residuals") +
      xlab("Time (months)") + ylab("Residuals") +
      theme_centered
    
    p2 <- ggAcf(res, lag.max = 36) +
      ggtitle("Residuals ACF") + ylab("ACF") +
      theme_centered
    
    p3 <- ggPacf(res, lag.max = 36) +
      ggtitle("Residuals PACF") + ylab("PACF") +
      theme_centered
    
    p4 <- ggplot(data.frame(res = res), aes(x = res)) +
      geom_histogram(aes(y = ..density..), bins = 30, fill = "lightgray", color = "black") +
      stat_function(fun = dnorm, args = list(mean = mean(res), sd = sd(res)), color = "red", size = 0.5) +
      ggtitle("Residuals Histogram") +
      xlab("Residuals") + ylab("Density") +
      theme_centered
    
    n <- length(res)
    k <- length(coef(m1.rate))
    lags <- unique(pmin(c(12, 24), n - 1))
    
    k_eff <- function(m) max(0, min(k, m - 1))
    
    mk_lb_str <- function(m) {
      lb <- Box.test(res, lag = m, type = "Ljung-Box", fitdf = k_eff(m))
      sprintf("Q(%d): p = %s", m, formatC(lb$p.value, format = "f", digits = 2))
    }
    
    # RMSE
    y <- as.numeric(df_obs_rate)
    y_hat <- as.numeric(fitted(m1.rate))
    
    # RMSE (absolute)
    rmse <- sqrt(mean((y - y_hat)^2, na.rm = TRUE))
    
    # Normalized RMSE as % of the mean
    nrmse <- rmse / mean(y, na.rm = TRUE) * 100
    
    # Bai–Perron and CUSUM tests
    bp_str <- NULL
    cusum_str <- NULL
    
    if (requireNamespace("strucchange", quietly = TRUE)) {
      library(strucchange)
      
      # Bai–Perron test on the series with a minimum segment size
      bp_full <- breakpoints(df_obs_rate ~ 1, h = max(12, frequency(df_obs_rate)))
      
      # Selects optimal number of structural breaks by BIC
      bic_vals <- BIC(bp_full)
      k_grid <- 0:(length(bic_vals) - 1)
      k_bp <- k_grid[which.min(bic_vals)]
      
      # Extract break dates (if any)
      if (k_bp > 0) {
        bp_k <- breakpoints(bp_full, breaks = k_bp)
        tt <- time(df_obs_rate)
        bd_times <- breakdates(bp_k)
        bd_row   <- sapply(bd_times, function(bt) which.min(abs(tt - bt)))
        bd_dates <- df_obs$mo_year_diagn[bd_row]
        bp_str <- sprintf("Bai–Perron: k=%d; breaks=%s",
                          k_bp, paste(as.character(bd_dates), collapse = ", "))
      } else {
        bp_str <- "Bai–Perron: k=0 (no breaks)"
      }
      
      # CUSUM test on residuals
      cusum_fit <- sctest(res ~ 1, type = "OLS-CUSUM")
      cusum_str <- sprintf("CUSUM: p = %s", formatC(cusum_fit$p.value, format = "f", digits = 2))
    }
    
    cap <- paste0(
      "RMSE = ", formatC(rmse, format = "f", digits = 2),
      " (", formatC(nrmse, format = "f", digits = 1), "% of mean) | ",
      "Ljung–Box test results: ",
      paste(vapply(lags, mk_lb_str, character(1)), collapse = " | ")
    )
    
    # Append Bai–Perron and CUSUM strings when computed
    bp_cusum <- paste(na.omit(c(bp_str, cusum_str)), collapse = " | ")
    if (nzchar(bp_cusum)) {
      cap <- paste(cap, bp_cusum, sep = "\n")
    }
    
    caption_grob <- grid::textGrob(
      cap, x = 0.5, hjust = 0.5,
      gp = grid::gpar(fontsize = 12, lineheight = 1.1)
    )
    
    g <- gridExtra::arrangeGrob(
      p1, p2, p3, p4, ncol = 2,
      bottom = caption_grob
    )
    
    ggsave(sprintf("output/figures/auto_residuals_%s_%s.svg", var, as.character(dis)[1]), plot = g, width = 8, height = 6, device = "svg")
    #ggsave(sprintf("output/figures/auto_residuals_%s_%s.png", var, as.character(dis)[1]), plot = g, width = 8, height = 6, device = "png")

    # Forecast from March 2020 and convert to time series object
    fc.rate  <- forecast(m1.rate, h = (max_index - n_preintervention), level = 95, bootstrap=TRUE, npaths=10000)
  
    # Forecasted rates 
    fc.ratemean <- ts(as.numeric(fc.rate$mean), start=intervention, frequency=12)
    fc.ratelower <- ts(as.numeric(fc.rate$lower), start=intervention, frequency=12) # Lower 95% prediction interval
    fc.rateupper <- ts(as.numeric(fc.rate$upper), start=intervention, frequency=12) # Upper 95% prediction interval
    
    # Flatten the matrix into a vector
    fc_rate<- data.frame(
      YearMonth = as.character(as.yearmon(time(fc.rate$mean))),
      mean = as.numeric(as.matrix(fc.rate$mean)),
      lower = as.numeric(as.matrix(fc.rate$lower)),
      upper = as.numeric(as.matrix(fc.rate$upper))
    )
  
    df_new <- df_dis %>% left_join(fc_rate, by = c("mon_year" = "YearMonth"))
    df_new$mean <- ifelse(is.na(df_new$mean), df_new[[var]], df_new$mean) #If NA (i.e. pre-forecast), replace as observed incidence
    df_new$lower <- ifelse(is.na(df_new$lower), df_new[[var]], df_new$lower) #If NA (i.e. pre-forecast), replace as observed incidence
    df_new$upper <- ifelse(is.na(df_new$upper), df_new[[var]], df_new$upper) #If NA (i.e. pre-forecast), replace as observed incidence
    
    df_new <- df_new %>%
      arrange(index) %>%
      mutate(moving_average = rollmean(get(var), k = 3, fill = NA, align = "center"))
    
    df_new <- df_new %>%
      arrange(index) %>%
      mutate(mean_ma = rollmean(mean, k = 3, fill = NA, align = "center"))
    
    # Save a table of values
    write.csv(df_new, file = paste0("output/tables/values_", var, "_", dis, ".csv"), row.names = FALSE)
  
    # Plot observed and expected graphs
    c1<- 
      ggplot(data = df_new,aes(x = mo_year_diagn))+
      geom_point(aes(y = .data[[var]]), color="#5E716A", alpha = 0.25, size=1.5)+
      geom_line(aes(y = moving_average), color = "#5E716A", linetype = "solid", size=0.70)+
      geom_point(data = df_new %>% filter(mo_year_diagn >= intervention_date), aes(y = mean), color="orange", alpha = 0.25, size=1.5)+
      geom_line(data = df_new %>% filter(mo_year_diagn >= intervention_date), aes(y = mean_ma), color = "orange", linetype = "solid", size=0.65)+
      geom_ribbon(data = df_new %>% filter(mo_year_diagn >= intervention_date), aes(ymin = lower, ymax = upper), alpha = 0.3, fill = "grey")+
      geom_vline(xintercept = as.numeric(intervention_date), linetype = "dashed", color = "grey")+
      scale_x_date(breaks = seq(as.Date(paste0(start[1], "-01-01")), as.Date(paste0(end[1] + 1, "-01-01")), by = "2 years"), date_labels = "%Y")+
      theme_minimal()+
      xlab(x_label)+
      ylab(y_label)+
      theme(
        legend.title = element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.line = element_line(color = "grey"),
        axis.ticks = element_line(color = "grey"),
        axis.text = element_text(size = 10, color = "black"),
        axis.title.x = element_text(size = 12, margin = margin(t = 5)),
        axis.title.y = element_text(size = 12, margin = margin(r = 5)), 
        plot.title = element_text(size = 14, hjust = 0.5, face = "plain") 
      ) +
      ggtitle(dis_title)
    
    saveRDS(c1, file = paste0("output/figures/obs_pred_", var, "_", dis, ".rds"))
    ggsave(filename = paste0("output/figures/obs_pred_", var, "_", dis, ".svg"), plot = c1, width = 8, height = 6, device = "svg")
    #ggsave(filename = paste0("output/figures/obs_pred_", var, "_", dis, ".png"), plot = c1, width = 8, height = 6, device = "png")
    
    print(c1)
    
    # Store y-axis values for Prophet sensitivity analyses
    gb <- ggplot_build(c1)
    pp <- gb$layout$panel_params[[1]]
    
    y_limits <- if (!is.null(pp$y.range)) pp$y.range else pp$y$range$range
    y_breaks <- if (!is.null(pp$y.major)) pp$y.major else pp$y$breaks

    # Calculate absolute and relative differences between observed and expected values at different time intervals
    a<- c(n_preintervention, (n_preintervention + 12), (n_preintervention + 24), (n_preintervention + 36), n_preintervention)
    b<- c((n_preintervention + 12), (n_preintervention + 24), (n_preintervention + 36), max_index, max_index)
    
    results_list <- list()
    
    for (i in 1:5) {
      
      observed_val <- df_new %>%
        filter(index > a[i] & index <= b[i]) %>%
        summarise(observed = sum(get(var))) %>%
        select(observed)
      
      predicted_val <- df_new %>%
        filter(index > a[i] & index <= b[i]) %>%
        mutate(se = (upper - lower) / (2 * 1.96)) %>%
        summarise(sum_pred_rate = sum(mean), total_var = sum(se^2)) %>%
        mutate(
          sum_pred_rate_l = (sum_pred_rate - (1.96 * sqrt(total_var))),
          sum_pred_rate_u = (sum_pred_rate + (1.96 * sqrt(total_var)))
        ) %>%
        select(sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u)
      
      observed_predicted_rate <- merge(observed_val, predicted_val)
      
      observed_predicted_rate <- observed_predicted_rate %>%
        mutate(change_rate = observed - sum_pred_rate,
               change_ratelow = observed - sum_pred_rate_l,
               change_ratehigh = observed - sum_pred_rate_u, 
               change_rate_per = (observed - sum_pred_rate) * 100 / sum_pred_rate,
               change_rate_per_low = (observed - sum_pred_rate_l) * 100 / sum_pred_rate_l, 
               change_rate_per_high = (observed - sum_pred_rate_u) * 100 / sum_pred_rate_u
        )
      
      # Store the result for this iteration in the list
      results_list[[i]] <- observed_predicted_rate %>%
        mutate(
          observed = round(observed, 2),
          sum_pred_rate = round(sum_pred_rate, 2),
          sum_pred_rate_l = round(sum_pred_rate_l, 2),
          sum_pred_rate_u = round(sum_pred_rate_u, 2),
          change_rate = round(change_rate, 2),
          change_ratelow = round(change_ratelow, 2),
          change_ratehigh = round(change_ratehigh, 2),
          change_rate_per = round(change_rate_per, 2),
          change_rate_per_low = round(change_rate_per_low, 2),
          change_rate_per_high = round(change_rate_per_high, 2)
        )
      
      if (i == 1) {
        rates.summary <- results_list[[i]] %>%
          select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                 change_rate, change_ratelow, change_ratehigh,
                 change_rate_per, change_rate_per_low, change_rate_per_high)
        colnames(rates.summary)[1:10] <- paste0(colnames(rates.summary)[1:10], ".2020")
      } else if (i == 2) {
        current_summary <- results_list[[i]] %>%
          select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                 change_rate, change_ratelow, change_ratehigh,
                 change_rate_per, change_rate_per_low, change_rate_per_high)
        colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".2021")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      } else if (i == 3) {
        current_summary <- results_list[[i]] %>%
          select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                 change_rate, change_ratelow, change_ratehigh,
                 change_rate_per, change_rate_per_low, change_rate_per_high)
        colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".2022")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      } else if (i == 4) {
        current_summary <- results_list[[i]] %>%
          select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                 change_rate, change_ratelow, change_ratehigh,
                 change_rate_per, change_rate_per_low, change_rate_per_high)
        colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".202324")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      } else if (i == 5) {
        current_summary <- results_list[[i]] %>%
          select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                 change_rate, change_ratelow, change_ratehigh,
                 change_rate_per, change_rate_per_low, change_rate_per_high)
        colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".total")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      }
    }
    
    rates.summary <- rates.summary %>%
      mutate(disease = dis_title) %>% 
      mutate(measure = var) %>% 
      select(measure, everything()) %>% 
      select(disease, everything()) 
    
    # Print summary table
    print(rates.summary)
    
    # Output to csv
    new_row <- rates.summary
    file_name <- "output/tables/change_incidence_byyear.csv"
    
    # Check if the file exists
    if (file.exists(file_name)) {
      existing_data <- read.csv(file_name)
      updated_data <- rbind(existing_data, new_row)
      write.csv(updated_data, file_name, row.names = FALSE)
    } else {
      write.csv(new_row, file_name, row.names = FALSE)
    }
    
    # Sensitivity analysis using Prophet forecasting method
    if (requireNamespace("prophet", quietly = TRUE)) {
    
      library(prophet)
      
      df_prop_train <- df_obs %>%
        dplyr::transmute(ds = as.Date(mo_year_diagn), y = .data[[var]])
      
      m.prophet <- prophet(
        df_prop_train,
        yearly.seasonality = TRUE,
        weekly.seasonality = FALSE,
        daily.seasonality = FALSE,
        seasonality.mode = "additive",
        interval.width = 0.95
      )
      
      future <- make_future_dataframe(m.prophet, periods = (max_index - n_preintervention), freq = "month")
      
      cut <- as.POSIXct(intervention_date, tz = "UTC")
      
      fc_prophet <- predict(m.prophet, future) %>%
        dplyr::mutate(ds = as.POSIXct(ds, tz = "UTC")) %>%
        dplyr::filter(ds >= cut) %>%
        dplyr::transmute(
          YearMonth = format(ds, "%b %Y"),
          mean_prophet = yhat,
          lower_prophet = yhat_lower,
          upper_prophet = yhat_upper
        )
      
      df_new2 <- df_dis %>%
        dplyr::left_join(fc_prophet, by = c("mon_year" = "YearMonth")) %>%
        dplyr::mutate(
          mean = ifelse(is.na(mean_prophet), .data[[var]], mean_prophet),
          lower = ifelse(is.na(lower_prophet), .data[[var]], lower_prophet),
          upper = ifelse(is.na(upper_prophet), .data[[var]], upper_prophet)
        ) %>%
        dplyr::arrange(index) %>%
        dplyr::mutate(
          moving_average = zoo::rollmean(.data[[var]], k = 3, fill = NA, align = "center"),
          mean_ma = zoo::rollmean(mean, k = 3, fill = NA, align = "center")
        )
      
      c_prophet <-
        ggplot(df_new2, aes(x = mo_year_diagn)) +
        geom_point(aes(y = .data[[var]]), color = "#5E716A", alpha = 0.25, size = 1.5)+
        geom_line(aes(y = moving_average), color = "#5E716A", linewidth = 0.7)+
        geom_ribbon(data = df_new2 %>% dplyr::filter(mo_year_diagn >= intervention_date), aes(ymin = lower, ymax = upper), alpha = 0.18, fill = "#2c7fb8")+
        geom_point(data = df_new2 %>% dplyr::filter(mo_year_diagn >= intervention_date), aes(y = mean), color = "#2c7fb8", alpha = 0.25, size = 1.2)+
        geom_line(data = df_new2 %>% dplyr::filter(mo_year_diagn >= intervention_date), aes(y = mean_ma), color = "#2c7fb8", linewidth = 0.7)+
        geom_vline(xintercept = as.numeric(intervention_date), linetype = "dashed", color = "grey")+
        scale_x_date(breaks = seq(as.Date(paste0(start[1], "-01-01")), as.Date(paste0(end[1] + 1, "-01-01")), by = "2 years"), date_labels = "%Y")+
        coord_cartesian(ylim = y_limits) +
        scale_y_continuous(breaks = y_breaks) +
        scale_color_manual(values = c("Observed" = "#5E716A", "Expected" = "#2c7fb8")) +
        theme_minimal() +
        xlab("") + ylab("") +
        theme(
          legend.title = element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(color = "grey"),
          axis.ticks = element_line(color = "grey"),
          axis.text  = element_text(size = 10, color = "black"),
          axis.title.x = element_text(size = 10, margin = margin(t = 10)),
          axis.title.y = element_text(size = 10, margin = margin(r = 10)),
          plot.title   = element_text(size = 14, hjust = 0.5, face = "plain")
        ) +
        ggtitle(paste0(dis_title))
      
      saveRDS(c_prophet, file = paste0("output/figures/prophet_", var, "_", dis, ".rds"))
      ggsave(filename = paste0("output/figures/prophet_", var, "_", dis, ".svg"),
             plot = c_prophet, width = 8, height = 6, device = "svg")
      
      print(c_prophet)
      
      # Calculate absolute and relative differences between observed and expected values for Prophet at different time intervals
      a<- c(n_preintervention, (n_preintervention + 12), (n_preintervention + 24), (n_preintervention + 36), n_preintervention)
      b<- c((n_preintervention + 12), (n_preintervention + 24), (n_preintervention + 36), max_index, max_index)
      
      results_list <- list()
      
      for (i in 1:5) {
        
        observed_val <- df_new2 %>%
          filter(index > a[i] & index <= b[i]) %>%
          summarise(observed = sum(get(var))) %>%
          select(observed)
        
        predicted_val <- df_new2 %>%
          filter(index > a[i] & index <= b[i]) %>%
          mutate(se = (upper - lower) / (2 * 1.96)) %>%
          summarise(sum_pred_rate = sum(mean), total_var = sum(se^2)) %>%
          mutate(
            sum_pred_rate_l = (sum_pred_rate - (1.96 * sqrt(total_var))),
            sum_pred_rate_u = (sum_pred_rate + (1.96 * sqrt(total_var)))
          ) %>%
          select(sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u)
        
        observed_predicted_rate <- merge(observed_val, predicted_val)
        
        observed_predicted_rate <- observed_predicted_rate %>%
          mutate(change_rate = observed - sum_pred_rate,
                 change_ratelow = observed - sum_pred_rate_l,
                 change_ratehigh = observed - sum_pred_rate_u, 
                 change_rate_per = (observed - sum_pred_rate) * 100 / sum_pred_rate,
                 change_rate_per_low = (observed - sum_pred_rate_l) * 100 / sum_pred_rate_l, 
                 change_rate_per_high = (observed - sum_pred_rate_u) * 100 / sum_pred_rate_u
          )
        
        # Store the result for this iteration in the list
        results_list[[i]] <- observed_predicted_rate %>%
          mutate(
            observed = round(observed, 2),
            sum_pred_rate = round(sum_pred_rate, 2),
            sum_pred_rate_l = round(sum_pred_rate_l, 2),
            sum_pred_rate_u = round(sum_pred_rate_u, 2),
            change_rate = round(change_rate, 2),
            change_ratelow = round(change_ratelow, 2),
            change_ratehigh = round(change_ratehigh, 2),
            change_rate_per = round(change_rate_per, 2),
            change_rate_per_low = round(change_rate_per_low, 2),
            change_rate_per_high = round(change_rate_per_high, 2)
          )
        
        if (i == 1) {
          rates.summary <- results_list[[i]] %>%
            select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                   change_rate, change_ratelow, change_ratehigh,
                   change_rate_per, change_rate_per_low, change_rate_per_high)
          colnames(rates.summary)[1:10] <- paste0(colnames(rates.summary)[1:10], ".2020")
        } else if (i == 2) {
          current_summary <- results_list[[i]] %>%
            select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                   change_rate, change_ratelow, change_ratehigh,
                   change_rate_per, change_rate_per_low, change_rate_per_high)
          colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".2021")
          rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
            select(-Row.names)
        } else if (i == 3) {
          current_summary <- results_list[[i]] %>%
            select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                   change_rate, change_ratelow, change_ratehigh,
                   change_rate_per, change_rate_per_low, change_rate_per_high)
          colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".2022")
          rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
            select(-Row.names)
        } else if (i == 4) {
          current_summary <- results_list[[i]] %>%
            select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                   change_rate, change_ratelow, change_ratehigh,
                   change_rate_per, change_rate_per_low, change_rate_per_high)
          colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".202324")
          rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
            select(-Row.names)
        } else if (i == 5) {
          current_summary <- results_list[[i]] %>%
            select(observed, sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u, 
                   change_rate, change_ratelow, change_ratehigh,
                   change_rate_per, change_rate_per_low, change_rate_per_high)
          colnames(current_summary)[1:10] <- paste0(colnames(current_summary)[1:10], ".total")
          rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
            select(-Row.names)
        }
      }
      
      rates.summary <- rates.summary %>%
        mutate(disease = dis_title) %>% 
        mutate(measure = var) %>% 
        select(measure, everything()) %>% 
        select(disease, everything()) 
      
      # Print summary table
      print(rates.summary)
      
      # Output to csv
      new_row <- rates.summary
      file_name <- "output/tables/change_incidence_byyear_prophet.csv"
      
      # Check if the file exists
      if (file.exists(file_name)) {
        existing_data <- read.csv(file_name)
        updated_data <- rbind(existing_data, new_row)
        write.csv(updated_data, file_name, row.names = FALSE)
      } else {
        write.csv(new_row, file_name, row.names = FALSE)
      }
    
    } else {
      message("Prophet package not installed, skipping forecast.")
    }
  }
  
  # Increment index (for labelling)
  index_axis <- index_axis + 1
}    

# # Generate combined graphs for each disease - Nb. the below doesn't run in the OpenSAFELY console
# dis_vec <- as.character(disease_list)
# 
# # List and read all RDS files that match the pattern (for SARIMA)
# rds_files <- list.files(path = "output/figures/", pattern = "^obs_pred_incidence.*_.*\\.rds$", full.names = TRUE)
# fnames <- basename(rds_files)
# file_dis <- sub("^obs_pred_incidence_(.*)\\.rds$", "\\1", fnames)
# keep <- file_dis %in% dis_vec
# matching_rds <- rds_files[keep]
# matching_dis <- file_dis[keep]
# idx <- match(matching_dis, dis_vec)
# ord <- order(idx, na.last = NA)
# matching_rds <- matching_rds[ord]
# plot_list <- lapply(matching_rds, readRDS)
# 
# png("output/figures/sarima_combined.png", width = 12830, height = 8680, res = 720)
# do.call(grid.arrange, c(plot_list, ncol = 5))
# dev.off()
# 
# # List and read all RDS files that match the pattern (for Prophet sensitivity)
# rds_files_p <- list.files(path = "output/figures/", pattern = "^prophet_incidence.*_.*\\.rds$", full.names = TRUE)
# fnames_p <- basename(rds_files_p)
# file_dis_p <- sub("^prophet_incidence_(.*)\\.rds$", "\\1", fnames_p)
# keep <- file_dis_p %in% dis_vec
# matching_rds_p <- rds_files_p[keep]
# matching_dis_p <- file_dis_p[keep]
# idx_p <- match(matching_dis_p, dis_vec)
# ord_p <- order(idx_p, na.last = NA)
# matching_rds_p <- matching_rds_p[ord_p]
# plot_list <- lapply(matching_rds_p, readRDS)
# 
# png("output/figures/sarima_combined_prophet.png", width = 12830, height = 8680, res = 720)
# do.call(grid.arrange, c(plot_list, ncol=5))
# dev.off()

dev.off()
graphics.off()
sink()