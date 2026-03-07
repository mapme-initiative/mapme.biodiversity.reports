# Task1 
## Context
I build up this repository organically. It's purpose is to be a collection of reproducible analysis reports that are produce in quarto and rendered as an html file to be published on Github pages. The reports contain analysis that is performed amongst others with the mapme.biodiversity package in R which uses open geospatial data to analyse conservation related datasets.

My goal for this project is to be able to quickly generate new reports for new use-caes using LLM agents to assist me in the coding process and publish them within the same quarto document and repository online. 

The current status is from my perspective: 
- two reports generated (Lao and Bolivia)
- An index and about page generated that introduce the project a bit better. 
- Missing: It seems to me that the repo is currently not 100% well structured if you think of this project in a more generalized way. The processing scripts, e.g. are in the to level folder. Input, Processing and Output data is not well seperated and also the data from the different use-cases is not sepearted in folders. 
- Missing: The Readme.md needs an update after all restructuring is finished
- Missing: There is no agents.md that orients coding agents on how to work in this repository. 
- Missing: a report for India

below you find more orientation on what you should do:
## Tasks
- Analyse the repo fully, think of a good structure and restructure, clean, organize, rename, wherever needed. Make sure to also adjust any scripts that references to these files so that they are still fully functional. 
- document the new organization and structure and eventual conventions in the readme.md and in an agents.md. Create an agents.md that is specific to the purpose of this repo and follows good examples for agents.md in data science. keep it lean and focussed though. 
- create a new report for India, more details below. 

## India report
You can find the input data for this task in /data/India. There are two geojson files. 
- one containing all villages in tripura state: tripura_villages_esri.geojson
- one containing only selected villages: tripura_vdpic_matched.geojson.  
- create a script to process the global forest watch data using the mapme biodiversity packages. Use the the fully available years 2001-2024. once you produced the output, we will continue with your task description. 
