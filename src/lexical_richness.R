# Import libraries
library(boot) # Function 'boot' for bootstrapping
library(emmeans) # Estimated marginal means for multiple comparisons
library(plyr) # Function 'revalue' to rename variable levels
library(dplyr) # Function 'select'
library(ggplot2) # Function 'ggplot' for data visualisation
library(gridExtra) # Function 'grid.arrange' to order graphs
library(influence.ME) # Function 'cooks.distanc.estex' to check fit and assumptions of linear models
library(lme4) # Function 'lmer' for linear mixed-effects modelling
library(pastecs) # Function 'stat.desc' for descriptive statistics
library(reshape2) # Functions 'dcast' (long -> wide) and 'melt' (wide -> long)
library(scales) # Function 'pretty_breaks' to use within ggplot

# Clear workspace
rm(list=ls())

# Set working directory to the current file location
# Can be done through 'Session' tab in RStudio 


### ------------------------
### Read and preprocess data
### ------------------------

# Read in data
lca_data <- read.csv("../data/lexical_richness.txt", header=TRUE, sep="\t")
lca_data$SubjectCode <- as.factor(lca_data$SubjectCode)

# Calculate overall lexical richness scores and average number of word tokens
lca_data$LD <- rowMeans(cbind(lca_data$ld_oct, lca_data$ld_feb, lca_data$ld_apr))
lca_data$LS <- rowMeans(cbind(lca_data$ls2_oct, lca_data$ls2_feb, lca_data$ls2_apr))
lca_data$LV <- rowMeans(cbind(lca_data$ndwesz_oct, lca_data$ndwesz_feb, lca_data$ndwesz_apr))
lca_data$tokens <- rowMeans(cbind(lca_data$wordtokens_oct, lca_data$wordtokens_feb, lca_data$wordtokens_apr))

# For each measure, transform to a long data frame
ld_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("ld_oct", "ld_feb", "ld_apr"), value.name = "LD")
colnames(ld_melted)[colnames(ld_melted)=="variable"] <- "Exam"
ld_melted$Exam <- revalue(ld_melted$Exam, c("ld_oct"="1 (Oct)", "ld_feb"="2 (Feb)", "ld_apr" = "3 (Apr)"))

ls_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("ls2_oct", "ls2_feb", "ls2_apr"), value.name = "LS")
colnames(ls_melted)[colnames(ls_melted)=="variable"] <- "Exam"
ls_melted$Exam <- revalue(ls_melted$Exam, c("ls2_oct"="1 (Oct)", "ls2_feb"="2 (Feb)", "ls2_apr" = "3 (Apr)"))

lv_melted <- melt(lca_data, id.vars=c("SubjectCode", "Track", "Nationality", "Group"), measure.vars = c("ndwesz_oct", "ndwesz_feb", "ndwesz_apr"), value.name = "LV")
colnames(lv_melted)[colnames(lv_melted)=="variable"] <- "Exam"
lv_melted$Exam <- revalue(lv_melted$Exam, c("ndwesz_oct"="1 (Oct)", "ndwesz_feb"="2 (Feb)", "ndwesz_apr" = "3 (Apr)"))

# Merge long dataframes
lca_long <- merge(ld_melted, ls_melted, by=c("SubjectCode", "Track", "Nationality", "Group", "Exam"))
lca_long <- merge(lca_long, lv_melted, by=c("SubjectCode", "Track", "Nationality", "Group", "Exam"))

# Add grades
lca_long$Grade <- ifelse(lca_long$Exam == "1 (Oct)", lca_data$grade_oct[match(lca_long$SubjectCode, lca_data$SubjectCode)], 
                  ifelse(lca_long$Exam == "2 (Feb)", lca_data$grade_feb[match(lca_long$SubjectCode, lca_data$SubjectCode)],
                  ifelse(lca_long$Exam == "3 (Apr)", lca_data$grade_apr[match(lca_long$SubjectCode, lca_data$SubjectCode)], NA)))
  
# Remove unused dataframes
#rm(list=ls(pattern="_melted"))


### -----------------------------------------
### Exam descriptives: Text length and grades
### -----------------------------------------

# Function to bootstrap the precision of test statistics
bootstrap <- function(data, func, iter){
  data <- na.omit(data)
  boot_sample <- boot(data, function(x,i) func(x[i]), iter)
  print("The original statistic is:")
  print(round(boot_sample$t0, 2))
  print("The bootstrapped standard error of the statistic is:")
  se <- sd(boot_sample$t)
  print(round(se, 2))
  print("The bootstrapped standard deviation of the statistic is:")
  sd <- se * sqrt(length(data))
  print(round(sd,2))
  ci <- boot.ci(boot_sample, type = "bca", conf = 1-alpha)
  print("The BCa confidence intervals of the statistic are:")
  print(round(ci$bca[,4],2)); print(round(ci$bca[,5],2))
}

# Text length descriptives
tapply(lca_data$wordtokens_oct, lca_data$Group, bootstrap, func=mean, iter=10000) # Per group
bootstrap(lca_data$wordtokens_oct, func=mean, iter=10000) # Overall

tapply(lca_data$wordtokens_feb, lca_data$Group, bootstrap, func=mean, iter=10000)
bootstrap(lca_data$wordtokens_feb, func=mean, iter=10000)

tapply(lca_data$wordtokens_apr, lca_data$Group, bootstrap, func=mean, iter=10000)
bootstrap(lca_data$wordtokens_apr, func=mean, iter=10000)

# Grade descriptives
tapply(lca_data$grade_oct, lca_data$Group, bootstrap, func=mean, iter=10000)
bootstrap(lca_data$grade_oct, func=mean, iter=10000)

tapply(lca_data$grade_feb, lca_data$Group, bootstrap, func=mean, iter=10000)
bootstrap(lca_data$grade_feb, func=mean, iter=10000)

tapply(lca_data$grade_apr, lca_data$Group, bootstrap, func=mean, iter=10000)
bootstrap(lca_data$grade_apr, func=mean, iter=10000)

# Visualise grade distributions
hist_grades_oct <- ggplot(data = lca_data, aes(grade_oct, fill = Group)) +
  geom_histogram(col = "white", binwidth = 0.5) +
  facet_grid(~Group) +
  labs(x = "\nHistograms of grades on Exam 1", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks=pretty_breaks(n=6)); hist_grades_oct

hist_grades_feb <- ggplot(data = lca_data, aes(grade_feb, fill = Group)) +
  geom_histogram(col = "white", binwidth = 0.5) +
  facet_grid(~Group) +
  labs(x = "\nHistograms of grades on Exam 2", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks=pretty_breaks(n=6)); hist_grades_feb

hist_grades_apr <- ggplot(data = lca_data, aes(grade_apr, fill = Group)) +
  geom_histogram(col = "white", binwidth = 0.5) +
  facet_grid(~Group) +
  labs(x = "\nHistograms of grades on Exam 3", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks=pretty_breaks(n=6)); hist_grades_apr


### ----------------------------------------------------
### Descriptives for the development of lexical richness
### ----------------------------------------------------

## Summary statistics
tapply(lca_data$ld_oct, lca_data$Group, length) # n

dplyr::select(lca_data, Group, ld_oct, ld_feb, ld_apr) %>%
  group_by(Group) %>%
  summarise_all("mean")  

dplyr::select(lca_data, Group, ld_oct, ld_feb, ld_apr) %>%
  group_by(Group) %>%
  summarise_all("sd")


## Visualisation

# Lexical density
tiff("../figures/Chapter 5 - Figure 1.tiff", units="in", width=7, height=4, res=300)
ld <- ggplot(ld_melted, aes(x = Exam, y = LD, linetype = Track, colour = Nationality, shape = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nExam", y = "Lexical density\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1)); ld
dev.off()

# Lexical sophistication
tiff("../figures/Chapter 5 - Figure 2.tiff", units="in", width=7, height=4, res=300)
ls <- ggplot(ls_melted, aes(x = Exam, y = LS, linetype = Track, colour = Nationality, shape = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nExam", y = "Lexical sophistication\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1)); ls
dev.off()

# Lexical variation
tiff("../figures/Chapter 5 - Figure 3.tiff", units="in", width=7, height=4, res=300)
lv <- ggplot(lv_melted, aes(x = Exam, y = LV, linetype = Track, colour = Nationality, shape = Nationality, group = interaction(Track, Nationality))) +
  stat_summary(fun.y = mean, geom = "point", size = 4) + 
  stat_summary(fun.y = mean, geom = "line", size = 2) +
  stat_summary(fun.data = mean_cl_boot, geom = "errorbar", linetype = "solid", alpha = 0.75, size = 1, width = 0.5, position = position_dodge(width = 0.05)) +
  theme(text = element_text(size = 20), axis.text.y = element_text(size = 18), axis.text.x = element_text(size = 18), strip.text = element_text(size=18)) +
  labs(x = "\nExam", y = "Lexical variation\n") +
  scale_color_manual(values=c("orange", "steelblue3")) +
  guides(linetype=guide_legend(keywidth = 2, keyheight = 1),
         colour=guide_legend(keywidth = 2, keyheight = 1)); lv
#NB: LV can be divided by 20 to obtain TTR. This is not the original measure.
dev.off()

### --------------------------------------------------------------
### Investigate how the lexical richness variables are distributed
### --------------------------------------------------------------

# Don't use German students in Dutch track
three_gr <- lca_data[lca_data$Group != "German_in_Dutch",]

## Lexical density
ld_oct <- ggplot(data = three_gr, aes(three_gr$ld_oct)) +
  geom_histogram(col = "white", fill = "steelblue3") +
  facet_grid(~Group) +
  labs(x = "\nOctober", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

ld_feb <- ggplot(data = three_gr, aes(three_gr$ld_feb)) +
  geom_histogram(col = "white", fill = "orange") +
  facet_grid(~Group) +
  labs(x = "\nFebruary", y = "Count\n") +
  ggtitle("Lexical density\n") +
  theme(plot.title = element_text(hjust = 0.5))

ld_apr <- ggplot(data = three_gr, aes(three_gr$ld_apr)) +
  geom_histogram(col = "white", fill = "mediumpurple4") +
  facet_grid(~Group) +
  labs(x = "\nApril", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

# To plot the three graphs in one picture
grid.arrange(ld_oct, ld_feb, ld_apr, nrow=1, ncol=3)

## Lexical sophistication
ls2_oct <- ggplot(data = three_gr, aes(three_gr$ls2_oct)) +
  geom_histogram(col = "white", fill = "steelblue3") +
  facet_grid(~Group) +
  labs(x = "\nOctober", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

ls2_feb <- ggplot(data = three_gr, aes(three_gr$ls2_feb)) +
  geom_histogram(col = "white", fill = "orange") +
  facet_grid(~Group) +
  labs(x = "\nFebruary", y = "Count\n") +
  ggtitle("Lexical sophistication\n") +
  theme(plot.title = element_text(hjust = 0.5))

ls2_apr <- ggplot(data = three_gr, aes(three_gr$ls2_apr)) +
  geom_histogram(col = "white", fill = "mediumpurple4") +
  facet_grid(~Group) +
  labs(x = "\nApril", y = "Count\n") +
  ggtitle("\n") +
  theme(plot.title = element_text(hjust = 0.5))

# Plot the three graphs in one picture
grid.arrange(ls2_oct, ls2_feb, ls2_apr, nrow=1, ncol=3)


### --------------------------------------------------------
### How does lexical richness develop during the first year?
### --------------------------------------------------------

### Lexical density

# Model comparisons
exam_LD <- lmer(LD ~ 1 + Exam + (1|SubjectCode), data = lca_long, REML = FALSE); summary(exam_LD)
grade_LD <- update(exam_LD, .~. + Grade); summary(grade_LD)
anova(exam_LD, grade_LD)

exam_group_LD <- update(exam_LD, .~. + Group); summary(exam_group_LD)
exam_group_int_LD <- update(exam_group_LD, .~. + Exam:Group); summary(exam_group_int_LD)
anova(exam_LD, exam_group_LD, exam_group_int_LD)

## Multiple comparisons

# Research question 1: Compare overall LD scores
group.emm_LD <- emmeans(exam_group_int_LD, ~ Group); group.emm_LD
pairs(group.emm_LD, adjust = "none")
confint(pairs(group.emm_LD, adjust = "none"))

# Research questions 2 and 3: Compare development of LD scores
exam_group.emm_LD <- emmeans(exam_group_int_LD, ~ Exam*Group); exam_group.emm_LD
pairs(exam_group.emm_LD, simple = c("Group", "Exam"), adjust = "none", interaction = TRUE)
pairs(exam_group.emm_LD, by = "Exam", adjust = "none")

## Check assumptions (see Winter, 2013)

## Is there a linear relationship between the dependent and independent variables?
# The plot should not show any obvious pattern in the residuals

## Homoskedasticity
# The standard deviations of the residuals should not depend on the x-value

tiff("../figures/Chapter 5 - Figure A.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
plot(fitted(exam_group_LD), residuals(exam_group_LD), main = "LD: Residual plot (Model 3)", xlab = "Predicted values", ylab = "Residual values"); abline(h = 0)
plot(fitted(exam_group_int_LD), residuals(exam_group_int_LD), main = "LD: Residual plot (Model 4)", xlab = "Predicted values", ylab = "Residual values"); abline(h = 0)
dev.off()

## Absence of collinearity
# Exam and Group are not correlated, because all groups took the same exams

## Normality of residuals
tiff("../figures/Chapter 5 - Figure B.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
hist(residuals(exam_group_LD), main = "LD: Histogram of residuals (Model 3)", xlab = "Residual value") # Seems normal
hist(residuals(exam_group_int_LD), main = "LD: Histogram of residuals (Model 4)", xlab = "Residual value") # Seems normal
dev.off()

qqnorm(residuals(exam_group_LD))
qqnorm(residuals(exam_group_int_LD))

## Absence of influential data points

# Calculate Cook's distance and visualise outcomes
lca_data$Cook_LD <- cooks.distance.estex(influence(exam_group_LD, group = 'SubjectCode'))
plot(lca_data$Cook_LD, ylab = "Cook's distance")

lca_data$Cook_int_LD <- cooks.distance.estex(influence(exam_group_int_LD, group = 'SubjectCode'))
plot(lca_data$Cook_int_LD, ylab = "Cook's distance")
# Different guidelines. Either, Cook's distance should not be >1 or >0.85 (assumption met)
# Or, it shouldn't be >4/n (assumption not met, but no real outliers)

## Independence
# Is taken care of by the random intercepts at the subject level

## Are the random coefficients normally distributed?
subject_intercepts <- ranef(exam_group_LD)[[1]]
subject_intercepts <- as.vector(subject_intercepts$`(Intercept)`)

subject_intercepts <- ranef(exam_group_int_LD)[[1]]
subject_intercepts <- as.vector(subject_intercepts$`(Intercept)`)

tiff("../figures/Chapter 5 - Figure C.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
hist(subject_intercepts, main = "LD: Histogram of subject intercepts (Model 3)", xlab = "Subject intercept")
hist(subject_intercepts, main = "LD: Histogram of subject intercepts (Model 4)", xlab = "Subject intercept")
dev.off()

### Lexical sophistication

# Model comparisons
exam_LS <- lmer(LS ~ 1 + Exam + (1|SubjectCode), data = lca_long, REML = FALSE)
grade_LS <- update(exam_LS, .~. + Grade); summary(grade_LS)
anova(exam_LS, grade_LS)

exam_group_LS <- update(grade_LS, .~. + Group); summary(exam_group_LS)
exam_group_int_LS <- update(exam_group_LS, .~. + Exam:Group); summary(exam_group_int_LS)
anova(grade_LS, exam_group_LS, exam_group_int_LS)

## Multiple comparisons

# Research question 1: Compare overall LS scores
group.emm_LS <- emmeans(exam_group_int_LS, ~ Group); group.emm_LS
pairs(group.emm_LS, adjust = "none")

# Research questions 2 and 3: Compare development of LS scores
exam_group.emm_LS <- emmeans(exam_group_int_LS, ~ Exam*Group); exam_group.emm_LS
pairs(exam_group.emm_LS, simple = c("Group", "Exam"), adjust = "none", interaction = TRUE)
pairs(exam_group.emm_LS, by = "Exam", adjust = "none")

## Check assumptions (see Winter, 2013)

## Is there a linear relationship between the dependent and independent variables?
# The plot should not show any obvious pattern in the residuals

## Homoskedasticity
# The standard deviations of the residuals should not depend on the x-value

tiff("../figures/Chapter 5 - Figure D.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
plot(fitted(exam_group_LS), residuals(exam_group_LS), main = "LS: Residual plot (Model 3)", xlab = "Predicted values", ylab = "Residual values"); abline(h = 0)
plot(fitted(exam_group_int_LS), residuals(exam_group_int_LS), main = "LS: Residual plot (Model 4)", xlab = "Predicted values", ylab = "Residual values"); abline(h = 0)
dev.off()

## Normality of residuals
tiff("../figures/Chapter 5 - Figure E.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
hist(residuals(exam_group_LS), main = "LS: Histogram of residuals (Model 3)", xlab = "Residual value") # Seems normal
hist(residuals(exam_group_int_LS), main = "LS: Histogram of residuals (Model 4)", xlab = "Residual value") # Seems normal
dev.off()

qqnorm(residuals(exam_group_LS))
qqnorm(residuals(exam_group_int_LS))

## Absence of influential data points

# Calculate Cook's distance and visualise outcomes
lca_data$Cook_LS <- cooks.distance.estex(influence(exam_group_LS, group = 'SubjectCode'))
plot(lca_data$Cook_LS, ylab = "Cook's distance")

lca_data$Cook_int_LS <- cooks.distance.estex(influence(exam_group_int_LS, group = 'SubjectCode'))
plot(lca_data$Cook_int_LS, ylab = "Cook's distance")
# Different guidelines. Either, Cook's distance should not be >1 or >0.85 (assumption met)
# Or, it shouldn't be >4/n (assumption not met, but no real outliers)

## Are the random coefficients normally distributed?
subject_intercepts <- ranef(exam_group_LS)[[1]]
subject_intercepts <- as.vector(subject_intercepts$`(Intercept)`)

subject_intercepts <- ranef(exam_group_int_LS)[[1]]
subject_intercepts <- as.vector(subject_intercepts$`(Intercept)`)

tiff("../figures/Chapter 5 - Figure F.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
hist(subject_intercepts, main = "LS: Histogram of subject intercepts (Model 3)", xlab = "Subject intercept")
hist(subject_intercepts, breaks = 12, main = "LS: Histogram of subject intercepts (Model 4)", xlab = "Subject intercept")
dev.off()


### Lexical variation

# Model comparisons
exam_LV <- lmer(LV ~ 1 + Exam + (1|SubjectCode), data = lca_long, REML = FALSE)
grade_LV <- update(exam_LV, .~. + Grade); summary(grade_LV)
anova(exam_LV, grade_LV)

exam_group_LV <- update(exam_LV, .~. + Group); summary(exam_group_LV)
exam_group_int_LV <- update(exam_group_LV, .~. + Exam:Group); summary(exam_group_int_LV)
anova(exam_LV, exam_group_LV, exam_group_int_LV)

## Multiple comparisons

# Research question 1: Compare overall LV scores
group.emm_LV <- emmeans(exam_group_int_LV, ~ Group); group.emm_LV
pairs(group.emm_LV, adjust = "none")

# Research questions 2 and 3: Compare development of LV scores
exam_group.emm_LV <- emmeans(exam_group_int_LV, ~ Exam*Group); exam_group.emm_LV
pairs(exam_group.emm_LV, simple = c("Group", "Exam"), adjust = "none", interaction = TRUE)
pairs(exam_group.emm_LV, by = "Exam", adjust = "none")

## Check assumptions (see Winter, 2013)

## Is there a linear relationship between the dependent and independent variables?
# The plot should not show any obvious pattern in the residuals

## Homoskedasticity
# The standard deviations of the residuals should not depend on the x-value

tiff("../figures/Chapter 5 - Figure G.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
plot(fitted(exam_group_LV), residuals(exam_group_LV), main = "LV: Residual plot (Model 3)", xlab = "Predicted values", ylab = "Residual values"); abline(h = 0) # A bimodal distribution appears
plot(fitted(exam_group_int_LV), residuals(exam_group_int_LV), main = "LV: Residual plot (Model 4)", xlab = "Predicted values", ylab = "Residual values"); abline(h = 0) # Slightly visible, but much better
dev.off()

## Normality of residuals
tiff("../figures/Chapter 5 - Figure H.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
hist(residuals(exam_group_LV), main = "LV: Histogram of residuals (Model 3)", xlab = "Residual value") # Quite normal, but skewed to the left
hist(residuals(exam_group_int_LV), main = "LV: Histogram of residuals (Model 4)", xlab = "Residual value") # Quite normal, but skewed to the left
dev.off()

qqnorm(residuals(exam_group_LV))
qqnorm(residuals(exam_group_int_LV))

## Absence of influential data points

# Calculate Cook's distance and visualise outcomes
lca_data$Cook_LV <- cooks.distance.estex(influence(exam_group_LV, group = 'SubjectCode'))
plot(lca_data$Cook_LV, ylab = "Cook's distance")

lca_data$Cook_int_LV <- cooks.distance.estex(influence(exam_group_int_LV, group = 'SubjectCode'))
plot(lca_data$Cook_int_LV, ylab = "Cook's distance")
# Different guidelines. Either, Cook's distance should not be >1 or >0.85 (assumption met)
# Or, it shouldn't be >4/n (assumption not met, but no real outliers)

## Are the random coefficients normally distributed?
subject_intercepts <- ranef(exam_group_LV)[[1]]
subject_intercepts <- as.vector(subject_intercepts$`(Intercept)`)

subject_intercepts <- ranef(exam_group_int_LV)[[1]]
subject_intercepts <- as.vector(subject_intercepts$`(Intercept)`)

tiff("../figures/Chapter 5 - Figure I.tiff", units="in", width=11, height=4, res=300)
par(mfrow=c(1,2))
hist(subject_intercepts, main = "LV: Histogram of subject intercepts (Model 3)", xlab = "Subject intercept")
hist(subject_intercepts, breaks = 8, main = "LV: Histogram of subject intercepts (Model 4)", xlab = "Subject intercept")
dev.off()


### ------------
### LexTALE data
### ------------

lex <- read.delim("../data/lextale.txt", header = TRUE, sep = "\t")

# Different in English skills?
tapply(lex$SchoolEnglish, lex$Track, stat.desc)
tapply(lex$SchoolEnglish, lex$Track, shapiro.test)
wilcox.test(lex$SchoolEnglish ~ lex$Track)

# Subset matched data
lex_matched <- lex[lex$Include == "Yes",]

# Check that the English school grade is the same for both groups
tapply(lex_matched$SchoolEnglish, lex_matched$Track, stat.desc)

# Different in LexTALE?
tapply(lex_matched$LexTALE, lex_matched$Track, stat.desc)
tapply(lex_matched$LexTALE, lex_matched$Track, shapiro.test)

hist(lex_matched$LexTALE[lex_matched$Track=="Dutch"])
hist(lex_matched$LexTALE[lex_matched$Track=="English"])

wilcox.test(lex_matched$LexTALE ~ lex_matched$Track)
t.test(lex_matched$LexTALE ~ lex_matched$Track)
