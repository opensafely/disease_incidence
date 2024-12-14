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

sessionInfo()

#For running locally
#setwd("C:/Users/k1754142/OneDrive/PhD Project/OpenSAFELY Incidence/disease_incidence/")
#setwd("C:/Users/Mark/OneDrive/PhD Project/OpenSAFELY Incidence/disease_incidence/")

## Create directories if needed
dir_create(here::here("output/figures"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output/tables"), showWarnings = FALSE, recurse = TRUE)

sink("logs/sarima_log.txt")
#pdf("output/figures/sarima_plots.pdf", width = 8, height = 6)

# Incidence data
df <-read.csv("output/data/arima_nonstandardised.csv")
#df <-read.csv("output/data/arima_nonstandardised - Copy.csv")

#Rename variables in the datafile 
names(df)[names(df) == "numerator"] <- "count" #standardise to common variable name - can remove this eventually
df<- df %>% filter(sex=="All") %>% select(disease, year, mo_year_diagn, incidence, count) 
df$month <- substr(df$mo_year_diagn, 1, 3)
df$mo_year_diagn <- gsub("-", " ", df$mo_year_diagn)
#df$mo_year_diagn <- sub("(\\d{2})$", "20\\1", df$mo_year_diagn)
df$mon_year <- df$mo_year_diagn
df$mo_year_diagn <- as.Date(paste0("01 ", df$mo_year_diagn), format = "%d %b %Y")
month_lab <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

#For gout, incidence rates are per 1,000 population - change to per 100,000 population - can remove this eventually
#df$incidence[df$disease == "Gout"] <- df$incidence[df$disease == "Gout"] * 100

#For RA (real data), incidence rates are per 10,000 population - change to per 100,000 population - can remove this eventually
#df$incidence[df$disease == "RA"] <- df$incidence[df$disease == "RA"] * 10

disease_list <- unique(df$disease)
# disease_list <- as.list(unique(df$disease))

# Define the variables to loop over
variables <- c("incidence", "count")
y_labels <- c("Incidence per 100,000 population", "Number of diagnoses per month")

# Loop through diseases
for (j in 1:length(disease_list)) {
  
  dis <- disease_list[j]
  df_dis <- df[df$disease == dis, ]
  df_dis <- df_dis %>%  mutate(index=1:n()) #create an index variable 1,2,3...
  
  #Keep only data from before March 2020 and save to separate df
  df_obs <- df_dis[which(df_dis$index<61),]
  
  # Loop through incidence and count
  for (i in 1:length(variables)) {
    var <- variables[i]
    y_label <- y_labels[i]
    
    #Graphs of observed incidence data - visually check the data for consistency of trends and seasonal patterns
    p1 <- ggplot(data = df_dis,aes(x = index, y = .data[[var]]))+geom_point()+geom_line()+
      scale_x_continuous(breaks = seq(1, max(df_dis$index), by = 12),labels = rep(df_dis$year, 7)[seq(1, 96, by = 12)])+
      theme_minimal()+
      xlab("Year of diagnosis")+ 
      ylab(y_label)+
      scale_fill_viridis_d()+
      scale_colour_viridis_d()+
      theme_minimal()+
      theme(
        legend.title = element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.line = element_line(color = "grey"),
        axis.ticks = element_line(color = "grey"),
        axis.text = element_text(size = 12),
        axis.title.x = element_text(size = 14, margin = margin(t = 10)),
        axis.title.y = element_text(size = 14, margin = margin(r = 10)), 
        plot.title = element_text(size = 16, hjust = 0.5) 
      ) +
      ggtitle(dis)
    
    ggsave(filename = paste0("output/figures/observed_", var, "_", dis, ".svg"), plot = p1, width = 8, height = 6, device = "svg")
    print(p1)

    #Convert to time series object 
    df_obs_rate <- ts(df_obs[[var]], frequency=12, start=c(2015,3))
    assign(paste0("ts_", var), df_obs_rate)
  
    #Plot time series - 1) raw data; 2) 1st order difference (yt- yt-1); 3) 1st order seasonal difference (yt-yt-1)-(yt-12-yt-12-1); checking for stationarity (i.e. remove trends over time by differencing)
    svg(filename = paste0("output/figures/raw_pre_covid_", var, "_", dis, ".svg"), width = 8, height = 6)
    plot(df_obs_rate, ylim=c(), type='l', col="blue", xlab="Year", ylab=y_label)
    dev.off()
    svg(filename = paste0("output/figures/differenced_pre_covid_", var, "_", dis, ".svg"), width = 8, height = 6)
    plot(diff(df_obs_rate),type = "l");abline(h=0,col = "red") #1st difference data
    dev.off()
    svg(filename = paste0("output/figures/seasonal_pre_covid_", var, "_", dis, ".svg"), width = 8, height = 6)
    plot(diff(diff(df_obs_rate),12),type = "l");abline(h=0,col = "red") #seasonal difference of 1st difference data 
    dev.off()
    
    #View ACF/PACF plots of undifferenced data (noting the extent of autocorrelation between time points)
    svg(filename = paste0("output/figures/raw_acf_", var, "_", dis, ".svg"), width = 8, height = 6)
    acf2(df_obs_rate, max.lag=59) 
    dev.off()
    
    #View ACF/PACF plots of differenced data (checking for autocorrelation after differencing)
    svg(filename = paste0("output/figures/differenced_acf_", var, "_", dis, ".svg"), width = 8, height = 6)
    acf2(diff(df_obs_rate), max.lag=46)
    dev.off()
    
    #View ACF/PACF plots of differenced/seasonally differenced data (checking for autocorrelation after differencing)
    svg(filename = paste0("output/figures/seasonal_acf_", var, "_", dis, ".svg"), width = 8, height = 6)
    acf2(diff(diff(df_obs_rate,12)), max.lag=46)
    dev.off()
    
    #Use auto.arima to fit SARIMA model - will identify p/q parameters that optimise AIC, but we need to double check residuals 
    suggested.rate<- auto.arima(df_obs_rate, seasonal=TRUE, max.p = 5, max.q = 5,  max.P = 2,  max.Q = 2, stepwise=FALSE, trace=TRUE) 
    #suggested.rate<- auto.arima(df_obs_rate, max.p = 5, max.q = 5,  max.P = 2,  max.Q = 2, stepwise=FALSE, trace=TRUE) 
    m1.rate <-suggested.rate
    m1.rate
    confint(m1.rate)
    
    #check residuals
    svg(filename = paste0("output/figures/auto_residuals_", var, "_", dis, ".svg"), width = 8, height = 6)
    checkresiduals(suggested.rate)
    dev.off()
    Box.test(suggested.rate$residuals, lag = 71, type = "Ljung-Box")
  
    #Forecast 24 months from March 2020 and convert to time series object
    fc.rate  <- forecast(m1.rate, h=36)
  
    #Forecasted rates 
    fc.ratemean <- ts(as.numeric(fc.rate$mean), start=c(2020,3), frequency=12)
    fc.ratelower <- ts(as.numeric(fc.rate$lower[,2]), start=c(2020,3), frequency=12) #lower 95% CI
    fc.rateupper <- ts(as.numeric(fc.rate$upper[,2]), start=c(2020,3), frequency=12) #upper 95% CI
    
    fc_rate<- data.frame(
      YearMonth = as.character(as.yearmon(time(fc.rate$mean))), # Year and month
      mean = as.numeric(as.matrix(fc.rate$mean)),
      lower = as.numeric(as.matrix(fc.rate$lower[, 2])),
      upper = as.numeric(as.matrix(fc.rate$upper[, 2]))
      # Flatten the matrix into a vector
    )
  
    df_new <- df_dis %>% left_join(fc_rate, by = c("mon_year" = "YearMonth"))
    df_new$mean <- ifelse(is.na(df_new$mean), df_new[[var]], df_new$mean) #If NA (i.e. pre-forecast), replace as = observed incidence
    df_new$lower <- ifelse(is.na(df_new$lower), df_new[[var]], df_new$lower) #If NA (i.e. pre-forecast), replace as = observed incidence
    df_new$upper <- ifelse(is.na(df_new$upper), df_new[[var]], df_new$upper) #If NA (i.e. pre-forecast), replace as = observed incidence
    
    df_new <- df_new %>%
      arrange(index) %>%
      mutate(moving_average = rollmean(get(var), k = 3, fill = NA, align = "center"))
    
    df_new <- df_new %>%
      arrange(index) %>%
      mutate(mean_ma = rollmean(mean, k = 3, fill = NA, align = "center"))
    
    write.csv(df_new, file = paste0("output/tables/values_", var, "_", dis, ".csv"), row.names = FALSE)
  
    #observed and predicted graphs to check model predictions against observed values
    c1<- 
      ggplot(data = df_new,aes(x = index))+
      geom_point(aes(y = .data[[var]]), color="#ADD8E6", size=3)+
      geom_line(aes(y = .data[[var]]), color="#ADD8E6")+
      geom_line(aes(y = moving_average), color = "blue", linetype = "solid", size=0.7)+
      geom_point(data = df_new %>% filter(index > 60), aes(y = mean), color="orange", alpha = 0.7, size=3)+
      geom_line(data = df_new %>% filter(index > 60), aes(y = mean), color="orange")+
      geom_line(data = df_new %>% filter(index > 60), aes(y = mean_ma), color = "red", linetype = "solid", size=0.7)+
      geom_ribbon(data = df_new %>% filter(index > 60), aes(ymin = lower, ymax = upper), alpha = 0.3, fill = "grey")+
      geom_vline(xintercept = 61, linetype = "dashed", color = "grey")+
      scale_x_continuous(breaks = seq(1, max(df_new$index), by = 12),labels = rep(df_new$year, 7)[seq(1, 96, by = 12)])+
      scale_fill_viridis_d()+
      scale_colour_viridis_d()+
      theme_minimal()+
      xlab("Year of diagnosis")+
      ylab(y_label)+
      theme(
        legend.title = element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.line = element_line(color = "grey"),
        axis.ticks = element_line(color = "grey"),
        axis.text = element_text(size = 12),
        axis.title.x = element_text(size = 14, margin = margin(t = 10)),
        axis.title.y = element_text(size = 14, margin = margin(r = 10)), 
        plot.title = element_text(size = 16, hjust = 0.5) 
      ) +
      ggtitle(dis)
    
    ggsave(filename = paste0("output/figures/obs_pred_", var, "_", dis, ".svg"), plot = c1, width = 8, height = 6, device = "svg")
    
    print(c1)
  
    #Calculate percentage difference between observed and predicted
    #i.e. months 61-72=2020, 73-84=2021, 85-96=2022, 61-96=2020+2021+2022) 
    a<- c(60, 72, 84, 60)
    b<- c(72, 84, 96, 96)
    
    results_list <- list()
    
    for (i in 1:4) {
      
      observed_val <- df_new %>%
        filter(index > a[i] & index <= b[i]) %>%
        summarise(observed = sum(get(var))) %>%
        select(observed)
      
      predicted_val <- df_new %>%
        filter(index > a[i] & index <= b[i]) %>%
        summarise(sum_pred_rate = sum(mean), sum_pred_rate_l= sum(lower), sum_pred_rate_u= sum(upper)) %>%
        select(sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u)
      
      observed_predicted_rate <- merge(observed_val, predicted_val)
      
      observed_predicted_rate <- observed_predicted_rate %>%
        mutate(change_rate = observed - sum_pred_rate,
               change_ratelow = observed - sum_pred_rate_l,
               change_ratehigh = observed - sum_pred_rate_u, 
               change_rate_per = (observed - sum_pred_rate) * 100 / sum_pred_rate,
               change_rateper_low = (observed - sum_pred_rate_l) * 100 / sum_pred_rate_l, 
               change_rateper_high = (observed - sum_pred_rate_u) * 100 / sum_pred_rate_u
        )
      
      # Store the result for this iteration in the list
      results_list[[i]] <- observed_predicted_rate %>%
        mutate(predicted = paste0(round(sum_pred_rate, 2), " (",  
                                    round(sum_pred_rate_l, 2), ", ",
                                    round(sum_pred_rate_u, 2), ")"),
               absolute_change = paste0(round(change_rate, 2), " (",  
                                          round(change_ratehigh, 2), ", ",
                                          round(change_ratelow, 2), ")"),
               percentage_change = paste0(round(change_rate_per, 2), " (",  
                                       round(change_rateper_high, 2), ", ",
                                       round(change_rateper_low, 2), ")"),
              observed = round(observed, 2)
        )
      
      # Add condition names to each result, based on iteration, if necessary
      if (i == 1) {
        rates.summary <- results_list[[i]] %>%
          select(observed, predicted, absolute_change, percentage_change)
        colnames(rates.summary)[1:4] <- paste0(colnames(rates.summary)[1:4], ".2020")
      } else if (i == 2) {
        current_summary <- results_list[[i]] %>%
          select(observed, predicted, absolute_change, percentage_change)
        colnames(current_summary)[1:4] <- paste0(colnames(current_summary)[1:4], ".2021")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      } else if (i == 3) {
        current_summary <- results_list[[i]] %>%
          select(observed, predicted, absolute_change, percentage_change)
        colnames(current_summary)[1:4] <- paste0(colnames(current_summary)[1:4], ".2022")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      } else if (i == 4) {
        current_summary <- results_list[[i]] %>%
          select(observed, predicted, absolute_change, percentage_change)
        colnames(current_summary)[1:4] <- paste0(colnames(current_summary)[1:4], ".total")
        rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
          select(-Row.names)
      }
    }
    
    rates.summary <- rates.summary %>%
      mutate(disease = dis) %>% 
      mutate(measure = var) %>% 
      select(measure, everything()) %>% 
      select(disease, everything()) 
    
    # The final summary table after the loop
    print(rates.summary)
  
    #Output to csv
    new_row <- rates.summary
    file_name <- "output/tables/change_incidence_byyear.csv"
    
    #Check if the file exists
    if (file.exists(file_name)) {
      existing_data <- read.csv(file_name)
      updated_data <- rbind(existing_data, new_row)
      write.csv(updated_data, file_name, row.names = FALSE)
    } else {
      write.csv(new_row, file_name, row.names = FALSE)
    }
  }
}

dev.off()

graphics.off()
sink()

  ###### OUTPUT FILE
  write.csv(df,"df_output.csv",row.names = FALSE)


  ######### Now run manually for other incidence rate #################
# 
#   df_dis <- df[df$disease == "Gout", ]
# 
#   df_dis <-df_dis %>%  mutate(index=1:n()) #create an index variable 1,2,3...
# 
#   #Keep only data from before March 2020 and save to separate df
#   df_obs <-df_dis[which(df_dis$index<61),]
# 
#   #Generate df copies for incidence and count
#   df_incidence <-df_dis
#   df_count <-df_dis
# 
#   #Graphs of observed incidence data - visually check the data for consistency of trends and seasonal patterns
#   p1 <- ggplot(data = df_incidence,aes(x = index,y = incidence ,colour = factor(year)))+geom_point()+geom_line()+
#     scale_x_continuous(breaks = seq(1, max(df_incidence$index), by = 12),labels = rep(df_incidence$year, 7)[seq(1, 96, by = 12)])+
#     scale_color_viridis_d(name = "Year")+
#     theme_minimal()+
#     xlab(NULL)+ ylab("Rate per 100,000 population")
#   p1
# 
#   #Convert to time series object
#   df_obs_rate <- ts(df_obs$incidence, frequency=12, start=c(2015,3))
#   df_obs_rate
# 
#   #Plot time series - 1) raw data; 2) 1st order difference (yt- yt-1); 3) 1st order seasonal difference (yt-yt-1)-(yt-12-yt-12-1); checking for stationarity (i.e. remove trends over time by differencing)
#   #options(scipen=5)
#   plot(df_obs_rate , ylim=c(), type='l', col="blue", xlab="Year", ylab="Incidence")
#   plot(diff(df_obs_rate),type = "l");abline(h=0,col = "red") #1st difference data - stationary
#   plot(diff(diff(df_obs_rate),12),type = "l");abline(h=0,col = "red") #seasonal difference of 1st difference data
# 
#   #View ACF/PACF plots of undifferenced data (noting the extent of autocorrelation between time points)
#   acf2(df_obs_rate, max.lag=59)
# 
#   #View ACF/PACF plots of differenced/seasonally differenced data (checking for autocorrelation after differencing)
#   acf2(diff(diff(df_obs_rate,12)), max.lag=46)
# 
#   #Use auto.arima to fit SARIMA model - will identify p/q parameters that optimise AIC, but we need to double check residuals
#   suggested.rate<- auto.arima(df_obs_rate, max.p = 5, max.q = 5,  max.P = 2,  max.Q = 2, stepwise=FALSE, trace=TRUE)
#   #suggested.rate<- auto.arima(df_obs_rate, seasonal=TRUE, max.p = 5, max.q = 5,  max.P = 2,  max.Q = 2, d=1, D=1, stepwise=FALSE, trace=TRUE) #can force d/D; may need to specify m too (e.g. m=12 for monthly seasonality)
#   m1.rate <-suggested.rate
#   confint(m1.rate)
# 
#   #check residuals
#   checkresiduals(suggested.rate)
#   Box.test(suggested.rate$residuals, lag = 71, type = "Ljung-Box")
# 
#   #NOTE: The R packages arima and sarima give the same results, both are used below for practical reasons
#   #i.e. arima gives precise confidence intervals and shows the overall p-value from the Ljung-Box test
#   #sarima shows more informative residual graphs
# 
#   #Can also use the sarima function in the console to try a few more models as the auto.arima package can sometimes produce Inf results - for some models that do converge when you use arima/sarima to fit them- not sure why, but it means auto.arima is limited in the models it explores)
#   #sarima.rate<-sarima(df_obs_rate, 2, 0, 1, P=1, D=1, Q=0, S = 12) #no drift
#   #sarima.rate
# 
#   #use suggested model (by auto.arima) as in this case, it has lowest AIC
#   #arima.rate<-arima(df_obs_rate, order=c(2,0,1), seasonal=list(order=c(1,1,0), period=12))
#   #arima.rate
#   #arima2.rate<-arima(df_obs_rate, order=c(2,0,1), seasonal=list(order=c(1,1,0), period=12), include.mean = FALSE)
# 
#   #Forecast 24 months from March 2020 and convert to time series object
#   fc.rate  <- forecast(m1.rate, h=36)
#   fc.rate
# 
#   #Forecasted rates
#   fc.ratemean <- ts(as.numeric(fc.rate$mean), start=c(2020,3), frequency=12)
#   fc.ratelower <- ts(as.numeric(fc.rate$lower[,2]), start=c(2020,3), frequency=12) #lower 95% CI
#   fc.rateupper <- ts(as.numeric(fc.rate$upper[,2]), start=c(2020,3), frequency=12) #upper 95% CI
# 
#   fc_rate<- data.frame(
#     YearMonth = as.character(as.yearmon(time(fc.rate$mean))), # Year and month
#     mean = as.numeric(as.matrix(fc.rate$mean)),
#     lower = as.numeric(as.matrix(fc.rate$lower[, 2])),
#     upper = as.numeric(as.matrix(fc.rate$upper[, 2]))
#     # Flatten the matrix into a vector
#   )
# 
#   df_incidence <- df_incidence %>% left_join(fc_rate, by = c("mon_year" = "YearMonth"))
# 
#   df_incidence$mean <- ifelse(is.na(df_incidence$mean), df_incidence$incidence, df_incidence$mean) #If NA (i.e. pre-forecast), replace as = observed incidence
#   df_incidence$lower <- ifelse(is.na(df_incidence$lower), df_incidence$incidence, df_incidence$lower) #If NA (i.e. pre-forecast), replace as = observed incidence
#   df_incidence$upper <- ifelse(is.na(df_incidence$upper), df_incidence$incidence, df_incidence$upper) #If NA (i.e. pre-forecast), replace as = observed incidence
# 
#   df_incidence <- df_incidence %>%
#     arrange(index) %>%
#     mutate(incidence_ma = rollmean(incidence, k = 3, fill = NA, align = "center"))
# 
#   df_incidence <- df_incidence %>%
#     arrange(index) %>%
#     mutate(mean_ma = rollmean(mean, k = 3, fill = NA, align = "center"))
# 
#   #observed and predicted graphs to check model predictions against observed values (not used for publication)
#   c1<-
#     ggplot(data = df_incidence,aes(x=index))+
#     geom_point(aes(y=incidence), color="#ADD8E6", size=3)+
#     geom_line(aes(y=incidence), color="#ADD8E6")+
#     geom_line(aes(y = incidence_ma), color = "blue", linetype = "solid", size=0.7)+
#     geom_point(data = df_incidence %>% filter(index > 60), aes(y=mean), color="orange", alpha = 0.7, size=3)+
#     geom_line(data = df_incidence %>% filter(index > 60), aes(y=mean), color="orange")+
#     geom_line(data = df_incidence %>% filter(index > 60), aes(y = mean_ma), color = "red", linetype = "solid", size=0.7)+
#     geom_ribbon(data = df_incidence %>% filter(index > 60), aes(ymin = lower, ymax = upper), alpha = 0.3, fill = "grey")+
#     geom_vline(xintercept = 61, linetype = "dashed", color = "grey")+
#     scale_x_continuous(breaks = seq(1, max(df_incidence$index), by = 12),labels = rep(df_incidence$year, 7)[seq(1, 96, by = 12)])+
#     scale_fill_viridis_d()+
#     scale_colour_viridis_d()+
#     theme_minimal()+
#     xlab("Year of diagnosis")+
#     ylab("Incidence rate per 100,000 population")+
#     theme(
#       legend.title = element_blank(),
#       panel.grid.major = element_blank(),
#       panel.grid.minor = element_blank(),
#       axis.line = element_line(color = "grey"),
#       axis.ticks = element_line(color = "grey"),
#       axis.text = element_text(size = 12),
#       axis.title.x = element_text(size = 14, margin = margin(t = 10)),
#       axis.title.y = element_text(size = 14, margin = margin(r = 10)),
#       plot.title = element_text(size = 16, hjust = 0.5)
#     )
# 
#   c1
# 
#   #Calculate percentage difference between observed and predicted
#   #i.e. months 61-72 =2020, 73-84=2021, 85-96=2022, 61-96=2020+2021+2022)
#   a<- c(60, 72, 84, 60)
#   b<- c(72, 84, 96, 96)
# 
#   results_list <- list()
# 
#   for (i in 1:4) {
# 
#     observed <- df_incidence %>%
#       filter(index > a[i] & index <= b[i]) %>%
#       summarise(sum_observed_rate = sum(incidence)) %>%
#       select(sum_observed_rate)
# 
#     predicted <- df_incidence %>%
#       filter(index > a[i] & index <= b[i]) %>%
#       summarise(sum_pred_rate = sum(mean), sum_pred_rate_l= sum(lower), sum_pred_rate_u= sum(upper)) %>%
#       select(sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u)
# 
#     observed_predicted_rate <- merge(observed, predicted)
# 
#     observed_predicted_rate <- observed_predicted_rate %>%
#       mutate(change_rate = sum_observed_rate - sum_pred_rate,
#              change_ratelow = sum_observed_rate - sum_pred_rate_l,
#              change_ratehigh = sum_observed_rate - sum_pred_rate_u,
#              change_rate_per = (sum_observed_rate - sum_pred_rate) * 100 / sum_pred_rate,
#              change_rateper_low = (sum_observed_rate - sum_pred_rate_l) * 100 / sum_pred_rate_l,
#              change_rateper_high = (sum_observed_rate - sum_pred_rate_u) * 100 / sum_pred_rate_u)
# 
#     # Store the result for this iteration in the list
#     results_list[[i]] <- observed_predicted_rate %>%
#       mutate(predicted_r = paste0(round(sum_pred_rate, 2), " (",
#                                   round(sum_pred_rate_l, 2), ", ",
#                                   round(sum_pred_rate_u, 2), ")"),
#              predictedchange_r = paste0(round(change_rate, 2), " (",
#                                         round(change_ratehigh, 2), ", ",
#                                         round(change_ratelow, 2), ")"),
#              predictedper_r = paste0(round(change_rate_per, 2), " (",
#                                      round(change_rateper_high, 2), ", ",
#                                      round(change_rateper_low, 2), ")"),
#              change_ratepercentage = paste0("Observed vs expected difference ",
#                                             round(change_rate_per, 2),
#                                             "% (",
#                                             round(change_rateper_high, 2), "%, ",
#                                             round(change_rateper_low, 2), "%)")) %>%
#       mutate(sum_observed_rate = round(sum_observed_rate, 2))
# 
#     # Add condition names to each result, based on iteration, if necessary
#     if (i == 1) {
#       rates.summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(rates.summary)[1:5] <- paste0(colnames(rates.summary)[1:5], ".2020")
#     } else if (i == 2) {
#       current_summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(current_summary)[1:5] <- paste0(colnames(current_summary)[1:5], ".2021")
#       rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
#         select(-Row.names)
#     } else if (i == 3) {
#       current_summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(current_summary)[1:5] <- paste0(colnames(current_summary)[1:5], ".2022")
#       rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
#         select(-Row.names)
#     } else if (i == 4) {
#       current_summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(current_summary)[1:5] <- paste0(colnames(current_summary)[1:5], ".total")
#       rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
#         select(-Row.names)
#     }
#   }
# 
#   # The final summary table after the loop
#   View(rates.summary)
#   
#   ###### OUTPUT FILES
#   write.csv(rates.summary,"LongTermConditions_Table1_rates_DM_incidence.csv",row.names = FALSE)
#   
#   ###### OUTPUT FILE
#   write.csv(df_incidence,"df_incidence_DM.csv",row.names = FALSE)
#   
#   ######### Now run manually for count #################
#   
#   #Graphs of observed count data - visually check the data for consistency of trends and seasonal patterns
#   p2 <- ggplot(data = df_count,aes(x = index,y = count ,colour = factor(year)))+geom_point()+geom_line()+
#     scale_x_continuous(breaks = seq(1, max(df_count$index), by = 12),labels = rep(df_count$year, 7)[seq(1, 96, by = 12)])+
#     scale_color_viridis_d(name = "Year")+
#     theme_minimal()+
#     xlab(NULL)+ ylab("Number of new diagnoses")
#   p2
#   
#   #Convert to time series object 
#   df_obs_rate <- ts(df_obs$count, frequency=12, start=c(2015,3))
#   df_obs_rate
#   
#   #Plot time series - 1) raw data; 2) 1st order difference (yt- yt-1); 3) 1st order seasonal difference (yt-yt-1)-(yt-12-yt-12-1); checking for stationarity (i.e. remove trends over time by differencing)
#   #options(scipen=5)
#   plot(df_obs_rate , ylim=c(), type='l', col="blue", xlab="Year", ylab="Count") #non-stationary, with evidence of seasonality
#   plot(diff(df_obs_rate),type = "l");abline(h=0,col = "red") #1st difference data - stationary
#   plot(diff(diff(df_obs_rate),12),type = "l");abline(h=0,col = "red") #seasonal difference of 1st difference data 
#   
#   #View ACF/PACF plots of undifferenced data (noting the extent of autocorrelation between time points)
#   acf2(df_obs_rate, max.lag=59) 
#   
#   #View ACF/PACF plots of differenced/seasonally differenced data (checking for autocorrelation after differencing)
#   acf2(diff(diff(df_obs_rate,12)), max.lag=46)
#   
#   #Use auto.arima to fit SARIMA model - will identify p/q parameters that optimise AIC, but we need to double check residuals 
#   suggested.rate<- auto.arima(df_obs_rate, max.p = 5, max.q = 5,  max.P = 2,  max.Q = 2, stepwise=FALSE, trace=TRUE) 
#   m1.rate <-suggested.rate
#   confint(m1.rate)
#   
#   #check residuals
#   checkresiduals(suggested.rate)
#   Box.test(suggested.rate$residuals, lag = 71, type = "Ljung-Box")
#   
#   #Forecast 24 months from March 2020 and convert to time series object
#   fc.rate  <- forecast(m1.rate, h=36)
#   fc.rate
#   
#   #Forecasted rates 
#   fc.ratemean <- ts(as.numeric(fc.rate$mean), start=c(2020,3), frequency=12)
#   fc.ratelower <- ts(as.numeric(fc.rate$lower[,2]), start=c(2020,3), frequency=12) #lower 95% CI
#   fc.rateupper <- ts(as.numeric(fc.rate$upper[,2]), start=c(2020,3), frequency=12) #upper 95% CI
#   
#   fc_rate<- data.frame(
#     YearMonth = as.character(as.yearmon(time(fc.rate$mean))), # Year and month
#     mean = as.numeric(as.matrix(fc.rate$mean)),
#     lower = as.numeric(as.matrix(fc.rate$lower[, 2])),
#     upper = as.numeric(as.matrix(fc.rate$upper[, 2]))
#     # Flatten the matrix into a vector
#   )
#   
#   df_count <- df_count %>% left_join(fc_rate, by = c("mon_year" = "YearMonth"))
#   
#   df_count$mean <- ifelse(is.na(df_count$mean), df_count$count, df_count$mean) #If NA (i.e. pre-forecast), replace as = observed count
#   df_count$lower <- ifelse(is.na(df_count$lower), df_count$count, df_count$lower) #If NA (i.e. pre-forecast), replace as = observed count
#   df_count$upper <- ifelse(is.na(df_count$upper), df_count$count, df_count$upper) #If NA (i.e. pre-forecast), replace as = observed count
#   
#   df_count <- df_count %>%
#     arrange(index) %>%
#     mutate(count_ma = rollmean(count, k = 3, fill = NA, align = "center"))
#   
#   df_count <- df_count %>%
#     arrange(index) %>%
#     mutate(mean_ma = rollmean(mean, k = 3, fill = NA, align = "center"))
#   
#   #observed and predicted graphs to check model predictions against observed values (not used for publication)
#   c2<- 
#     ggplot(data = df_count,aes(x=index))+
#     geom_point(aes(y=count), color="#ADD8E6", size=3)+
#     geom_line(aes(y=count), color="#ADD8E6")+
#     geom_line(aes(y = count_ma), color = "blue", linetype = "solid", size=0.7)+
#     geom_point(data = df_count %>% filter(index > 60), aes(y=mean), color="orange", alpha = 0.7, size=3)+
#     geom_line(data = df_count %>% filter(index > 60), aes(y=mean), color="orange")+
#     geom_line(data = df_count %>% filter(index > 60), aes(y = mean_ma), color = "red", linetype = "solid", size=0.7)+
#     geom_ribbon(data = df_count %>% filter(index > 60), aes(ymin = lower, ymax = upper), alpha = 0.3, fill = "grey")+
#     geom_vline(xintercept = 61, linetype = "dashed", color = "grey")+
#     scale_x_continuous(breaks = seq(1, max(df_count$index), by = 12),labels = rep(df_count$year, 7)[seq(1, 96, by = 12)])+
#     scale_fill_viridis_d()+
#     scale_colour_viridis_d()+
#     theme_minimal()+
#     xlab("Date of diagnosis")+
#     ylab("Number of new diagnoses")+
#     theme(
#       legend.title = element_blank(),
#       panel.grid.major = element_blank(), 
#       panel.grid.minor = element_blank(),
#       axis.line = element_line(color = "grey"),
#       axis.ticks = element_line(color = "grey"),
#       axis.text = element_text(size = 12),
#       axis.title.x = element_text(size = 14, margin = margin(t = 10)),
#       axis.title.y = element_text(size = 14, margin = margin(r = 10)), 
#       plot.title = element_text(size = 16, hjust = 0.5) 
#     )
#   
#   c2
#   
#   #Calculate percentage difference between observed and predicted
#   #i.e. months 61-72 =2020, 73-84=2021, 85-96=2022, 61-96=2020+2021+2022) 
#   a<- c(60, 72, 84, 60)
#   b<- c(72, 84, 96, 96)
#   
#   results_list <- list()
#   
#   for (i in 1:4) {
#     
#     observed <- df_count %>%
#       filter(index > a[i] & index <= b[i]) %>%
#       summarise(sum_observed_rate = sum(count)) %>%
#       select(sum_observed_rate)
#     
#     predicted <- df_count %>%
#       filter(index > a[i] & index <= b[i]) %>%
#       summarise(sum_pred_rate = sum(mean), sum_pred_rate_l= sum(lower), sum_pred_rate_u= sum(upper)) %>%
#       select(sum_pred_rate, sum_pred_rate_l, sum_pred_rate_u)
#     
#     observed_predicted_rate <- merge(observed, predicted)
#     
#     observed_predicted_rate <- observed_predicted_rate %>%
#       mutate(change_rate = sum_observed_rate - sum_pred_rate,
#              change_ratelow = sum_observed_rate - sum_pred_rate_l,
#              change_ratehigh = sum_observed_rate - sum_pred_rate_u, 
#              change_rate_per = (sum_observed_rate - sum_pred_rate) * 100 / sum_pred_rate,
#              change_rateper_low = (sum_observed_rate - sum_pred_rate_l) * 100 / sum_pred_rate_l, 
#              change_rateper_high = (sum_observed_rate - sum_pred_rate_u) * 100 / sum_pred_rate_u)
#     
#     # Store the result for this iteration in the list
#     results_list[[i]] <- observed_predicted_rate %>%
#       mutate(predicted_r = paste0(round(sum_pred_rate, 2), " (",  
#                                   round(sum_pred_rate_l, 2), ", ",
#                                   round(sum_pred_rate_u, 2), ")"),
#              predictedchange_r = paste0(round(change_rate, 2), " (",  
#                                         round(change_ratehigh, 2), ", ",
#                                         round(change_ratelow, 2), ")"),
#              predictedper_r = paste0(round(change_rate_per, 2), " (",  
#                                      round(change_rateper_high, 2), ", ",
#                                      round(change_rateper_low, 2), ")"),
#              change_ratepercentage = paste0("Observed vs expected difference ",
#                                             round(change_rate_per, 2), 
#                                             "% (", 
#                                             round(change_rateper_high, 2), "%, ",
#                                             round(change_rateper_low, 2), "%)")) %>%
#       mutate(sum_observed_rate = round(sum_observed_rate, 2))
#     
#     # Add condition names to each result, based on iteration, if necessary
#     if (i == 1) {
#       rates.summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(rates.summary)[1:5] <- paste0(colnames(rates.summary)[1:5], ".2020")
#     } else if (i == 2) {
#       current_summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(current_summary)[1:5] <- paste0(colnames(current_summary)[1:5], ".2021")
#       rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
#         select(-Row.names)
#     } else if (i == 3) {
#       current_summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(current_summary)[1:5] <- paste0(colnames(current_summary)[1:5], ".2022")
#       rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
#         select(-Row.names)
#     } else if (i == 4) {
#       current_summary <- results_list[[i]] %>%
#         select(sum_observed_rate, predicted_r, predictedchange_r, predictedper_r, change_ratepercentage)
#       colnames(current_summary)[1:5] <- paste0(colnames(current_summary)[1:5], ".total")
#       rates.summary <- merge(rates.summary, current_summary, by = "row.names", all = TRUE) %>%
#         select(-Row.names)
#     }
#   }
#   
#   # The final summary table after the loop
#   View(rates.summary)
#   
#   ###### OUTPUT FILES
#   write.csv(rates.summary,"LongTermConditions_Table1_rates_MS_count.csv",row.names = FALSE)
#   
#   ###### OUTPUT FILE
#   write.csv(df_count,"df_count_MS",row.names = FALSE)
# 

################################################################################################################## END 




