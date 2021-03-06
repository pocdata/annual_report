
source("functions.R")
source("configurations.R")

###########################################################
# Rate of Screened-In Report by Prior Screened-In Reports #
###########################################################

screenedin_order <- sqlQuery(con_test_annie, "SELECT RO.*
    									,LC.old_region_cd
									FROM rate_referrals_scrn_in_order_specific AS RO
                             JOIN ref_lookup_county_region AS LC
                             ON LC.county_cd = RO.county_cd;")

####################################
# aggregating data to region level #
####################################

screenedin_order_agg <- screenedin_order %>% group_by(qry_type, date_type, start_date, nth_order, old_region_cd) %>%
    summarize(cnt_referrals = sum(cnt_referrals),
              prior_order_referrals = sum(prior_order_referrals),
              referral_rate = sum(cnt_referrals, na.rm = T)/sum(prior_order_referrals, na.rm = T) * 1000) %>%
    filter(start_date > start_d & start_date < end_d)

#######################
# loop to get ts data #				
#######################

dat2 <- as.data.frame(NULL)

for(h in 0:6){	
    d <- h
    dat1 <- as.data.frame(NULL)
    for (i in 1:3) {
        dat <- ts_func(screenedin_order_agg, old_region_cd == d & nth_order == i, x = 8)
        dat1 <- rbind.fill(dat1, dat)
    }
    dat2 <- rbind(dat2, dat1)					
}									

names(dat2) <- c("qry_type", "date_type", "start_date", "nth_order", "old_region_cd", "cnt_referrals", "prior_order_referrals", "referral_rate", "seasonal", "trend")

for(i in 1:ncol(dat2)){
    dat2[, i] <- class_convert(dat2[,i])
}			

# loading data into mySQL
# sqlDrop(con_test_annie, sqtable = "rate_referrals_scrn_in_order_specific_ts")
sqlSave(con_test_annie, dat = dat2, tablename = "rate_referrals_scrn_in_order_specific_ts", rownames = FALSE)
