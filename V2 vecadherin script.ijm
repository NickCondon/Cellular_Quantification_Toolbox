print("\\Clear");
//	MIT License
//	Copyright (c) 2020 Nicholas Condon n.condon@uq.edu.au
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.
scripttitle= "AlexYU_Kymograph_";
version= "0.1";
date= "23-10-2020";
description= "Description";
showMessage("Institute for Molecular Biosciences ImageJ Script", "<html>
    +"<h1><font size=6 color=Teal>ACRF: Cancer Biology Imaging Facility</h1>
    +"<h1><font size=5 color=Purple><i>The University of Queensland</i></h1>
    +"<h4><a href=http://imb.uq.edu.au/Microscopy/>ACRF: Cancer Biology Imaging Facility</a><h4>
    +"<h1><font color=black>ImageJ Script Macro: "+scripttitle+"</h1> 
    +"<p1>Version: "+version+" ("+date+")</p1>"
    +"<H2><font size=3>Created by Nicholas Condon</H2>"
    +"<p1><font size=2> contact n.condon@uq.edu.au \n </p1>" 
    +"<P4><font size=2> Available for use/modification/sharing under the "+"<p4><a href=https://opensource.org/licenses/MIT/>MIT License</a><h4> </P4>"
    +"<h3>   <h3>"    
    +"<p1><font size=3  i>"+description+"</p1>
    +"<h1><font size=2> </h1>"  
	   +"<h0><font size=5> </h0>"
    +"");
print("");
print("FIJI Macro: "+scripttitle);
print("Version: "+version+" Version Date: "+date);
print("ACRF: Cancer Biology Imaging Facility");
print("By Nicholas Condon (2020) n.condon@uq.edu.au")
print("");
getDateAndTime(year, month, week, day, hour, min, sec, msec);
print("Script Run Date: "+day+"/"+(month+1)+"/"+year+"  Time: " +hour+":"+min+":"+sec);
print("");

//Directory Warning and Instruction panel     
Dialog.create("Choosing your working directory.");
 	Dialog.addMessage("Use the next window to navigate to the directory of your images.");
  	Dialog.addMessage("(Note a sub-directory will be made within this folder for output files) ");
  	Dialog.addMessage("Take note of your file extension (eg .tif, .czi)");
Dialog.show(); 

//Directory Location
path = getDirectory("Choose Source Directory ");
list = getFileList(path);
getDateAndTime(year, month, week, day, hour, min, sec, msec);

ext = ".czi";
Dialog.create("Settings");
Dialog.addString("File Extension: ", ext);
Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
Dialog.show();
ext = Dialog.getString();

start = getTime();

//Creates Directory for output images/logs/results table
resultsDir = path+"_Results_"+"_"+year+"-"+month+"-"+day+"_at_"+hour+"."+min+"/"; 
File.makeDirectory(resultsDir);
print("Working Directory Location: "+path);
summaryFile = File.open(resultsDir+"Results_"+"_"+year+"-"+month+"-"+day+"_at_"+hour+"."+min+".xls");
print(summaryFile,"Image Name \t Image Number \t Line Number \t Line Length \t Line Position \t Width \t r^2 \t r^2 Thresh \t 0.95");


for (z=0; z<list.length; z++) {
if (endsWith(list[z],ext)){

		run("Bio-Formats Importer", "open=["+path+list[z]+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		run("Clear Results");
		roiManager("reset");
		roiManager("show all with labels");
		run("Z Project...", "projection=[Max Intensity]");
		windowtitle = getTitle();
		run("Duplicate...", "title=actin duplicate channels=2");
		
		print("Opening File: "+(z+1)+" of "+list.length+"  Filename: "+windowtitle);
		windowtitlenoext = replace(windowtitle, ext, "");
		
		setTool("polyline");
		
		
		doneNow = 0;							//variable for exiting ROIselection loop
	
		while(doneNow !=1){
			waitForUser("Draw your shape! (Then click ok)");		//wait for user allows you to click stuff
			if(selectionType()>0){  roiManager("add");}				//only adds a selection if the user made one								
			
			Dialog.create("I Choo Choo Choooose ROIs");				//allows for exit sequence to be chosen
			Dialog.addCheckbox("Tick me when your done:", 0);
			Dialog.show();
			doneNow = Dialog.getCheckbox();							//updates variable from selection (if ticked =1, so wont keep running)
		}
	setBatchMode(true);
		run("Clear Results");										//why wouldnt you clear results
		if(roiManager("count")==0){exit("Macro Aborted! No ROIs Created")};		//exits is no selection was made
		
		for (y = 0; y < roiManager("count"); y++) {								
			print("Measuring Line #"+(y+1));
			selectWindow("actin");
			roiManager("Select",y);									//selects first ROI
			roiManager("Rename",(y+1));								//Renames it from base 0
			run("Straighten...", "title=[straighten] line=100 process");
			run("Gaussian Blur...", "sigma=2");
			getDimensions(width, height, channels, slices, frames);
			FWHMArray = newArray(width+1);
			setLineWidth(2);
			for (i=0;i<width; i++){
				makeLine(i, 0, i, height);
				run("Plot Profile");
				Plot.getValues(xpoints, ypoints);
				Fit.doFit("Gaussian", xpoints, ypoints);
				sigma=Fit.p(3);
				rSqrd = Fit.rSquared;
				FWHM=abs(2*sqrt(2*log(2))*sigma);
				print("Width at position "+i+" = "+FWHM);
				FWHMArray[i] = FWHM;
				selectWindow("Plot of straighten"); close();
				print(summaryFile, windowtitle+"\t"+(z+1)+"\t"+(y+1)+"\t"+width+"\t"+i+"\t"+FWHM+"\t"+rSqrd+"\t \t"+"=IF(G"+(i+2)+">$I$1, 1, 0)");		
			}
			setBatchMode(false);
			close();	
		}		
while(nImages>0){close();}
roiManager("save", resultsDir+windowtitle+"_ROIs.zip");







		}}
		selectWindow("Log");
		saveAs("Text", "Log.txt");
//exit message to notify user that the script has finished.
title = "Batch Completed";
msg = "Put down that coffee! Your analysis is finished";
waitForUser(title, msg);
