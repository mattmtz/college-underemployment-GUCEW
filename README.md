# college-underemployment-GUCEW

## Overview
Assessing the overstatement of underemployment of workers with bachelor's degrees.

Use the "input/00_Setup.do" file to set the working directory, then run the .do file. All output in the current draft is in the "output/underemployment_analysis.xlsx" file, with additional graphs for alternative underemployment measures in the output folder as .png files. The underlying data can easily be sent to Excel by updating the code in the "code/" folder .do files starting with "D#_".

## Replication

In order to work with these files, create two local subfolders in the same folder as the "college-underemployment" repository folder: (1) a subfolder titled "IPUMS Data", and (2) a subfolder titled "intermediate". The "IPUMS Data" subfolder should contain an unzipped .dat file with the variables/observations defined in the "_documentation" subfolder of the repository. In the "code" subfolder, file "00_SETUP.do", change the name of the global variable "IPUMS" to match the name of the current .dat file.

The "intermediate" folder should remain empty; it will be populated once the code is run.

>[!NOTE]
> For any additional clarification questions or issues, please email Matt Martinez.


