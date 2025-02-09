//
//  ContentView.swift
//  CountryChatGPT
//
//  Created by Tatiana Kornilova on 31.01.2025.
//

// ChatGpt o3-mini Version 2
import Foundation

// MARK: - Models

// This struct is used to decode the top-level array.
// We ignore the first element (metadata) and then decode the second element as an array of Country.
struct CountryResponse: Codable {
    let countries: [Country]
    
    // Custom initializer to decode the top-level array.
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        // Decode (and ignore) the metadata.
        _ = try container.decode(Meta.self)
        // Now decode the countries array.
        countries = try container.decode([Country].self)
    }
}

// Metadata about the response (we don’t use it in this sample).
struct Meta: Codable {
    let page: Int
    let pages: Int
    let per_page: FlexibleInt  // now flexible
    let total: Int
}

// The Country model – note that we use the "id" field from the API as the unique identifier.
struct Country: Codable, Identifiable {
    // The API’s "id" is the country code.
    let id: String
    let iso2Code: String
    let name: String
    let region: Category
    let incomeLevel: Category
    let lendingType: Category
    let capitalCity: String
    let longitude: String
    let latitude: String
}

// A helper type for nested category fields (like region, incomeLevel, etc.)
struct Category: Codable {
    let id: String
    let value: String
}
//------
// MARK: - Indicator API Models

// Response to decode indicator data
struct IndicatorResponse: Codable {
    let data: [IndicatorData]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Meta.self)
        data = try container.decode([IndicatorData].self)
    }
}

struct IndicatorData: Codable {
    let indicator: Indicator?
    let country: IndicatorCountry?
    let countryiso3code: String?
    let date: String?
    let value: Double?
    let unit: String?
    let obs_status: String?
    let decimal: Int?
}

struct Indicator: Codable {
    let id: String?
    let value: String?
}

struct IndicatorCountry: Codable {
    let id: String?
    let value: String?
}

// A type that decodes either an Int or a String convertible to an Int.
struct FlexibleInt: Codable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let stringValue = try? container.decode(String.self),
                  let intValue = Int(stringValue) {
            self.value = intValue
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected Int or String convertible to Int"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Flag Emoji Extension

extension String {
    /// Converts a 2-letter country code into its corresponding flag emoji.
    var flagEmoji: String {
        self.uppercased().unicodeScalars.compactMap { scalar -> String? in
            guard let flagScalar = UnicodeScalar(127397 + scalar.value) else { return nil }
            return String(flagScalar)
        }.joined()
    }
}


import SwiftUI

@MainActor
class CountriesViewModel: ObservableObject {
    @Published var countries: [Country] = []
    // Group real countries by region.
    @Published var groupedCountries: [String: [Country]] = [:]
    
    // Indicator dictionaries: country id -> value
    @Published var populationData: [String: Int] = [:]
    @Published var gdpData: [String: Double] = [:]
    
    func loadCountries() async {
        do {
            // This network call runs off the background thread.
            let fetchedCountries = try await fetchCountriesInBackground()
            // Now update the UI on the main actor
            countries = fetchedCountries
            groupedCountries = Dictionary(grouping: fetchedCountries, by: { $0.region.value })
            
            // Fetch population and GDP concurrently.
            // This network call runs off the background thread.
            async let popResult = fetchPopulation()
            async let gdpResult = fetchGDP()
            let (pop, gdp) = try await (popResult, gdpResult)
            // Now update the UI on the main actor
            self.populationData = pop
            self.gdpData = gdp
            
        } catch {
            print("Error fetching countries: \(error)")
        }
    }
    
    nonisolated private func fetchCountriesInBackground() async throws -> [Country] {
        guard let url = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CountryResponse.self, from: data)
        // Filter out aggregates here if desired.
        return response.countries.filter { $0.region.value != "Aggregates" }
    }
    
    // Fetch population (indicator "SP.POP.TOTL") for year 2022.
    nonisolated private func fetchPopulation() async throws -> [String: Int] {
        guard let url = URL(string: "https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&per_page=500&date=2022") else { return [:]}
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(IndicatorResponse.self, from: data)
        var dict: [String: Int] = [:]
        for item in decoded.data {
            if let code = item.countryiso3code, let value = item.value {
                dict[code] = Int(value)
            }
        }
              return dict
    }
    
    // Fetch GDP (indicator "NY.GDP.MKTP.CD") for year 2022.
    nonisolated private func fetchGDP() async throws ->  [String: Double]{
        guard let url = URL(string: "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&per_page=500&date=2022") else { return   [:]}
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(IndicatorResponse.self, from: data)
        var dict: [String: Double] = [:]
        for item in decoded.data {
            if let code = item.countryiso3code, let value = item.value {
                dict[code] = value
            }
        }
        return dict
    }
}

struct ContentView: View {
    @StateObject var viewModel = CountriesViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.groupedCountries.keys.sorted(), id: \.self) { region in
                    Section(header: Text(region)) {
                        if let countries = viewModel.groupedCountries[region] {
                            ForEach(countries) { country in
                                NavigationLink(destination: CountryDetailView(country: country,
                                    population: viewModel.populationData[country.id],
                                    gdp: viewModel.gdpData[country.id])) {
                                    HStack {
                                        // Flag emoji from iso2Code
                                        Text(country.iso2Code.flagEmoji)
                                            .font(.largeTitle)
                                        VStack(alignment: .leading) {
                                            Text(country.name)
                                                .font(.headline)
                                            HStack {
                                                if let pop = viewModel.populationData[country.id] {
                                                    Text("Population: \(pop)")
                                                } else {
                                                    Text("Population: N/A")
                                                }
                                                Spacer()
                                                if let gdp = viewModel.gdpData[country.id] {
                                                    Text("GDP: \(gdp, specifier: "%.0f")")
                                                } else {
                                                    Text("GDP: N/A")
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("World Countries")
            .task {
                await viewModel.loadCountries()
            }
        }
    }
}

import MapKit
import CoreLocation

struct CountryDetailView: View {
    let country: Country
    let population: Int?
    let gdp: Double?
    
    // Use the new state property for the map's position.
        @State private var position: MapCameraPosition
    // Will hold the capital city coordinate after geocoding.
        @State private var capitalCoordinate: CLLocationCoordinate2D? = nil
   
    
    init(country: Country, population: Int?, gdp: Double?) {
        self.country = country
        self.population = population
        self.gdp = gdp
        
        // Convert latitude/longitude strings to Double.
        let lat = Double(country.latitude) ?? 0.0
        let lon = Double(country.longitude) ?? 0.0
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        // Initialize the MapPCameraPosition
                _position = State(initialValue:.region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
                )))
    }
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Text("Flag:")
                    Spacer()
                    Text(country.iso2Code.flagEmoji)
                        .font(.largeTitle)
                }
                HStack {
                    Text("Capital:")
                    Spacer()
                    Text(country.capitalCity)
                }
            }
            
            Section(header: Text("Map")) {
                // Display the map with a marker for the country.
              
                // Use the new iOS 17 Map initializer with a MapContentBuilder.
                Map (position: $position){
                    // For annotation, convert the coordinate strings to Double.
                    let lat = Double(country.latitude) ?? 0.0
                    let lon = Double(country.longitude) ?? 0.0
                   
                    // Marker for the country's center.
                   if country.capitalCity == "" {
                        Marker("\(country.name)",coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                    
                    // If the capital city's coordinate is available, add a marker.
                    
                   if let capitalCoordinate = capitalCoordinate {
                        Marker(coordinate: capitalCoordinate) {
                            // Use a Label to indicate the capital city.
                            Label("\(country.capitalCity)", systemImage: "building.columns")
                        }
                    }
                   
                    
              }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .task {
                    await geocodeCapital()
                    print (" \(country.capitalCity) \(capitalCoordinate ?? CLLocationCoordinate2D())")
                }
            }
            
            Section(header: Text("Indicators")) {
                HStack {
                    Text("Population:")
                    Spacer()
                    if let pop = population {
                        Text("\(pop)")
                    } else {
                        Text("N/A")
                    }
                }
                HStack {
                    Text("GDP (USD):")
                    Spacer()
                    if let gdp = gdp {
                        Text("\(gdp, specifier: "%.0f")")
                    } else {
                        Text("N/A")
                    }
                }
            }
        }
        .navigationTitle(country.name)
    }
    //---
    // Geocode the capital city name to obtain its coordinate.
   nonisolated  func geocodeCapital() async {
        
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(country.capitalCity)
                if let location = placemarks.first?.location {
                    await MainActor.run{
                        capitalCoordinate = location.coordinate
                    }
                    
                }
            } catch {
                print("Error geocoding capital city: \(error)")
            }
        }
    //----
 /*   func geocodeCapital() async {
        // Capture the capital city string so that the detached task doesn't capture self.
        let capitalCity = country.capitalCity
        
        let coordinate: CLLocationCoordinate2D? = await Task.detached { [capitalCity] in
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(capitalCity)
                return placemarks.first?.location?.coordinate
            } catch {
                print("Error geocoding capital city: \(error)")
                return nil
            }
        }.value

        if let coordinate = coordinate {
            await MainActor.run {
                self.capitalCoordinate = coordinate
            }
        }
    }*/
}

#Preview {
    ContentView()
}
