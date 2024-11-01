# college-underemployment-GUCEW

## Overview
Assessing the overstatement of underemployment of workers with bachelor's degrees.

Use the "input/00_Setup.do" file to set the working directory, then run the .do file. All output in the current draft is in the "output/underemployment_analysis.xlsx" file, with additional graphs for alternative underemployment measures in the output folder as .png files. The underlying data can easily be sent to Excel by updating the code in the "code/" folder .do files starting with "D#_".

## Replication

In order to work with these files, create a local subfolder titled "IPUMS Data" in the same folder as the "college-underemployment-GUCEW" repository folder. This subfolder should contain an unzipped .dat file with the variables/observations defined in the "_documentation" subfolder of the repository. In the "code" subfolder, file "00_SETUP.do", change the name of the global variable "IPUMS" to match the name of the current .dat file.

Additionally, within the "college-underemployment-GUCEW" repository folder, add an empty "intermediate" subfolder; this will be populated with the intermediate datasets once the code is run.

>[!NOTE]
> For any additional clarification questions or issues, please email Matt Martinez.


