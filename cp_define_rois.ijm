//This script is used to define the locations of the cells for quantification of the fluorescence images.
//Outlines encompassing cells are drawn using the template image as a guide
//A file containing the location of the cells (or "regions of interest") is created
//This file is then used to define the locaton of cells in fluorescence image series 


//Defines the file path where the ROI files will be saved
output_folder = "C:\\Users\\dw2471\\OneDrive - cumc.columbia.edu\\temp\\fiji_analysis_output\\ROIs\\"

if (isOpen("ROI Manager")) { 
 selectWindow("ROI Manager"); 
 run("Close"); 
} 

//open the template image 
open("");
ROIfile = File.name;
ROIpath = File.directory;
FileSaveName = File.nameWithoutExtension;

//A popup box will appear with a number of files
//waitForUser("Measure Background");
Dialog.create("Imaging info");
//Selects which Ca indicator dye is used. It is only important when Fura-2 is used 
//because there are two images acquired at each timepoint, so the analysis is slightly different
Dialog.addChoice("Ca2+ indicator:", newArray("Fura-2", "Fura-2 single wl", "Fluo-4","Cal-590","GCaMP5"));
//The choice of objective determines the size of the image 
Dialog.addChoice("Objective:", newArray("40x", "20x"));
//This is an opportunity to add a identifier to the image. A single short string with no spaces. Maybe genotype, cell type, condition etc...
Dialog.addString("Cell ID"," ");
//Used if there is a background value which needs to be removed from the fluorescence images (can be ignored; not used here)
Dialog.addNumber("Background",0);
Dialog.show();
dye = Dialog.getChoice();
objtype = Dialog.getChoice();
LineID = Dialog.getString();
Background = Dialog.getNumber();

//The contents of fields of the popup box are saved as metadata embedded in a new copy of the template image, and as a separate text file.
//These values are used in the analysis of the fluorescence images
infostring = "\""+dye+"\" "+"\""+objtype+"\" "+"\""+LineID+"\" "+"\""+Background+"\"";
run("Select All");
run("Copy");
run("Internal Clipboard");
setMetadata("Info", infostring);
saveAs("tiff", output_folder+FileSaveName+".tif");
run("Show Info...");
selectWindow("Info for "+FileSaveName+".tif");
saveAs("Text", output_folder+FileSaveName+"_Batch_metadata.txt");
run("Close"); 

//ROIs are drawn on the template image manually
waitForUser("Define ROIs");
roi_no = roiManager("count"); 
init_roi_no = roiManager("count");

//ROIs are renamed and saved
for (j=0; j<init_roi_no; j++){ 
	roiManager("select", j);
	ROIname = IJ.pad(j+1, 3);
	roiManager("Rename", ROIname);
	} 
roiManager("Remove Slice Info");
roiManager("Save", output_folder+FileSaveName+"_ROIs.zip");


//ROI coordinates saved as a csv file
table1 = "Results";
Table.create(table1);
roi_no = roiManager("count"); 
init_roi_no = roiManager("count");
for (j=0; j<init_roi_no; j++){ 
	roiManager("select", j);
	x_coord = getValue("X");
	y_coord = getValue("Y");
	Table.set("ROI", j, j+1);
    Table.set("X", j, x_coord);
     Table.set("Y", j, y_coord);

}

Table.update;
Table.save(output_folder+FileSaveName+"_ROI_coordinates.csv");

//A template image with the regions of interest identified is saved 
run("Select All");
run("Copy");
run("Internal Clipboard");
roiManager("Show All with labels");
roiManager("Show All");
run("Flatten");
saveAs("Jpeg", output_folder+FileSaveName+"_ROI_map");
close();
close();
close();
close();



