#This script is run after the fluorescence intensities of the images have been calculated using the 
#first two ImageJ scripts "define_rois.ijm" and "measure_fluorescence.ijm"
#It calculates the time when the peak calcium transient occurs in each of the cells, which is then used to create the overlay image in figure X
#It also plots the graph shown in figue X

library(tidyverse)
library(splitstackshape)
library(svglite)

#Folder location of the text file created by "measure_fluorescence.ijm" which contains fluorescence intensity measurements from all cells
fluorescence_intensity_folder <- "C:/Users/dw2471/OneDrive - cumc.columbia.edu/temp/fiji_analysis_output/test_data"

#Location of the ROI coordinates csv file that was created by the 'define_rois.ijm'
roi_coordinates_file <- "C:/Users/dw2471/OneDrive - cumc.columbia.edu/temp/fiji_analysis_output/ROIs/230329_d1_f5_DIC_ROI_coordinates.csv"

setwd(fluorescence_intensity_folder)
tps_files <- dir(fluorescence_intensity_folder,pattern = ".*analysis.txt")

#Imports test file
f_import <- function(x){read_tsv(x,
                                 col_names = T,
                                 id="FileName")
}
 
imported_data<-tps_files%>%
   map_df(.,f_import)
 
 
#Normalize to the first 6 frames (start of control period prior to drug addition)
f_normalize <- function(x){
   x/mean(x[1:6])
 }
 
all_data<-imported_data %>%
rename(Image_Number = 2)%>%
select(!contains("Number"))%>%
select(!contains("File"))

  normalized_data <- all_data%>%
    mutate(across(!contains("Time") & where(is.numeric),f_normalize))%>%
    rename(time_s = 1)

#Plots intensities of all cells
normalized_data%>%
  select(!contains("file"))%>%
 pivot_longer(-(time_s))%>%
  ggplot(.,aes(x=time_s,y=value,group=name))+
  geom_line()


##This calculates the time of peak fluorescence for each of the cells

#The maximum fluorescence change of each of the cells 
maximum_fluorescence<-normalized_data%>%
  pivot_longer(-time_s)%>%
  group_by(name)%>%
  summarise(maximum_fluorescence_change=max(value))

#Can select only cells with a maximum change in fluorescence above a defined threshold are included in the analysis
threshold = 2
above_threshold = maximum_fluorescence%>%
  filter(maximum_fluorescence_change>threshold)#%>%
  
#Matches the peak value with the time poin
long_normalized <- normalized_data %>%
  pivot_longer(-time_s,values_to = "fluorescence_change")

peak_times <- above_threshold %>%
  rename(fluorescence_change = maximum_fluorescence_change )%>%
  right_join(long_normalized,.,by=c("name","fluorescence_change"))%>%
  rename(time_of_calcium_peak = 1)%>%
  cSplit("name",sep=":")%>%
  rename(ROI_number = name_4)%>%
  select(!starts_with("name"))%>%
  mutate(ROI = sprintf("%03d", ROI_number))%>%
  select(-ROI_number)
 
  
#This loads the text file containing the x y coordinates of each ROI created by 'define_rois.ijm'
ROI_positions <- read_csv(roi_coordinates_file,
         col_names = T)%>%
  select(ROI,X,Y)%>%
  mutate(ROI_pad = sprintf("%03d", ROI))%>%
  select(-ROI)%>%
  rename(ROI=ROI_pad)

time_coordinates <- right_join(ROI_positions,peak_times,by="ROI")%>%
  arrange(time_of_calcium_peak)%>%
  rename(x=X,
         y=Y)

#Determines the coordinates of stimulated cell. It is simply uses the coordinates of the ROI of the cell which has the first calcium peak.
#It has the potential to cause problems if the peak of the stimulated cell is reached very slowly
origin <- as.numeric(time_coordinates[1,1:2])


#calculation of the distance of the center of the ROI from the first stimulated cell
euclidean <- function(x, y) {
  sqrt((x - origin[1])^2 + (y - origin[2])^2)
}

distances <-  time_coordinates%>%
  rowwise() %>%
  mutate(distance_from_stimulated_cell = euclidean(x, y))
  
#The calculates the time of the fluorescence peak of each cell relative to the stimulated cell
#Only ROIs which have an calcium transient within 30 s are included 
t_zero <- distances$time_of_calcium_peak[1]
distances_cut_off <-distances %>%
mutate(time_from_origin = ((time_of_calcium_peak-t_zero)))%>%
  filter(time_from_origin<30)

#This plots the distance of the responding cell from the stimulate cell vs the time when the fluorescence peak occurs
#From this we can calculate the speed of the calcium wave
spread.lm <- lm(distance_from_stimulated_cell ~ time_from_origin, distances_cut_off)
ggplot(distances_cut_off,aes(x=time_from_origin, y = distance_from_stimulated_cell))+
  geom_point()+
  geom_abline(slope = coef(spread.lm)[["time_from_origin"]], 
              intercept = coef(spread.lm)[["(Intercept)"]])+
  theme_classic()
ggsave("scatter_plots.svg",height = 3, width = 3)
  
  
#Plot fluorescence of selected ROIs

#ROIs that meet threshold
only_threshold_ROIs <- distances_cut_off$ROI%>%
  as_tibble()%>%
  rename(ROI = value)

#fluorescence data with ROIs
normalized_with_ROI <-normalized_data%>%
  pivot_longer(-time_s)%>%
  cSplit("name",sep=":")%>%
  rename(ROI_number = name_4)%>%
  select(!starts_with("name"))%>%
  mutate(ROI = sprintf("%03d", ROI_number))

subset_of_ROIs = "084|123|056|006"

right_join(normalized_with_ROI,only_threshold_ROIs,by="ROI")%>%
  filter(grepl(subset_of_ROIs,ROI))%>%
  #filter(grepl("084|133|006|077",ROI))%>%
  ggplot(.,aes(x=time_s,y=value,group=ROI))+
  geom_line(aes(color=ROI))+
  theme_classic()
ggsave("selected_fluorescence_intensity_plots.svg",height = 3, width = 3)
  
  
