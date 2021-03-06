# Import libraries
library(ggplot2); library(dplyr); library(reshape2); library(plyr); library(Hmisc); library(gridExtra)
library(car); library(fBasics); library(scales); library(MASS)

# Clear workspace
rm(list=ls())

# Set working directory to the current file location
# Can be done through 'Session' tab in RStudio 

# Read in data
subject_info <- read.csv("../data/subject_info.txt", header=TRUE, sep="\t", fileEncoding="UTF-8-BOM")
lca_data <- read.csv("../data/r_data.txt", header=TRUE, sep=",")

# Rename columns and colume values
colnames(subject_info)[colnames(subject_info)=="Natio1"] <- "Nationality"
colnames(lca_data)[colnames(lca_data)=="Natio1"] <- "Nationality"
colnames(subject_info)[colnames(subject_info)=="TrackNatio1"] <- "Group"
colnames(lca_data)[colnames(lca_data)=="TrackNatio1"] <- "Group"
subject_info$Nationality <- revalue(subject_info$Nationality, c("NL" = "Dutch", "DU" = "German"))
subject_info$Track <- revalue(subject_info$Track, c("NL" = "Dutch", "EN" = "English"))
subject_info$Group <- revalue(subject_info$Group, c("DU_in_NL" = "German_in_Dutch", "NL_in_NL" = "Dutch_in_Dutch", "DU_in_EN" = "German_in_English", "NL_in_EN" = "Dutch_in_English"))
lca_data$Nationality <- revalue(lca_data$Nationality, c("NL" = "Dutch", "DU" = "German"))
lca_data$Track <- revalue(lca_data$Track, c("NL" = "Dutch", "EN" = "English"))
lca_data$Group <- revalue(lca_data$Group, c("DU_in_NL" = "German_in_Dutch", "NL_in_NL" = "Dutch_in_Dutch", "DU_in_EN" = "German_in_English", "NL_in_EN" = "Dutch_in_English"))

# Create new dataframes
all_data <- merge(lca_data, subject_info, all.y = TRUE)
no_dropout <- all_data[all_data$DropOut!="DuringYear1",]

# Relevel (for better visualisation)
lca_data$Track <- factor(lca_data$Track, levels = c("Dutch", "English"))
lca_data$Nationality <- factor(lca_data$Nationality, levels = c("Dutch", "German"))
all_data$Group <- factor(all_data$Group, levels = c("Dutch_in_Dutch", "Dutch_in_English", "German_in_Dutch", "German_in_English"))
all_data$DropOut <- factor(all_data$DropOut, levels = c("DuringYear1", "AfterYear1", "No"))
no_dropout$Group <- factor(no_dropout$Group, levels = c("Dutch_in_Dutch", "Dutch_in_English", "German_in_Dutch", "German_in_English"))

# Recode
str(subject_info)
# All first year results are currently coded as factors
# This is because there are also non-numeric data, such as "ND"
#subject_info$Stat1 <- as.numeric(subject_info$Stat1) # Doesn't work without preprocessing


### Study success: descriptive statistics

## ECTS

# All students
tapply(all_data$ECTSTotal, all_data$Group, mean)
tapply(all_data$ECTSTotal, all_data$Group, sd)
descr_all <- tapply(all_data$ECTSTotal, all_data$Group, basicStats)
basicStats(all_data$ECTSTotal)

# No drop-outs
tapply(no_dropout$ECTSTotal, no_dropout$Group, mean)
tapply(no_dropout$ECTSTotal, no_dropout$Group, sd)
descr_sub <- tapply(no_dropout$ECTSTotal, no_dropout$Group, basicStats)
basicStats(no_dropout$ECTSTotal)

# Histogram of total number of ECTS obtained
ects_hist <- ggplot(data = no_dropout, aes(ECTSTotal, fill = Group)) +
  geom_histogram(col = "white", binwidth = 5) +
  facet_grid(~Group) +
  labs(x = "\nTotal number of ECTS obtained", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks=pretty_breaks(n=5)) +
  scale_y_continuous(breaks=pretty_breaks(n=10)); ects_hist

## Mean grade

# All students
tapply(all_data$MeanPsyWeighted, all_data$Group, mean, na.rm = TRUE)
tapply(all_data$MeanPsyWeighted, all_data$Group, sd, na.rm = TRUE)
descr_all <- tapply(all_data$MeanPsyWeighted, all_data$Group, basicStats)
basicStats(all_data$MeanPsyWeighted)

# No drop-outs
tapply(no_dropout$MeanPsyWeighted, no_dropout$Group, mean, na.rm = TRUE)
tapply(no_dropout$MeanPsyWeighted, no_dropout$Group, sd, na.rm = TRUE)
descr_sub <- tapply(no_dropout$MeanPsyWeighted, no_dropout$Group, basicStats); descr_sub
basicStats(no_dropout$MeanPsyWeighted)

# Histogram of total number of ECTS obtained
ects_mean <- ggplot(data = no_dropout, aes(MeanPsyWeighted, fill = Group)) +
  geom_histogram(col = "white", binwidth = 0.5) +
  facet_grid(~Group) +
  labs(x = "\nHistogram of mean grades", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks=pretty_breaks(n=6)); ects_mean 

## Weighted grade

# All students
tapply(all_data$GradesTimesECTS, all_data$Group, mean, na.rm = TRUE)
tapply(all_data$GradesTimesECTS, all_data$Group, sd, na.rm = TRUE)
descr_all <- tapply(all_data$GradesTimesECTS, all_data$Group, basicStats)
basicStats(all_data$GradesTimesECTS)

# No drop-outs
tapply(no_dropout$GradesTimesECTS, no_dropout$Group, mean, na.rm = TRUE)
tapply(no_dropout$GradesTimesECTS, no_dropout$Group, sd, na.rm = TRUE)
descr_sub <- tapply(no_dropout$GradesTimesECTS, no_dropout$Group, basicStats); descr_sub
basicStats(no_dropout$GradesTimesECTS)

# Histogram of total number of ECTS obtained
ects_weighted <- ggplot(data = no_dropout, aes(GradesTimesECTS, fill = Group)) +
  geom_histogram(col = "white", binwidth = 50) +
  facet_grid(~Group) +
  labs(x = "\nHistogram of weighted grades", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks=pretty_breaks(n=3)); ects_weighted

## Drop-out
drop <- table(all_data$DropOut, all_data$Group); drop
prop.table(drop, 2)

# Collapse during and after year 1
all_data$DropOut2[all_data$DropOut != "No"] <- "Yes"
all_data$DropOut2[all_data$DropOut == "No"] <- "No"

drop2 <- table(all_data$DropOut2, all_data$Group); drop2
prop.table(drop2, 2)


### Study success: inferential statistics

## Total number of ECTS

## Checking assumptions
ects_hist # Data are not normally distributed

# Kruskal-Wallis test
kruskal.test(ECTSTotal ~ Group, data = no_dropout)
no_dropout$Rank <- rank(no_dropout$ECTSTotal)
by(no_dropout$Rank, no_dropout$Group, mean)

## Robust ANOVA

# Transform data to wide format
wilcox_wide <- dcast(no_dropout, SubjectCode ~ Group, value.var = "ECTSTotal")
str(wilcox_wide)
wilcox_wide$SubjectCode <- NULL

# Load functions from Rand Wilcox
source("Rallfun-v35.txt")

# Perform robust ANOVA
t1way(wilcox_wide, tr = 0)
t1way(wilcox_wide, tr = 0.1)
t1way(wilcox_wide, tr = 0.2)
med1way(wilcox_wide) # "WARNING: tied values detected. Estimate of standard error might be highly inaccurate, even with n large."
t1waybt(wilcox_wide, tr = 0.1)

## Mean grade

## Checking assumptions
ects_mean # Data seem normally distributed
tapply(all_data$MeanPsyWeighted, all_data$Group, shapiro.test) # Shapiro test says data are non-normally distributed

# Levene's test of homogeneity of variance
leveneTest(no_dropout$MeanPsyWeighted, no_dropout$Group) # Not significant

# Is ECTSTotal different between the groups?
lm_mean <- lm(MeanPsyWeighted ~ Group, data = no_dropout)
summary(lm_mean)

aov_mean <- aov(MeanPsyWeighted ~ Group, data = no_dropout)
summary(aov_mean)
plot(aov_mean)

# Kruskal-Wallis test
kruskal.test(MeanPsyWeighted ~ Group, data = no_dropout)
no_dropout$RankMeanPsyWeighted <- rank(no_dropout$MeanPsyWeighted)
by(no_dropout$RankMeanPsyWeighted, no_dropout$Group, mean)

## Weighted grades

## Checking assumptions
ects_weighted # Data seem skewed
tapply(all_data$GradesTimesECTS, all_data$Group, shapiro.test) # Data are non-normally distributed

# Levene's test of homogeneity of variance
leveneTest(no_dropout$GradesTimesECTS, no_dropout$Group) # Not significant

# Kruskal-Wallis test
kruskal.test(GradesTimesECTS ~ Group, data = no_dropout)
no_dropout$RankGradesTimesECTS <- rank(no_dropout$GradesTimesECTS)
by(no_dropout$GradesTimesECTS, no_dropout$Group, mean)


### Passing the BSA

# All students
bsa_all <- table(all_data$PassedBSA, all_data$Group); bsa_all
prop.table(bsa_all, 2)
chisq.test(bsa_all)

# No drop-outs
bsa_no_dropout <- table(no_dropout$PassedBSA, no_dropout$Group); bsa_no_dropout
prop.table(bsa_no_dropout, 2)
chisq.test(bsa_no_dropout)


### Do certain groups drop out more often?
drop <- table(all_data$DropOut, all_data$Group); drop
chisq.test(drop)

## Collapse during and after year 1
all_data$DropOut2[all_data$DropOut != "No"] <- "Yes"
all_data$DropOut2[all_data$DropOut == "No"] <- "No"

drop2 <- table(all_data$DropOut2, all_data$Group); drop2
chisq.test(drop2)


### Do the 'better' Dutch students choose the English track?

# Select Dutch students only
dutch_data <- subject_info[subject_info$Nationality == "Dutch",]

# Descriptives per track
tapply(dutch_data$SchoolMean, dutch_data$Track, length)
tapply(dutch_data$SchoolMean, dutch_data$Track, summary)
tapply(dutch_data$SchoolMean, dutch_data$Track, sd, na.rm=TRUE)

tapply(dutch_data$SchoolEnglish, dutch_data$Track, length)
tapply(dutch_data$SchoolEnglish, dutch_data$Track, summary)
tapply(dutch_data$SchoolEnglish, dutch_data$Track, sd, na.rm=TRUE)

# Plot distribution of grades
hist(dutch_data$SchoolMean[dutch_data$Track == "English"], breaks=12)
hist(dutch_data$SchoolMean[dutch_data$Track == "Dutch"], breaks=12)

hist(dutch_data$SchoolEnglish[dutch_data$Track == "English"])
hist(dutch_data$SchoolEnglish[dutch_data$Track == "Dutch"])

# Are grades normally distributed? --> Not in the Dutch track
tapply(dutch_data$SchoolMean, dutch_data$Track, shapiro.test)
tapply(dutch_data$SchoolEnglish, dutch_data$Track, shapiro.test)

# Use non-parametric testing
wilcox.test(dutch_data$SchoolMean[dutch_data$Track=="English"], dutch_data$SchoolMean[dutch_data$Track=="Dutch"])
wilcox.test(dutch_data$SchoolEnglish[dutch_data$Track=="English"], dutch_data$SchoolEnglish[dutch_data$Track=="Dutch"])

# Since the p-value for SchoolMean is so close to significance (.07), also do a t-test for further exploration
t.test(dutch_data$SchoolMean[dutch_data$Track=="English"], dutch_data$SchoolMean[dutch_data$Track=="Dutch"])


### How do L1 and L2 lexical richness develop during the 1st year?

## Descriptives
tapply(lca_data$ld_oct, lca_data$Group, length) # n

lca_data %>%
  select(Group, ld_oct, ld_feb, ld_apr) %>%
  group_by(Group) %>%
  summarise_all("mean")

lca_data %>%
  select(Group, ld_oct, ld_feb, ld_apr) %>%
  group_by(Group) %>%
  summarise_all("sd")

## Visualisation: Lexical density

# Reshape data
ld_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("ld_oct", "ld_feb", "ld_apr"), value.name = "LD")
colnames(ld_melted)[colnames(ld_melted)=="variable"] <- "Month"
ld_melted$Month <- revalue(ld_melted$Month, c("ld_oct"="October", "ld_feb"="February", "ld_apr" = "April"))

# Visualise
ggplot(ld_melted, aes(x = Month, y = LD, linetype = Track, colour = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nMonth", y = "Lexical Density\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1))

## Visualisation: Lexical sophistication

# Reshape data
ls2_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("ls2_oct", "ls2_feb", "ls2_apr"), value.name = "LS2")
colnames(ls2_melted)[colnames(ls2_melted)=="variable"] <- "Month"
ls2_melted$Month <- revalue(ls2_melted$Month, c("ls2_oct"="October", "ls2_feb"="February", "ls2_apr" = "April"))

# Visualise
ggplot(ls2_melted, aes(x = Month, y = LS2, linetype = Track, colour = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nMonth", y = "Lexical Sophistication\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1))

## Visualisation: NDWESZ

# Reshape data
ndwesz_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("ndwesz_oct", "ndwesz_feb", "ndwesz_apr"), value.name = "NDWESZ")
colnames(ndwesz_melted)[colnames(ndwesz_melted)=="variable"] <- "Month"
ndwesz_melted$Month <- revalue(ndwesz_melted$Month, c("ndwesz_oct"="October", "ndwesz_feb"="February", "ndwesz_apr" = "April"))

# Visualise
ggplot(ndwesz_melted, aes(x = Month, y = NDWESZ/20, linetype = Track, colour = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nMonth", y = "Lexical Variation 1\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1))

#NB: I divided NDWESZ by 20 to obtain TTR. This is not the original measure.

## Visualisation: MSTTR

# Reshape data
msttr_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("msttr_oct", "msttr_feb", "msttr_apr"), value.name = "MSTTR")
colnames(msttr_melted)[colnames(msttr_melted)=="variable"] <- "Month"
msttr_melted$Month <- revalue(msttr_melted$Month, c("msttr_oct"="October", "msttr_feb"="February", "msttr_apr" = "April"))

# Visualise
ggplot(msttr_melted, aes(x = Month, y = MSTTR, linetype = Track, colour = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nMonth", y = "Lexical Variation 2\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1))

## Histograms

# Don't use German students in Dutch track
three_gr <- lca_data[lca_data$Group != "German_in_Dutch",]

# Investigate how the variables are distributed

# Lexical density
ld_oct <- ggplot(data = three_gr, aes(three_gr$ld_oct)) +
  geom_histogram(fill = "steelblue3") +
  facet_grid(~Group) +
  labs(x = "\nOctober", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

ld_feb <- ggplot(data = three_gr, aes(three_gr$ld_feb)) +
  geom_histogram(fill = "orange") +
  facet_grid(~Group) +
  labs(x = "\nFebruary", y = "Count\n") +
  ggtitle("Lexical density\n") +
  theme(plot.title = element_text(hjust = 0.5))

ld_apr <- ggplot(data = three_gr, aes(three_gr$ld_apr)) +
  geom_histogram(fill = "mediumpurple4") +
  facet_grid(~Group) +
  labs(x = "\nApril", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

# To plot the three graphs in one picture
grid.arrange(ld_oct, ld_feb, ld_apr, nrow=1, ncol=3)

# Lexical sophistication
ls2_oct <- ggplot(data = three_gr, aes(three_gr$ls2_oct)) +
  geom_histogram(fill = "steelblue3") +
  facet_grid(~Group) +
  labs(x = "\nOctober", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

ls2_feb <- ggplot(data = three_gr, aes(three_gr$ls2_feb)) +
  geom_histogram(fill = "orange") +
  facet_grid(~Group) +
  labs(x = "\nFebruary", y = "Count\n") +
  ggtitle("Lexical sophistication\n") +
  theme(plot.title = element_text(hjust = 0.5))

ls2_apr <- ggplot(data = three_gr, aes(three_gr$ls2_apr)) +
  geom_histogram(fill = "mediumpurple4") +
  facet_grid(~Group) +
  labs(x = "\nApril", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

# To plot the three graphs in one picture
grid.arrange(ls2_oct, ls2_feb, ls2_apr, nrow=1, ncol=3)

## Analyse grades
grades <- read.csv("data/grades.txt", header=TRUE, sep=",")

# Only use the grades of those students whose writing samples are used
good_subjects <- lca_data$SubjectCode

# Filter grades
grades <- grades[grades$SubjectCode %in% good_subjects,] # Probleem: lengte 317 in plaats van 314?


## Statistical analysis

# Merge long dataframes
long_data <- merge(ld_melted, ls2_melted, by=c("SubjectCode", "Track", "Nationality", "Group", "Month"))
long_data <- merge(long_data, ndwesz_melted, by=c("SubjectCode", "Track", "Nationality", "Group", "Month"))
long_data$Month <- factor(long_data$Month, levels = c("October", "February", "April"))

# Exclude Germans in the Dutch track
long_data <- long_data[long_data$Group != "German_in_Dutch",]

# Define outcome variable
outcome <- cbind(long_data$LD, long_data$LS2, long_data$NDWESZ)

# Run MANOVA
manova <- manova(outcome ~ Group + Month + Group * Month, data = long_data)
summary(manova)
summary.lm(manova)
summary.aov(manova)
