The purpose of this new project is to update a data-analysis that was done with R. The data-analysis was done about 2 years ago and I downloaded the repo for you that contains the relevant code. You can find and scan the code in this folder: “~/Documents/cursor/mapme.protectedareas/”. You may not need to scan everything because it will crowd your context window but you should start with

-       "~/Documents/cursor/mapme.protectedareas/README.md"
-       "~/Documents/cursor/mapme.protectedareas/contributing.md"

To get a first impression how the repo is structured and about its multiple purposes. You will see that it has mulitple purposes of which only a couple is relevant here. 

You can then check the file “~/Documents/cursor/mapme.protectedareas/analysis/threat_assessment_bolivia.Rmd”.

It contains the relevant reporting code that I need to update. You will notice that in this script, several datasets are loaded for the analysis. I will provide you with newly updated data here or tell you how to generate it. 

The R object that is called "wdpa_kfw" is now located under "data/portfolio.gpkg". It contains all protected areas that are still or where formerly financed by KfW or GIZ. 

Next there is an R object created called "gfw_lossstats" loaded from a CSV. this file contains forest cover loss statistics from the global forest watch. It was generated with another script using the mapme.biodiversity package. You can find more information about this package here and about its basic usage here <https://github.com/mapme-initiative/mapme.biodiversity>. Read the readme.md from the repository to understand how it works. You should then create a separate R script from scratch called "processing.R" that generates the relevant input statistics. We do this outside of the Rmd script, because it can take a longer time to process. 

Here the update already starts. You should add data up until 2024 i.e. process forest cover loss data between 2000 and 2024. 

A more detailed documentation of the package is also available online under: https://mapme-initiative.github.io/mapme.biodiversity/ 

The same is true for fire data. later in the script there is an object loaded called bolivia_fire_data. This data was also generated with the afformentioned package which also allows to calculate fire indicators. Now there is one important change in the package. Formerly the package allowed to generated statistics on active fire counts using NASA FIRMS data. Now the package only allows to generate burned areas in ha based on MODIS data. So you would also need to update the analysis code in the markdown file to account for this and measure area instead of incidences. 

 You will also need another geospatial datafile that contains all protected areas. It is used in the script to create an object called wdpa_allPAs. You can find the relevant data in "data/wdpa.gdb". Its a file geodatabase, that you can load as a spatial layer in R as well. 

 Now here are your main tasks for the project
 - regenerate and update the relevant input data for the period 2000-2024. Do this in a sepearte R script. process the data and eventually fix errors. 
 - regenerate the rmd file for reporting purposes. Note that you should adapt the text in the markdown according to the new study period, utilized methods and data and also according to the results you detected. 
 - You should check before, whether we still want to use the old RMD system or whether it is possible to change to the more modern Quarto format from RStudio.
 - check whether it still makes sense to use workflowR to generate the website or whether it is easier to use Quarto for this purpose. Remember that I use Github pages the free version. I want to make this a scalable project i.e. to put new analysis scripts and reports into the website.
 - generate the html websites for from the RMD or Quarto files so I can check the results. 

 Make sure to install and or update also all relevant R packages. Also make sure to generate sufficient documentation in a Readme file of this repo. 
