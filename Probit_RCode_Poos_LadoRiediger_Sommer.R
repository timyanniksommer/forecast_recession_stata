# Import Data

library(readxl)
data <- read_excel("Desktop/Final/Probit_DataSet_LadoRiediger_Sommer.xlsx")

# MAE
abs_dif_sta1 <- abs(data$poos_p_sta1[233:256] - data$recession[233:256])

mae_sta1 <- (1/24) * sum(abs_dif_sta1)

abs_dif_dyn1 <- abs(data$poos_p_dyn1[233:256] - data$recession[233:256])

mae_dyn1 <- (1/24) * sum(abs_dif_dyn1)

abs_dif_sta3 <- abs(data$poos_p_sta3[233:256] - data$recession[233:256])

mae_sta3 <- (1/24) * sum(abs_dif_sta3)

abs_dif_dyn3 <- abs(data$poos_p_dyn3[233:256] - data$recession[233:256])

mae_dyn3 <- (1/24) * sum(abs_dif_dyn3)


results_mae<- list(mae_sta1, mae_dyn1, mae_sta3, mae_dyn3)


#RMSE
sq_dif_sta1 <- (data$poos_p_sta1[233:256] - data$recession[233:256])^2

rmse_sta1 <- sqrt(mean(sq_dif_sta1))

sq_dif_dyn1 <- (data$poos_p_dyn1[233:256] - data$recession[233:256])^2

rmse_dyn1 <- sqrt(mean(sq_dif_dyn1))

sq_dif_sta3 <- (data$poos_p_sta3[233:256] - data$recession[233:256])^2

rmse_sta3 <- sqrt(mean(sq_dif_sta3))

sq_dif_dyn3 <- (data$poos_p_dyn3[233:256] - data$recession[233:256])^2

rmse_dyn3 <- sqrt(mean(sq_dif_dyn3))

results_rmse <- list(rmse_sta1, rmse_dyn1, rmse_sta3, rmse_dyn3)

#Theil

theil_sta1 <- rmse_sta1 / ((sqrt(mean((data$poos_p_sta1[233:256])^2))) + (sqrt(mean((data$recession[233:256])^2))))

theil_dyn1 <- rmse_dyn1 / ((sqrt(mean((data$poos_p_dyn1[233:256])^2))) + (sqrt(mean((data$recession[233:256])^2))))

theil_sta3 <- rmse_sta3 / ((sqrt(mean((data$poos_p_sta3[233:256])^2))) + (sqrt(mean((data$recession[233:256])^2))))

theil_dyn3 <- rmse_dyn3 / ((sqrt(mean((data$poos_p_dyn3[233:256])^2))) + (sqrt(mean((data$recession[233:256])^2))))

results_theil <- list(theil_sta1, theil_dyn1, theil_sta3, theil_dyn3)


################################################################################################################
#Robustness Check
################################################################################################################

# MAE
abs_dif_sta1_rob <- abs(data$poos_p_sta1_rob[221:256] - data$recession[221:256])

mae_sta1_rob <- (1/36) * sum(abs_dif_sta1_rob)

abs_dif_dyn1_rob <- abs(data$poos_p_dyn1_rob[221:256] - data$recession[221:256])

mae_dyn1_rob <- (1/36) * sum(abs_dif_dyn1_rob)

abs_dif_sta3_rob <- abs(data$poos_p_sta3_rob[221:256] - data$recession[221:256])

mae_sta3_rob <- (1/36) * sum(abs_dif_sta3_rob)

abs_dif_dyn3_rob <- abs(data$poos_p_dyn3_rob[221:256] - data$recession[221:256])

mae_dyn3_rob <- (1/36) * sum(abs_dif_dyn3_rob)


results_mae_rob<- list(mae_sta_rob1, mae_dyn1_rob, mae_sta3_rob, mae_dyn3_rob)


#RMSE
sq_dif_sta1_rob <- (data$poos_p_sta1_rob[221:256] - data$recession[221:256])^2

rmse_sta1_rob <- sqrt(mean(sq_dif_sta1_rob))

sq_dif_dyn1_rob <- (data$poos_p_dyn1_rob[221:256] - data$recession[221:256])^2

rmse_dyn1_rob <- sqrt(mean(sq_dif_dyn1_rob))

sq_dif_sta3_rob <- (data$poos_p_sta3_rob[221:256] - data$recession[221:256])^2

rmse_sta3_rob <- sqrt(mean(sq_dif_sta3_rob))

sq_dif_dyn3_rob <- (data$poos_p_dyn3_rob[221:256] - data$recession[221:256])^2

rmse_dyn3_rob <- sqrt(mean(sq_dif_dyn3_rob))

results_rmse_rob <- list(rmse_sta1_rob, rmse_dyn1_rob, rmse_sta3_rob, rmse_dyn3_rob)

#Theil

theil_sta1_rob <- rmse_sta1_rob / ((sqrt(mean((data$poos_p_sta1_rob[221:256])^2))) + (sqrt(mean((data$recession[221:256])^2))))

theil_dyn1_rob <- rmse_dyn1_rob / ((sqrt(mean((data$poos_p_dyn1_rob[221:256])^2))) + (sqrt(mean((data$recession[221:256])^2))))

theil_sta3_rob <- rmse_sta3_rob / ((sqrt(mean((data$poos_p_sta3_rob[221:256])^2))) + (sqrt(mean((data$recession[221:256])^2))))

theil_dyn3_rob <- rmse_dyn3_rob / ((sqrt(mean((data$poos_p_dyn3_rob[221:256])^2))) + (sqrt(mean((data$recession[221:256])^2))))

results_theil_rob <- list(theil_sta1_rob, theil_dyn1_rob, theil_sta3_rob, theil_dyn3_rob)

