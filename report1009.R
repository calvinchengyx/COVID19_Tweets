library(quanteda)
library(dplyr)
library(ggplot2)
library(stringr)

ct_twitter = readRDS("ct_twitter_3.rds")
diffnet = readRDS("diffNet_1007.rds")
ideos = readRDS("ideos.rds")
moral_emo_dic = readRDS("moral_emo_dic.rds")
virality_score = readRDS("virality_score_aug18.rds")
code_connie = readRDS("code_sample1009.rds")

#### RQ 1####
rq1 = code_connie[,c("tweetid","id","ct_category","Stance","txt")]
#ideos$uid = as.factor(ideos$uid)
rq1 = left_join(rq1,ideos[,c("uid","ideology_scores")], by=c("id"="uid"))
rq1 = rq1[!is.na(rq1$ideology_scores),] # remove those users who can not be categorized into conservatives or liberals
rq1$ideo = ifelse(rq1$ideology_scores>0,"conservative","liberal")
table(rq1$ideo)
p1_1 = ggplot(rq1, aes(x = ideo)) +
  geom_bar() + 
  theme_minimal() + 
  scale_fill_brewer(palette="Greys") + 
  ggtitle("CT Tweet Posts") + 
  theme()
ggsave("p1_1.pdf", plot = p1_1, height = 5, width = 8)

p1_2 = ggplot(rq1, aes(x = ideo)) +
  geom_bar() + 
  facet_wrap( ~ Stance) +
  theme_minimal() + 
  scale_fill_brewer(palette="Greys") + 
  ggtitle("CT Tweet Posts") + 
  theme()
ggsave("p1_2.pdf", plot = p1_2, height = 5, width = 8)

rq1_2 = left_join(diffnet[,c("sharers","tid")], ideos[,c("uid","ideology_scores")], by=c("sharers"="uid"))
rq1_2 = rq1_2[!is.na(rq1_2$ideology_scores),]
rq1_2$ideo = ifelse(rq1_2$ideology_scores>0,"conservative","liberal")
p1_3 = ggplot(rq1_2, aes(x = ideo)) +
  geom_bar() + 
  theme_minimal() + 
  scale_fill_brewer(palette="Greys") + 
  ggtitle("CT Tweet Sharers") + 
  theme()
ggsave("p1_3.pdf", plot = p1_3, height = 5, width = 8)

rq1_2 = left_join(rq1_2, code_connie[,c("tweetid","Stance")], by = c("tid"="tweetid"))
rq1_2 =  rq1_2[!is.na(rq1_2$Stance),]
p1_4 = ggplot(rq1_2, aes(x = ideo)) +
  geom_bar() + 
  facet_wrap( ~ Stance) +
  theme_minimal() + 
  scale_fill_brewer(palette="Greys") + 
  ggtitle("CT Tweet Sharers") + 
  theme()
ggsave("p1_4.pdf", plot = p1_4, height = 5, width = 8)

#### RQ 2 ####
rq2 = code_connie[,c("tweetid","id","ct_category","Type","txt")]
#ideos$uid = as.factor(ideos$uid)
rq2 = left_join(rq2,ideos[,c("uid","ideology_scores")], by=c("id"="uid"))
rq2 = rq2[!is.na(rq2$ideology_scores),] # remove those users who can not be categorized into conservatives or liberals
rq2$ideo = ifelse(rq2$ideology_scores>0,"conservative","liberal")
rq2 = rq2[rq2$Type!="UC" & rq2$Type!="UC-T" & rq2$Type!="UR",] # remove those unrelated tweets
p2 = ggplot(rq2, aes(x = ideo)) +
  geom_bar() + 
  facet_wrap( ~ Type) +
  theme_minimal() + 
  scale_fill_brewer(palette="Greys") + 
  ggtitle("CT tweet content and political ideologies") + 
  theme()
ggsave("p2.pdf", plot = p2, height = 5, width = 8)

x = rq2[rq2$Type=="SM",]
table(x$ideo)

#### RQ 3  ####
rq3_x = ct_twitter[ct_twitter$retweeted_tweetid==""&ct_twitter$retweeted_userid==""
                 &ct_twitter$replyto_tweetid==""&ct_twitter$replyto_userid=="",]
rq3_x = rq3_x[,c("tweetid","id","txt","retweet_count","ct_category")]
rq3_y = ct_twitter[ct_twitter$retweeted_tweetid!=""&ct_twitter$retweeted_userid!=""
                   &ct_twitter$replyto_tweetid==""&ct_twitter$replyto_userid=="",]
rq3_y = rq3_y[,c("retweeted_tweetid","retweeted_userid","txt","retweet_count","ct_category")]
colnames(rq3_y) = c("tweetid","id","txt","retweet_count","ct_category")
rq3 = rbind(rq3_x,rq3_y)
rq3 = rq3[!duplicated(rq3$tweetid),]
rq3$retweet_count = as.numeric(rq3$retweet_count)
rq3 = rq3[rq3$retweet_count>0,]

clean_tweet = function(tweets){
  clean_tweet = stringi::stri_trans_general(tweets, "latin-ascii") 
  clean_tweet = str_remove_all(clean_tweet, "[^\\u0000-\\u007f]+") # replace all non-ASCII characters
  clean_tweet = iconv(clean_tweet, "latin1", "ASCII", sub="") # replace all non-ASCII characters
  clean_tweet = str_replace_all(clean_tweet, "http(s):\\/\\/(.*)(\\s?)" ,"")
  clean_tweet = str_replace_all(clean_tweet, "@\\w+","") # remove all mentioned names
  clean_tweet = str_replace_all(clean_tweet, "\\bRT\\b","") # remove RT
  clean_tweet = str_replace_all(clean_tweet, "[[:punct:]]","") # remove all punctuations (meaning hashtag contents are remained)
  clean_tweet = str_replace_all(clean_tweet, "\\bamp\\b","")
  clean_tweet = stringi::stri_trim(clean_tweet, side = "both") # remove leading and tailing spaces
  return(clean_tweet)
}
rq3$txt_clean = clean_tweet(rq3$txt)
corp = corpus(rq3, docid_field = "tweetid", text_field = "txt_clean")
tks = tokens(corp,remove_punct = T)
tks_emo = tokens_lookup(tks, dictionary = moral_emo_dic, levels = 1)
tks_df = dfm(tks_emo) %>% convert(to = "data.frame")
rq3_1 = left_join(rq3,tks_df, by = c("tweetid"="document"))
cor.test(rq3_1$mix, rq3_1$retweet_count, method=c("pearson", "kendall", "spearman"))
p3_1 = ggplot(rq3_1, aes(x = mix, y = retweet_count)) + geom_point()
ggsave("p3_1.pdf", plot = p3_1, height = 5, width = 8)

rq3_2 = left_join(rq3_1, code_connie[,c("tweetid","Stance","Type")], by = c("tweetid"="tweetid"))
rq3_2_1 = rq3_2[!is.na(rq3_2$Stance),]
p3_2_1 = ggplot(rq3_2_1, aes(x = mix, y = retweet_count)) + 
  geom_point() +
  facet_wrap( ~ Stance) 
ggsave("p3_2.pdf", plot = p3_2, height = 5, width = 8)

rq3_2_2 = rq3_2[!is.na(rq3_2$Type),]
p3_2_2 = ggplot(rq3_2_2, aes(x = mix, y = retweet_count)) + 
  geom_point() +
  facet_wrap( ~ Type) 
ggsave("p3_2_2.pdf", plot = p3_2_2, height = 5, width = 8)

rq3_3 = diffnet[diffnet$tid %in% rq3_1$tweetid,]
rq3_3 = left_join(rq3_3,rq3[,c("tweetid","id")], by = c("tid"="tweetid"))
rq3_3 = left_join(rq3_3, ideos[,c("uid","ideology_scores")], by=c("sharers"="uid"))
rq3_3 = left_join(rq3_3, ideos[,c("uid","ideology_scores")], by=c("id"="uid"))
rq3_3 = rq3_3[!is.na(rq3_3$ideology_scores.x) & !is.na(rq3_3$ideology_scores.y),]
rq3_3$cross_ideo = ifelse(rq3_3$ideology_scores.x*rq3_3$ideology_scores.y>0, "in-group","out-group")
rq3_3_x = rq3_3 %>% group_by(tid, cross_ideo) %>% summarise(n =n())
rq3_3_x = left_join(rq3_3_x, rq3_1[,c("tweetid","mix")], by = c("tid"="tweetid"))
rq3_3_y = rq3_3_x %>% group_by(mix, cross_ideo) %>% summarise(mean_of_mixed = mean(n))
print(rq3_3_y)
p3_3 = ggplot(rq3_3_y, aes(x = cross_ideo, y = mean_of_mixed)) + 
  geom_bar(stat = "identity") +
  facet_wrap( ~ mix) + 
  theme_minimal() + 
  scale_fill_brewer(palette="Greys") + 
  ggtitle("Cross-ideology sharing of CT tweets and the number of moral-emo words") + 
  theme()
ggsave("p3_3.pdf", plot = p3_3, height = 5, width = 8)


#### RQ 4 ####
rq4 = left_join(virality_score[,c("tid","sv","sv_normalized")], code_connie[,c("tweetid","Type")], by = c("tid"="tweetid"))
rq4 = rq4[!is.na(rq4$Type),]
rq4 = left_join(rq4, rq3[,c("tweetid","id")], by = c("tid"="tweetid"))
rq4 = rq4[!duplicated(rq4$tid),]
rq4 = left_join(rq4, ideos[,c("uid","ideology_scores")], by=c("id"="uid"))
rq4[61,5] = 1
rq4 = rq4[!is.na(rq4$ideology_scores),]
rq4$ideo = ifelse(rq4$ideology_scores>0,"conservative","liberal")
rq4 %>% group_by(Type,ideo) %>% summarise(n = mean(sv_normalized))


#### 1016 update ####
x = ct_twitter[ct_twitter$ct_category!="ct23",]
y = ct_twitter[ct_twitter$ct_category=="ct23",]
y1 = y[str_detect(y$txt,regex("(?=.*\\bplandemi)(?=.*(\\bjudy|mikovit|\\bdrjudy))", ignore_case = T)),]
y2 = y[str_detect(y$txt,regex("(?=.*\\bcares\\b)(?=.*\\bact\\b)|(?=.*\\bclorox\\b)", ignore_case = T)),]
y3 = y[str_detect(y$txt,regex("(?=.*(\\bcattl|\\bcanin))(?=.*\\bvacci)", ignore_case = T)),]
y3$ct_category = "ct28"

ct_twitter_1016 = rbind(x,y1)
ct_twitter_1016 = rbind(ct_twitter_1016,y3)
saveRDS(ct_twitter_1016,"ct_twitter_1016.rds")

ct_twitter_1016_connie = ct_twitter_1016
ct_twitter_1016_connie$id =  paste0('"', ct_twitter_1016$id, '"')
ct_twitter_1016_connie$tweetid = paste0('"', ct_twitter_1016$id, '"')
ct_twitter_1016_connie$replyto_userid =  paste0('"', ct_twitter_1016$replyto_userid, '"')
ct_twitter_1016_connie$replyto_tweetid =  paste0('"', ct_twitter_1016$replyto_tweetid, '"')
ct_twitter_1016_connie$retweeted_tweetid =  paste0('"', ct_twitter_1016$retweeted_tweetid, '"')
ct_twitter_1016_connie$retweeted_userid =  paste0('"', ct_twitter_1016$retweeted_userid, '"')
write.csv(ct_twitter_1016_connie, file = "ct_twitter_1016.csv") 

user_info_1016_connie = user_info
user_info_1016_connie$id = paste0('"', user_info$id, '"')
user_info_1016_connie$id_str = paste0('"', user_info$id_str, '"')
write.csv(user_info_1016_connie, file = "user_info_1016.csv")
