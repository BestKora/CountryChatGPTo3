## iOS apps Countries created by ChatGPT 4.o3-mini

 A simple iOS application Countries, which shows all the countries of the World by region (Europe, Asia, Latin America, etc.) 
 and for each country its name and flag. 
 
 If you select a country, then additional information about the population 
 and the size of GDP (gross domestic product) gdp and the country's location on the World map is reported.
 We used World Bank data, but we did not tell the AI ​​either the sites or the data structures, 
 the AI ​​should find all this itself and use them when creating an iOS application.
 
 ![til](https://github.com/BestKora/CountryChatGPTo3/blob/285aa2b9c83668acf453f46f36f1e36f1fa3c590/ChatGPTO3.gif)

## Technologies used by ChatGPT o3-mini:

* MVVM design pattern 
* SwiftUI
* async / await
* Swift 6 strict concurrency using @MainActor and marking selection functions as nonisolated or using Task.detached.
*  API with Map (position: $position) and Maker
*  CLGeocoder() to get more accurate geographic coordinates of the country's capital and Task.detached to run in the background.
  
## Results of using ChatGPT o3-mini:

* Coped with decoding JSON data without any problems
* Used a modern async / await system for working with multithreading.
Suggested several options for switching to Swift 6 strict concurrency using @MainActor and marking selection functions as nonisolated or using Task.detached.
* At first, I suggested the old Map API with Map (coordinateRegion: $region, annotationItems: [country]) and MapMaker, but after receiving the corresponding warnings, I switched to the new API with Map (position: $position) and Maker.
* Used CLGeocoder() to get more accurate geographic coordinates of the country's capital and Task.detached to run in the background.
* The reasoning is short, to the point and lasts from 1 to 25 seconds, the average time is 8 seconds.
* I can recommend it as a good training material for iOS developers.
