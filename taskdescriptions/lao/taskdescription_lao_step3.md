# Data Processing
- There seems to be no data processed for the other protected areas in Lao. There is a note at the end of the report saying "_Note: A comprehensive comparison with national trends would require processing forest cover data for all Lao protected areas. The current analysis focuses on the four project areas, providing a foundation for future comparative analysis." Check the processing script, adapt it if true. Currently the comparision areas are not shown in all tables and plots where i would like to have them. Execute the script. before then adapting the report. 

# Report
## Map
- make the map only have of the vertical size. make it horizontally 100%. It seems to be currently only 70% or 80%.
- Check if you can add a transparency slider for the maplayers from the leaflet library or leaflet.extras library or any leaflet related library. research wheather layer transparency sliders are possible.
- Change the two embedded layers "Forest Cover Loss (2001-2014)" and "Forest Cover Loss (2014-2024)". I want them to show the periods that we also use below for the analysis. Those are 2009-2013, 2014-2018, 2019-2023. Look at the pattterns in the URLs. They contain startyear and stopyear or similar tags. Adjust those with the years and create three layers for those periods. In addition create another layer that shows the period 2001-2024.
- Add another layer called "Project PAs (Outlines)". It should contain the same data as "Project PAs" but it should be styled differently. Use only the polygon outline in Red and make the fill completly transparent.

## Line Charts and Barcharts
- not all charts currently contain the vertical lines with the project periods. Add them to all plots.
- only two vertical lines are shown for the years 2014 and 2019. make sure to add also lines for 2009 and 2023 for all plots.
- make the lines slightly thinner and more elegant.
- Make all plots but the overall Trends plot only have of the verical size. 

## Interpretations
- Once the data is processed for the whole country rework your interpretations and take into account the comparative perspective. 