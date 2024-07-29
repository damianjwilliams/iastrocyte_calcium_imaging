//This script creates an image in which the ROIs/cells are colored according to the time of the calcium peak. 
//Cells where the calcium peaks occurs later are a more yellow hue
//T=0 is the calcium peak time in the cell stimulated by the patch pipette (assuming it is the first cell to show a calcium response)

//This script requires the ROI locations are loaded from the ROI zip file into the ROI manager, and the corresponding image for the overlay is open (usually the transmitted light image)

//This script uses the output file from R, which contains the ROI locations and time of peak calcium transient. Usually only subset of ROIs are used.
//See the R script annotations for more details. 

//Opens the R output file and remove any ROIs that aren't included in the 
//R file
path = File.openDialog("Open R output file containing ROI numbers and time");  
Table.open(path)
imported_ROI_list = Table.getColumn("ROI"); // array of the selected ROI names from the R file output
ROI_manager_list = Array.getSequence(roiManager("count")+1);// array of all the ROIs originally created
ROI_manager_list = Array.slice(ROI_manager_list,1);
ROIs_to_remove_list = newArray(); 

//This loops through every ROI in ROI manager and tries to match it with an ROI from the imported ROI list.
//If there is no match, the ROI number is added to a list of ROIs to be deleted. 
for (i = 0; i < ROI_manager_list.length; i++) {
	val = ROI_manager_list[i];
	is_in_imported_ROI_list = false;
	for (j = 0; j < imported_ROI_list.length; j++) {
		if(val == imported_ROI_list[j]){
			is_in_imported_ROI_list = true;
			break;
		}
	}
	if(!is_in_imported_ROI_list){
		ROIs_to_remove_list =Array.concat(ROIs_to_remove_list,val-1);
	}
}

//Deletes all of the ROIs in the ROIs_to_remove_list
Array.print(ROIs_to_remove_list); 
roiManager("Select",ROIs_to_remove_list);
roiManager("delete");

//The remaining ROIs still are still ordered on the basis of when they were inititally added to the ROI
//rather than the order of the peak times from the R output file. The result of this is that the wrong colors
//are assigned to the ROIs in the coloring step
//This code reorders the ROIs correctly

//This is acheived by going through the correctly ordered ROI names in R output file
//and re-adding the corresponding ROI in the ROI manager to the ROI manager and deleting the original.
//Given that the ROIs are ordered based on when they were added,  
//re-adding the ROIs in the order of the R output file will correct the order in ROI manager    
 ROIs_from_R_ouput = Table.getColumn("ROI");//ROIs in the correct order from the R output file
Array.print(ROIs_from_R_ouput);
ROIs_from_ROI_manager = Array.getSequence(roiManager("count")+1);//ROIs ordered incorrectly from ROI manager
ROIs_from_ROI_manager = Array.slice(ROIs_from_ROI_manager,1);

//Gets the count of ROIs in the manager
roi_index_array_del = Array.getSequence(roiManager("count"));
Array.print(roi_index_array_del);
print(roi_index_array_del.length) 

//This loops through each ROI in the R output 
for (j=0; j<ROIs_from_R_ouput.length; j++){

//Formats the name of the ROI from the R output file
current_roi = ROIs_from_R_ouput[j];
ROIname = IJ.pad(current_roi, 3);
print("name:\t"+ROIname);

//Finds the index of the where the ROI name from the R output occurs in the ROI manager
index_id = RoiManager.getIndex(ROIname);
print("index id"+index_id);
roiManager("Select", index_id);
wait(100);

//Then the ROI  is copied to the end of the ROI manager
roiManager("Add");
//
}

//The original ROI is deleted 
roiManager("Select",roi_index_array_del);
roiManager("delete");

//This uses the ROI_Color_Coder.ijm macro https://imagejdocu.list.lu/macro/roi_color_coder
//Colorizes ROIs listed in the ROI Manager by matching the time of the peak calcium (originally from the R output file)
//to a color of a lookup table
run("ROI Color Coder", "colorize=time_point using=viridis");
//The color of the ROI outline is set, but this must be changed to the fill color
selectWindow("ROI Manager");
roi_no = roiManager("count"); 
init_roi_no = roiManager("count");
for (j=0; j<init_roi_no; j++){ 
	roiManager("select", j);
	print(j);
	outline_color = Roi.getStrokeColor();
	roiManager("Set Fill Color", outline_color);
	
	} 