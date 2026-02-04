I had a first look at the evaluation report. Here is my feedback. Please implement the proposed changes which are given for each individual section below. 

# Forest Cover Development 
# Summary statistics: 

- table is currently given in longformat with one protected area appearing multiple times. Translate this table into wide where each year is one column and annual loss is given as the value.
- Before add a column that contains information whether an area was part of the project or not. Call this column "Project Area" and make the values yes/no dependend on whether they where part of the project (this is the areas that are analysed later in detail).
- Also show the WDPA ID as a column.
- Also show protected area size as a column. For this get the value from the WDPA data. There is a column called GIS_M_AREA. It reports the area in sqkm. Convert it to ha.
- Also show forest cover in 2000 as a column and create three columns that aggregate the losses for the periods 2009-2013, 2014-2018 and 2019-2023
- The final table should have columns in the order of "Protected Area Name", "WDPA ID", "Project Area", "Total Protected Area", "Forest Cover in 2000", "Cumulative Loss 2009-2013 (ha)", "Cumulative Loss 2014-2018 (ha)", "Cumulative Loss 2019-2023 (ha)", "Loss 2001 (ha)", "Loss 2022 (ha)", Loss 2003 (ha), etc. until Loss 2024 (ha).

## Overall Trends
- convert linechart forest-cover overview to a stacked barplot. the individual staks should be all protected areas in Laos that were analyzed in the report. make sure to use an appealing well distinguishable color scheme for the different areas.
- convert bar chart with total lossees to a stacked bar chart with total losses, again the individual areas comprising the stacks. make sure to use the same color scheme as before.


# Tempral Analysis of Deforestation for the Project Period
- create one graph called "Cumulative forest cover loss (2001-2024) for project PAs" from the three existing ones containg all project protected areas. Seperate the three distinct phases with dashed darkgrey vertical lines and create text labels for the phases in the plot.
- create a second graph. It should have the same setup as the graph before and be called "Cumulative forest cover loss (2001-2024) for all PAs". Again it should contain the data from the project PAs in the same colors as above as well as the data for all other PAs analyzed. Those should be grey lines so that the project PAs are clearly distinguishable. 
- create a third graph that shows forest cover per year in the project areas. It should be  a line-chart displaying total forest cover from 2000-2024. Call it "Forest cover (2001-2024) for project PAs". Use the same color scheme as above and again, seperate the project phases with dashed vertical lines.
- Create a fourth graph that shows forest cover per year in the all areas. Call it "Forest cover (2001-2024) for all PAs". Just as in the graph 2, use the same color scheme for the project PAs and make the other ones grey so that project PAs are clearly distinguishable.
## Interpretation of Trends
- remove this part.

# Descriptive Analysis
- remove this part

# Key Findings
- this part is currently very weak. Make sure to base your interpretation son the actual data. How did forest cover loss develop in the project areas? Was there a notable reduction during or after the period? If not how does this compare to the national trends of forest cover loss in protected areas.
- make sure to not hallucinate interpretations here and based them purely on a descriptive analysis of the processed data.

# Comparative context
- remove this section completly with all subsections

# conclusions and recommendations
- remove this section completly with all subsections

# Other remarks
- center all plots and make them take less space of the reporting panel. I think visually appealing would be around 70%.
- Keep consistency amongst graphs regarind color scheme and other visual elements used in ggplot.
- use ggplotly for all graphs. Guarantee that the plots are truely interactive.
- add a section called "Map" Between the sections "Analyzed Protected Areas" and "Forest Cover Development (2000-Present)". This map should be made in the exact same way as the map in "# Threat Assessment for Protected Areas in Bolivia" report. Check the Quarto document in this repo to see how it was produced. Of course it should contain the data from Lao and not Bolivia, so this part you should adapt. But Styling and additional layers should be exactly the same.
- Use a strong model to implement these changes. I was not pleased with your first approach. Use strong reasoning and programming skills to implement these changes. Plan your steps well and make sure you do not forget anyting.
- After you are finished, render the report and make sure to fix all eventuall errors as long as it takes so that the report renders correctly. 