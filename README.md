# COVID19_Tweets

## Data Collection
Projects in this repository is based on tweet dataset from [Chen](https://github.com/echen102/COVID-19-TweetIDs)'s repository. Please refer to the original dataset for more information about the scale, sampling methods and related research. We followed the authors' instruction to hydrate tweets and saved them to local SQL database. 

## Key Words filter
we filter Conspiracy Theory (CT) related tweets from Jan 21 to Jun 30, 2020 based on a set of keywords. These keywords were manually coded and collected from a batch of fact-checking websites. Their regular expressions could be found in the keywords.txt file. 

