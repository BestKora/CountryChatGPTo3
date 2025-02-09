//
//  Archiv.swift
//  CountryChatGPT
//
//  Created by Tatiana Kornilova on 08.02.2025.
//

/*
import SwiftUI


// handling error version DeepSeek working
 
struct ContentView: View {
    @StateObject private var viewModel = CountryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.loadingState {
                case .loading:
                    ProgressView("Loading countries...")
                case .loaded:
                    List {
                        ForEach(viewModel.groupedCountries.keys.sorted(), id: \.self) { region in
                            Section(header: Text(region).foregroundStyle(Color.gray).bold().font(.title3)) {
                                ForEach(viewModel.groupedCountries[region] ?? []) { country in
                                    CountryRow(country: country)
                                }
                            }
                        }
                    }
                case .error(let message):
                    Text(message)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("World Countries")
        }
        .task {
            await viewModel.fetchAllData()
        }
    }
}

struct CountryRow: View {
    let country: Country
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack {
                Text(country.flag)
                    .font(.system(size: 65))
                Text(country.name)
                    .font(.title2)
                Text(country.iso2Code)
                    .monospaced()
            }
              
                    Label(country.capitalCity, systemImage: "building.2")
                        .font(.title3)
               
                
                HStack(spacing: 0) {
                    if let population = country.population {
                        Label(population.formatted() + " people", systemImage: "person.2")
                    }
                    if let gdp = country.gdp {
                        Label("$" + Int(gdp).formatted(), systemImage: "dollarsign.circle")
                    }
                }
                .font(.callout)
        }
    }
}

struct Country: Decodable, Identifiable {
    let id: String
    let iso2Code: String
    let name: String
    let capitalCity: String
    let region: Region
    var population: Int?
    var gdp: Double?
    
    var flag: String {
        iso2Code.unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
    
    struct Region: Decodable {
        let id: String
        let value: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, region
        case iso2Code = "iso2Code"
        case capitalCity = "capitalCity"
    }
}

class CountryViewModel: ObservableObject {
    enum LoadingState {
        case loading, loaded, error(String)
    }
    
    @Published var loadingState: LoadingState = .loading
    @Published var groupedCountries: [String: [Country]] = [:]
    
    private let countryURL = "https://api.worldbank.org/v2/country?format=json&per_page=300"
    private let populationURL = "https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&date=2022&per_page=300"
    
    private let gdpURL = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&date=2022&per_page=300"
    
  /*  func fetchAllData() async {
        do {
            async let countries = fetchCountries()
            async let populationData = fetchIndicatorData(url: populationURL)
            async let gdpData = fetchIndicatorData(url: gdpURL)
            
            var finalCountries = try await countries
            let populationDict = try await populationData
            let gdpDict = try await gdpData
            
            // Merge economic data
            finalCountries = finalCountries.map { country in
                var modified = country
                modified.population = Int(populationDict[country.iso2Code] ?? 0)
                modified.gdp = gdpDict[country.iso2Code]
                return modified
            }
            
            let filtered = finalCountries.filter {
                !$0.region.value.lowercased().contains("aggregate") &&
                $0.region.id != "NA" &&
                $0.capitalCity != ""
            }
            
            let grouped = Dictionary(grouping: filtered) {
                $0.region.value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            await MainActor.run {
                groupedCountries = grouped
                loadingState = .loaded
            }
        } catch {
            await MainActor.run {
                loadingState = .error("Failed to load data: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchCountries() async throws -> [Country] {
        struct WorldBankResponse: Decodable {
            let countries: [Country]
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                _ = try container.decode(CountryResponseMetadata.self)
                countries = try container.decode([Country].self)
            }
        }
        
        let (data, _) = try await URLSession.shared.data(from: URL(string: countryURL)!)
        return try JSONDecoder().decode(WorldBankResponse.self, from: data).countries
    }
    
    private func fetchIndicatorData(url: String) async throws -> [String: Double] {
        
        struct IndicatorResponse: Decodable {
            let entries: [Entry]
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                _ = try container.decode(IndicatorResponseMetadata.self)
                entries = try container.decode([Entry].self)
            }
            
            struct Entry: Decodable {
                let country: CountryInd
                let value: Double?
                
                struct CountryInd: Decodable {
                    let id: String  // This is the ISO2 code
                }
            }
        }
       
        do {
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
        let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
        
        let dictionary: [String: Double] = response.entries.reduce(into: [:]) { dict, entry in
            guard let value = entry.value else { return }
            dict[entry.country.id] = value
        }
        
        return dictionary
        } catch {
            print("Error in Indicator fetching: \(error)")
            return [:]
        }
    }*/
    func fetchAllData() async {
        do {
            async let countries = try fetchCountries()
            async let populationData = try fetchIndicatorData(url: populationURL)
            async let gdpData = try fetchIndicatorData(url: gdpURL)
            
            let (finalCountries, populationDict, gdpDict) = try await (countries, populationData, gdpData)
            
            let mergedCountries = mergeData(
                countries: finalCountries,
                population: populationDict,
                gdp: gdpDict
            )
            
            await MainActor.run {
                groupedCountries = mergedCountries//groupedCountries
                loadingState = .loaded
            }
        } catch {
            await handleError(error)
        }
    }
    
    private func fetchCountries() async throws -> [Country] {
        do {
            guard let url = URL(string: countryURL) else {
                throw APIError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            return try decodeCountries(from: data)
        } catch {
            throw handleFetchError(error, context: "countries")
        }
    }
    
    private func fetchIndicatorData(url: String) async throws -> [String: Double] {
        do {
            guard let url = URL(string: url) else {
                throw APIError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            return try decodeIndicatorData(from: data)
        } catch {
            throw handleFetchError(error, context: "indicator data")
        }
    }
    // MARK: - Decoding Helpers
       private func decodeCountries(from data: Data) throws -> [Country] {
           do {
               struct WorldBankResponse: Decodable {
                   let countries: [Country]
                   
                   init(from decoder: Decoder) throws {
                       var container = try decoder.unkeyedContainer()
                       _ = try container.decode(CountryResponseMetadata.self)
                       countries = try container.decode([Country].self)
                   }
               }
               return try JSONDecoder().decode(WorldBankResponse.self, from: data).countries
           } catch {
               throw APIError.decodingFailed(
                   message: "Countries decoding failed: \(error.localizedDescription)"
               )
           }
       }
    private func decodeIndicatorData(from data: Data) throws -> [String: Double] {
        do {
            struct IndicatorResponse: Decodable {
                let entries: [Entry]
                
                init(from decoder: Decoder) throws {
                    var container = try decoder.unkeyedContainer()
                    _ = try container.decode(IndicatorResponseMetadata.self)
                    entries = try container.decode([Entry].self)
                }
                
                struct Entry: Decodable {
                    let country: CountryEntry
                    let value: Double?
                    
                    struct CountryEntry: Decodable {
                        let id: String
                    }
                }
            }
            
            let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
            return response.entries.reduce(into: [:]) { dict, entry in
                guard let value = entry.value else { return }
                dict[entry.country.id] = value
            }
        } catch {
            throw APIError.decodingFailed(
                message: "Indicator data decoding failed: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) async {
        let message: String
        switch error {
        case let apiError as APIError:
            message = apiError.localizedDescription
        case let urlError as URLError:
            message = handleUrlError(urlError)
        default:
            message = "Unknown error: \(error.localizedDescription)"
        }
        
        await MainActor.run {
            loadingState = .error(message)
        }
    }
    
    private func handleUrlError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network settings."
        case .timedOut:
            return "Request timed out. Please try again later."
        case .networkConnectionLost:
            return "Network connection lost. Please check your connection."
        default:
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    private func handleFetchError(_ error: Error, context: String) -> Error {
        print("Error fetching \(context): \(error)")
        if let apiError = error as? APIError {
            return apiError
        }
        return APIError.requestFailed(
            message: "Failed to fetch \(context): \(error.localizedDescription)"
        )
    }
    
    // MARK: - Data Processing
    private func mergeData(
        countries: [Country],
        population: [String: Double],
        gdp: [String: Double]
    ) -> [String: [Country]] {
        let filtered = countries
            .map { country in
                var modified = country
                modified.population = population[country.iso2Code].flatMap(Int.init)
                modified.gdp = gdp[country.iso2Code]
                return modified
            }
            .filter {
                !$0.region.value.lowercased().contains("aggregate") &&
                $0.region.id != "NA" &&
                !$0.capitalCity.isEmpty
            }
        
        return Dictionary(grouping: filtered) {
            $0.region.value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(message: String)
    case requestFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .invalidResponse:
            return "Received invalid response from server"
        case .decodingFailed(let message):
            return "Data parsing failed: \(message)"
        case .requestFailed(let message):
            return "Network request failed: \(message)"
        }
    }
}

// Separate metadata structures for different endpoints
struct CountryResponseMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: String // String in country endpoint
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
    }
}

struct IndicatorResponseMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int     // Indicator endpoint uses Int
    let total: Int
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
        case lastUpdated = "lastupdated"
    }
}

#Preview {
    ContentView()
}
*/
/*
// Swift 6 concurrency Version DeepSeek working
import SwiftUI

// MARK: - Main View
@MainActor
struct CountryListView: View {
    @StateObject private var viewModel = CountryViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .loading:
                    ProgressView("Loading countries...")
                case .loaded:
                    List {
                        ForEach(viewModel.sortedRegions, id: \.self) { region in
                            Section(header: Text(region)) {
                                ForEach(viewModel.countries(in: region)) { country in
                                    CountryRow(country: country)
                                }
                            }
                        }
                    }
                case .error(let message):
                    ContentUnavailableView("Loading Failed", systemImage: "globe", description: Text(message))
                }
            }
            .navigationTitle("World Countries")
            .refreshable { await viewModel.load() }
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - View Components
struct CountryRow: View {
    let country: Country
    
    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(country.name)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Label(country.capitalCity, systemImage: "building.2")
                    Text(country.iso2Code)
                        .monospaced()
                }
                .font(.caption)
                
                HStack(spacing: 16) {
                    if let population = country.population {
                        Label(population.formatted() + " people", systemImage: "person.2")
                    }
                    if let gdp = country.gdp {
                        Label(gdp.formatted(.currency(code: "USD")), systemImage: "dollarsign.circle")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - ViewModel
//@Observable
@MainActor
final class CountryViewModel: ObservableObject {
    enum LoadingState {
        case loading, loaded, error(String)
    }
    
    @Published private(set) var loadingState: LoadingState = .loaded
    @Published  var countriesByRegion: [String: [Country]] = [:]
    
    private let service = WorldBankService()
    
    var sortedRegions: [String] {
        countriesByRegion.keys.sorted()
    }
    
    func countries(in region: String) -> [Country] {
        countriesByRegion[region] ?? []
    }
    
    func load() async {
        loadingState = .loading
        do {
            try await service.fetchAllData()
            countriesByRegion = await service.groupedCountries
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
}

// MARK: - Service Layer
actor WorldBankService {
    private(set) var groupedCountries: [String: [Country]] = [:]
    
    private let countryURL = "https://api.worldbank.org/v2/country?format=json&per_page=300"
    private let populationURL = "https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&date=2022&per_page=300"
    private let gdpURL = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&date=2022&per_page=300"
    
    func fetchAllData() async throws {
        async let countries = fetchCountries()
        async let populationData = fetchIndicatorData(url: populationURL)
        async let gdpData = fetchIndicatorData(url: gdpURL)
        
        let (baseCountries, population, gdp) = try await (countries, populationData, gdpData)
        
        let merged = merge(
            countries: baseCountries,
            population: population,
            gdp: gdp
        )
        
        groupedCountries = groupCountries(merged)
    }
    
    private nonisolated func fetchCountries() async throws -> [Country] {
        let (data, _) = try await fetchResource(from: countryURL)
        return try decodeCountries(from: data)
    }
    
    private nonisolated func fetchIndicatorData(url: String) async throws -> [String: Double] {
        let (data, _) = try await fetchResource(from: url)
        return try decodeIndicatorData(from: data)
    }
    
    private nonisolated func fetchResource(from urlString: String) async throws -> (Data, URLResponse) {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        return try await URLSession.shared.data(from: url)
    }
    
    // MARK: - Data Processing
    private func merge(
        countries: [Country],
        population: [String: Double],
        gdp: [String: Double]
    ) -> [Country] {
        countries
            .map { country in
                var modified = country
                modified.population = population[country.iso2Code].flatMap(Int.init)
                modified.gdp = gdp[country.iso2Code]
                return modified
            }
            .filter {
                !$0.region.value.lowercased().contains("aggregate") &&
                $0.region.id != "NA" &&
                !$0.capitalCity.isEmpty
            }
    }
    
    private func groupCountries(_ countries: [Country]) -> [String: [Country]] {
        Dictionary(grouping: countries) {
            $0.region.value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // MARK: - Decoding
    private nonisolated func decodeCountries(from data: Data) throws -> [Country] {
        struct WorldBankResponse: Decodable {
            let countries: [Country]
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                _ = try container.decode(CountryResponseMetadata.self)
                countries = try container.decode([Country].self)
            }
        }
        let countriesIn = try JSONDecoder().decode(WorldBankResponse.self, from: data).countries
        return countriesIn //try JSONDecoder().decode(WorldBankResponse.self, from: data).countries
    }
    
    private nonisolated func decodeIndicatorData(from data: Data) throws -> [String: Double] {
        struct IndicatorResponse: Decodable {
            let entries: [Entry]
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                _ = try container.decode(IndicatorResponseMetadata.self)
                entries = try container.decode([Entry].self)
            }
            
            struct Entry: Decodable {
                let country: CountryEntry
                let value: Double?
                
                struct CountryEntry: Decodable {
                    let id: String
                }
            }
        }
        
        let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
        return response.entries.reduce(into: [:]) { dict, entry in
            guard let value = entry.value else { return }
            dict[entry.country.id] = value
        }
    }
}

// MARK: - Models & Error Handling
struct Country: Decodable, Identifiable, Sendable {
    let id: String
    let iso2Code: String
    let name: String
    let capitalCity: String
    let region: Region
    var population: Int?
    var gdp: Double?
    
    var flag: String {
        iso2Code.unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
    
    struct Region: Decodable, Sendable {
        let id: String
        let value: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, region
        case iso2Code = "iso2Code"
        case capitalCity = "capitalCity"
    }
}

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case decodingFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid API endpoint URL"
        case .invalidResponse: "Received invalid response from server"
        case .decodingFailed(let message): "Data parsing failed: \(message)"
        }
    }
}

struct CountryResponseMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: String
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
    }
}

struct IndicatorResponseMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
    }
}

#Preview {
    CountryListView()
}
*/
/*
// ChatGPT version 0
import SwiftUI

struct Region: Decodable {
    let id: String
    let value: String
}

struct IncomeLevel: Decodable {
    let id: String
    let value: String
}

struct Country: Identifiable, Decodable {
    let id: String
    let name: String
    let region: Region
    let incomeLevel: IncomeLevel
    let capitalCity: String
    let latitude: String
    let longitude: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case region
        case incomeLevel
        case capitalCity
        case latitude
        case longitude
    }
}

struct DecodableMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: String
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "per_page"
        case total
    }
}

struct WorldBankResponse: Decodable {
    let metadata: DecodableMetadata
    let countries: [Country]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        metadata = try container.decode(DecodableMetadata.self)
        countries = try container.decode([Country].self)
    }
}

@MainActor
class CountriesViewModel: ObservableObject {
    @Published private(set) var countries: [Country] = []
    
    func fetchCountries() async {
        guard let url = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(WorldBankResponse.self, from: data)
            await MainActor.run {
                self.countries = decodedResponse.countries.filter { $0.region.value != "Aggregates" }
            }
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
        }
    }
    
    var groupedCountries: [String: [Country]] {
        Dictionary(grouping: countries, by: { $0.region.value })
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CountriesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groupedCountries.keys.sorted(), id: \ .self) { region in
                    Section(header: Text(region).font(.headline)) {
                        ForEach(viewModel.groupedCountries[region] ?? []) { country in
                            VStack(alignment: .leading) {
                                Text(country.name).font(.headline)
                                Text("Income Level: \(country.incomeLevel.value)").font(.subheadline)
                                Text("Capital: \(country.capitalCity)").font(.subheadline)
                                Text("Coordinates: \(country.latitude), \(country.longitude)").font(.subheadline)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("World Countries")
            .task {
                await viewModel.fetchCountries()
            }
        }
    }
}
*/

/*
// ChatGPT Swift 6 concurrency version 1 Slow
import SwiftUI

// MARK: - Models

struct Region: Decodable {
    let id: String
    let value: String
}

struct IncomeLevel: Decodable {
    let id: String
    let value: String
}

struct Country: Identifiable, Decodable {
    let id: String
    let name: String
    let region: Region
    let incomeLevel: IncomeLevel
    let capitalCity: String
    let latitude: String
    let longitude: String
    // New properties for additional data.
    var population: Int? = nil
    var gdp: Double? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, name, region, incomeLevel, capitalCity, latitude, longitude
    }
}

/// Metadata for the country endpoint (per_page is a String)
struct CountryMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: String
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "per_page"
        case total
    }
}

/// Metadata for the indicator endpoints (per_page is an Int)
struct IndicatorMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "per_page"
        case total
    }
}

/// The country list response from World Bank API.
/// The response is an array where the first element is metadata and the second is an array of Country objects.
struct WorldBankResponse: Decodable {
    let metadata: CountryMetadata
    let countries: [Country]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        metadata = try container.decode(CountryMetadata.self)
        countries = try container.decode([Country].self)
    }
}

/// Model for an indicator entry. We extract only the “value” field.
struct IndicatorEntry: Decodable {
    let value: Double?
    
    enum CodingKeys: String, CodingKey {
        case value
    }
}

/// Response for an indicator endpoint (for population or GDP).
/// The response is an array where the first element is metadata and the second is an array of IndicatorEntry objects.
struct IndicatorResponse: Decodable {
    let metadata: IndicatorMetadata
    let data: [IndicatorEntry]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        metadata = try container.decode(IndicatorMetadata.self)
        data = try container.decode([IndicatorEntry].self)
    }
}

// MARK: - ViewModel
@MainActor
class CountriesViewModel: ObservableObject {
    @Published private(set) var countries: [Country] = []
    
    /// Fetch the list of countries, then concurrently fetch population and GDP for each.
     func  fetchCountries() async {
        guard let url = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else { return }
        
        do {
            // Network call runs on a background thread.
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(WorldBankResponse.self, from: data)
            // Filter out "Aggregates"
            var updatedCountries = decodedResponse.countries.filter { $0.region.value != "Aggregates" }
            
            // Fetch additional data concurrently for each country.
            await withTaskGroup(of: (Int, Int?, Double?).self) { group in
                for (index, country) in updatedCountries.enumerated() {
                    group.addTask { [country] in
                        let population = await self.fetchPopulation(for: country.id)
                        let gdp = await self.fetchGDP(for: country.id)
                        return (index, population, gdp)
                    }
                }
                
                for await (index, population, gdp) in group {
                    updatedCountries[index].population = population
                    updatedCountries[index].gdp = gdp
                }
            }
            
            // UI updates on main thread.
            await MainActor.run {
                self.countries = updatedCountries
           }
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
        }
    }
    
    /// Fetch the latest population for a given country using its country code.
    private nonisolated func fetchPopulation(for countryId: String) async -> Int? {
        guard let url = URL(string: "https://api.worldbank.org/v2/country/\(countryId)/indicator/SP.POP.TOTL?format=json&per_page=1") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
            if let value = response.data.first?.value {
                return Int(value)
            }
        } catch {
            print("Error fetching population for \(countryId): \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Fetch the latest GDP for a given country using its country code.
    private nonisolated func fetchGDP(for countryId: String) async -> Double? {
        guard let url = URL(string: "https://api.worldbank.org/v2/country/\(countryId)/indicator/NY.GDP.MKTP.CD?format=json&per_page=1") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
            return response.data.first?.value
        } catch {
            print("Error fetching GDP for \(countryId): \(error.localizedDescription)")
        }
        return nil
    }
    
    var groupedCountries: [String: [Country]] {
        Dictionary(grouping: countries, by: { $0.region.value })
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var viewModel = CountriesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groupedCountries.keys.sorted(), id: \.self) { region in
                    Section(header: Text(region).font(.headline)) {
                        ForEach(viewModel.groupedCountries[region] ?? []) { country in
                            VStack(alignment: .leading) {
                                Text(country.name)
                                    .font(.headline)
                                Text("Income Level: \(country.incomeLevel.value)")
                                    .font(.subheadline)
                                Text("Capital: \(country.capitalCity)")
                                    .font(.subheadline)
                                Text("Coordinates: \(country.latitude), \(country.longitude)")
                                    .font(.subheadline)
                                Text("Population: \(country.population ?? 0)")
                                    .font(.subheadline)
                                Text("GDP: \(country.gdp ?? 0)")
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("World Countries")
            .task {
                await viewModel.fetchCountries()
            }
        }
    }
}
*/

/*
// ChatGPT flag population gdp
import SwiftUI

// MARK: - Models

struct Region: Decodable {
    let id: String
    let value: String
}

struct IncomeLevel: Decodable {
    let id: String
    let value: String
}

struct Country: Identifiable, Decodable {
    let id: String
    let iso2Code: String      // New: ISO2 code for the country
    let name: String
    let region: Region
    let incomeLevel: IncomeLevel
    let capitalCity: String
    let latitude: String
    let longitude: String
    // New properties for additional data.
    var population: Int? = nil
    var gdp: Double? = nil
    
    // Computed property to return the flag emoji based on the ISO2 code.
    var flag: String {
        return iso2Code.flagEmoji
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, region, incomeLevel, capitalCity, latitude, longitude, iso2Code
    }
}

/// Extension to convert an ISO country code into a flag emoji.
extension String {
    var flagEmoji: String {
        let base: UInt32 = 127397
        var scalarView = String.UnicodeScalarView()
        for scalar in self.uppercased().unicodeScalars {
            if let scalarFlag = UnicodeScalar(base + scalar.value) {
                scalarView.append(scalarFlag)
            }
        }
        return String(scalarView)
    }
}
/// Metadata for the country endpoint (per_page is a String)
struct CountryMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: String
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
    }
}

/// Metadata for the indicator endpoints (per_page is an Int)
struct IndicatorMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
    }
}

/// The country list response from World Bank API.
struct WorldBankResponse: Decodable {
    let metadata: CountryMetadata
    let countries: [Country]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        metadata = try container.decode(CountryMetadata.self)
        countries = try container.decode([Country].self)
    }
}

/// Model for an indicator entry. We extract the “value” field and also decode a country reference.
struct IndicatorEntry: Decodable {
    let country: CountryReference
    let value: Double?
    
    /// A helper model for country reference in the indicator response.
    struct CountryReference: Decodable {
        let id: String // This is the ISO2 code
    }
    
}
/// Response for an indicator endpoint (for population or GDP).
struct IndicatorResponse: Decodable {
    let metadata: IndicatorMetadata
    let data: [IndicatorEntry]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        metadata = try container.decode(IndicatorMetadata.self)
        data = try container.decode([IndicatorEntry].self)
    }
}

// MARK: - ViewModel

@MainActor
class CountriesViewModel: ObservableObject {
    @Published private(set) var countries: [Country] = []
    
    /// Entry point for fetching countries. This function runs on the main actor.
    func fetchCountries() async {
        // Call a helper that runs off the main actor.
        let updatedCountries = await fetchCountriesFromNetwork()
        // Now update the UI on the main actor.
        self.countries = updatedCountries
    }
    
    /// Perform the network fetching on a background thread using a detached task.
    private func fetchCountriesFromNetwork() async -> [Country] {
        guard let countriesURL = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else {
            return []
        }
        
        do {
            // Perform the country request (this runs on a background thread)
            let (countriesData, _) = try await URLSession.shared.data(from: countriesURL)
            let decodedResponse = try JSONDecoder().decode(WorldBankResponse.self, from: countriesData)
            var updatedCountries = decodedResponse.countries.filter { $0.region.value != "Aggregates" }
            
            // Fetch bulk indicator data concurrently for population and GDP.
            async let populationResponse = fetchIndicator(for: "SP.POP.TOTL", perPage: 300)
            async let gdpResponse = fetchIndicator(for: "NY.GDP.MKTP.CD", perPage: 300)
            
            let (popResponse, gdpResponseResult) = try await (populationResponse, gdpResponse)
            
            // Create lookups keyed by country id.
            let populationLookup = Dictionary(uniqueKeysWithValues: popResponse.data.compactMap { entry in
                            if let value = entry.value { return (entry.country.id, Int(value)) }
                            return nil
                        })
    
            let gdpLookup = Dictionary(uniqueKeysWithValues: gdpResponseResult.data.compactMap { entry in
                            if let value = entry.value { return (entry.country.id, value) }
                            return nil
                        })
            
            // Merge the fetched indicator data into the country objects.
            
            updatedCountries = updatedCountries.map { country in
                var mutableCountry = country
                mutableCountry.population = populationLookup[country.iso2Code]
                mutableCountry.gdp = gdpLookup[country.iso2Code]
                return mutableCountry
            }
            
            return updatedCountries
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Helper function to fetch an indicator response for all countries.
    private func fetchIndicator(for indicator: String, perPage: Int) async throws -> IndicatorResponse {
        // Using "all" fetches data for all countries.
       
        guard let url = URL(string: "https://api.worldbank.org/v2/country/all/indicator/\(indicator)?format=json&date=2022&per_page=\(perPage)") else {
            throw URLError(.badURL)
        }
       print (url)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
        return response //try JSONDecoder().decode(IndicatorResponse.self, from: data)
        
    }
    
    var groupedCountries: [String: [Country]] {
        Dictionary(grouping: countries, by: { $0.region.value })
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var viewModel = CountriesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groupedCountries.keys.sorted(), id: \.self) { region in
                    Section(header: Text(region).font(.headline)) {
                        ForEach(viewModel.groupedCountries[region] ?? []) { country in
                            VStack(alignment: .leading) {
                                Text(country.name)
                                    .font(.headline)
                                Text("Income Level: \(country.incomeLevel.value)")
                                    .font(.subheadline)
                                Text("Capital: \(country.capitalCity)")
                                    .font(.subheadline)
                                Text("Coordinates: \(country.latitude), \(country.longitude)")
                                    .font(.subheadline)
                                Text("Population: \(country.population ?? 0)")
                                    .font(.subheadline)
                                Text("GDP: \(country.gdp ?? 0)")
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("World Countries")
            .task {
                await viewModel.fetchCountries()
            }
        }
    }
}

#Preview {
    ContentView()
}
*/
/*
// ChatGPT o3-mini  resoning and search version 1
import Foundation

// MARK: - Models

struct CountryResponse: Codable {
    let countries: [Country]
    
    // Custom initializer to decode the top-level array.
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        // Decode and ignore metadata.
        _ = try container.decode(Meta.self)
        // Decode the countries array.
        countries = try container.decode([Country].self)
    }
}

struct Meta: Codable {
    let page: Int
    let pages: Int
    let per_page: String
    let total: Int
}

struct Country: Codable, Identifiable {
    let id: String            // This is the country code.
    let iso2Code: String
    let name: String
    let region: Category
    let incomeLevel: Category
    let lendingType: Category
    let capitalCity: String
    let longitude: String
    let latitude: String
}

struct Category: Codable {
    let id: String
    let value: String
}

import Foundation
import SwiftUI

class CountriesViewModel: ObservableObject {
    @Published var countries: [Country] = []
    // Group real countries by region.
    @Published var groupedCountries: [String: [Country]] = [:]
    
    @MainActor
    func fetchCountries() async {
        // Use a per_page parameter high enough to include most countries.
        guard let url = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else {
            print("Invalid URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CountryResponse.self, from: data)
            
            // Filter out aggregates – only include countries whose region value is not "Aggregates"
            let realCountries = response.countries.filter { $0.region.value != "Aggregates" }
            self.countries = realCountries
            
            // Group the filtered countries by region.
            groupedCountries = Dictionary(grouping: realCountries, by: { $0.region.value })
        } catch {
            print("Error fetching countries: \(error)")
        }
    }
}


import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = CountriesViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Sort region names alphabetically.
                ForEach(viewModel.groupedCountries.keys.sorted(), id: \.self) { region in
                    Section(header: Text(region)) {
                        if let countriesInRegion = viewModel.groupedCountries[region] {
                            ForEach(countriesInRegion) { country in
                                NavigationLink(destination: CountryDetailView(country: country)) {
                                    Text(country.name)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("World Countries")
            .task {
                await viewModel.fetchCountries()
            }
        }
    }
}

struct CountryDetailView: View {
    let country: Country
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Text("Capital:")
                    Spacer()
                    Text(country.capitalCity)
                }
                HStack {
                    Text("Region:")
                    Spacer()
                    Text(country.region.value)
                }
                HStack {
                    Text("Income Level:")
                    Spacer()
                    Text(country.incomeLevel.value)
                }
                HStack {
                    Text("ISO Code:")
                    Spacer()
                    Text(country.iso2Code)
                }
            }
            
            Section(header: Text("Location")) {
                HStack {
                    Text("Latitude:")
                    Spacer()
                    Text(country.latitude)
                }
                HStack {
                    Text("Longitude:")
                    Spacer()
                    Text(country.longitude)
                }
            }
        }
        .navigationTitle(country.name)
    }
}
*/

/*
// ChatGPT o3-mini  resoning and search version 2 population, gdp and flag map

import Foundation

// MARK: - Models

import Foundation

// MARK: - Country API Models

struct CountryResponse: Codable {
    let countries: [Country]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        // Decode (and ignore) the metadata.
        _ = try container.decode(Meta.self)
        countries = try container.decode([Country].self)
    }
}

struct Country: Codable, Identifiable {
    let id: String            // Three-letter country code.
    let iso2Code: String      // Two-letter country code.
    let name: String
    let region: Category
    let incomeLevel: Category
    let lendingType: Category
    let capitalCity: String
    let longitude: String
    let latitude: String
}

struct Category: Codable {
    let id: String
    let value: String
}

// MARK: - Indicator API Models

// MARK: - Population Models (non‑generic)

struct PopulationIndicatorResponse: Codable {
    let indicator: Indicator?
    let country: IndicatorCountry?
    let countryiso3code: String?
    let date: String?
    // Decode as Double to allow decimal values (then convert to Int as needed)
    let value: Double?
    let unit: String?
    let obs_status: String?
    let decimal: Int?
}

struct PopulationDataResponse: Codable {
    let data: [PopulationIndicatorResponse]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Meta.self)
        data = try container.decode([PopulationIndicatorResponse].self)
    }
}

// MARK: - GDP Models (non‑generic)

struct GDPIndicatorResponse: Codable {
    let indicator: Indicator?
    let country: IndicatorCountry?
    let countryiso3code: String?
    let date: String?
    let value: Double?
    let unit: String?
    let obs_status: String?
    let decimal: Int?
}

struct GDPDataResponse: Codable {
    let data: [GDPIndicatorResponse]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Meta.self)
        data = try container.decode([GDPIndicatorResponse].self)
    }
}


struct Indicator: Codable {
    let id: String?
    let value: String?
}

struct IndicatorCountry: Codable {
    let id: String?
    let value: String?
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

// Update the Meta model to use FlexibleInt for per_page.
struct Meta: Codable {
    let page: Int
    let pages: Int
    let per_page: FlexibleInt  // now flexible
    let total: Int
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
     //   guard let url = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else {
     //       print("Invalid URL")
      //      return
      //  }
            do {
            /*    let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(CountryResponse.self, from: data)
                
                // Filter out non‑sovereign aggregates (assume region value "Aggregates" means not a real country)
                let realCountries = response.countries.filter { $0.region.value != "Aggregates" }
                self.countries = realCountries*/
                // This network call runs off the main thread.
                let realCountries = try await fetchCountries()
                                // Now update the UI on the main actor.
                await MainActor.run {
                    self.countries = realCountries
                    groupedCountries = Dictionary(grouping: realCountries, by: { $0.region.value })
                }
                
                // Fetch population and GDP concurrently.
                //async let popResult = fetchPopulation()
                //  async let gdpResult = fetchGDP()
                try await fetchPopulation()
                try await fetchGDP()
                //   _ = try await (popResult, gdpResult)
                //   _ = try await (fetchPopulation(), fetchGDP())
                
            } catch {
                print("Error fetching countries: \(error)")
            }
    }
    
    nonisolated  func fetchCountries() async throws -> [Country] {
        var countries: [Country] = []
        guard let url = URL(string: "https://api.worldbank.org/v2/country?format=json&per_page=300") else {
            throw URLError(.badURL)
        }
        do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CountryResponse.self, from: data)
        // Filter out aggregates here if desired.
            countries = response.countries.filter { $0.region.value != "Aggregates" }
        return  countries
        } catch {
            print("Error fetching countries: \(error)")
        }
        return countries
    }
    
    // Fetch Population (indicator "SP.POP.TOTL") for year 2022.
      nonisolated func fetchPopulation() async throws {
           guard let url = URL(string: "https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&per_page=500&date=2022") else { return }
           let (data, _) = try await URLSession.shared.data(from: url)
           let decoded = try JSONDecoder().decode(PopulationDataResponse.self, from: data)
           var dict: [String: Int] = [:]
           for item in decoded.data {
               if let code = item.countryiso3code, let value = item.value {
                   // Convert the Double value to Int (this truncates the fractional part)
                   dict[code] = Int(value)
               }
           }
           // Create an immutable copy before passing it to MainActor
               let result = dict
               await MainActor.run {
                   self.populationData = result
               }
         //  await MainActor.run { self.populationData = dict }
       }
       
       // Fetch GDP (indicator "NY.GDP.MKTP.CD") for year 2022.
    nonisolated  func fetchGDP() async throws {
           guard let url = URL(string: "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&per_page=500&date=2022") else { return }
           let (data, _) = try await URLSession.shared.data(from: url)
           let decoded = try JSONDecoder().decode(GDPDataResponse.self, from: data)
           var dict: [String: Double] = [:]
           for item in decoded.data {
               if let code = item.countryiso3code, let value = item.value {
                   dict[code] = value
               }
           }
           // Create an immutable copy before passing it to MainActor
               let result = dict
               await MainActor.run {
                   self.gdpData = result
               }
         //  await MainActor.run { self.gdpData = dict }
       }
}

import SwiftUI

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
                                    VStack(alignment: .leading, spacing: 0) {
                                        // HStack for flag and name.
                                        HStack {
                                            Text(country.iso2Code.flagEmoji)
                                              //  .font(.largeTitle)
                                                .font(.system(size: 45))
                                            Text(country.name)
                                                .font(.title2)
                                            Text(country.iso2Code)
                                                .font(.headline)
                                        }
                                        // HStack for population and GDP.
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
                                    .padding(.vertical, 4)
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

//without Map
/*
struct CountryDetailView: View {
    let country: Country
    let population: Int?
    let gdp: Double?
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Text("Flag:")
                    Spacer()
                    Text(country.iso2Code.flagEmoji)
                        .font(.system(size: 60))
                  //  .font(.largeTitle)
                }
                HStack {
                    Text("Capital:")
                    Spacer()
                    Text(country.capitalCity)
                }
                HStack {
                    Text("Region:")
                    Spacer()
                    Text(country.region.value)
                }
                HStack {
                    Text("Income Level:")
                    Spacer()
                    Text(country.incomeLevel.value)
                }
                HStack {
                    Text("ISO Code:")
                    Spacer()
                    Text(country.iso2Code)
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
            
            Section(header: Text("Location")) {
                HStack {
                    Text("Latitude:")
                    Spacer()
                    Text(country.latitude)
                }
                HStack {
                    Text("Longitude:")
                    Spacer()
                    Text(country.longitude)
                }
            }
        }
        .navigationTitle(country.name)
    }
}*/
 // with Map
import SwiftUI
import MapKit

struct CountryDetailView: View {
    let country: Country
    let population: Int?
    let gdp: Double?
    
    // Create a region state from the country's latitude/longitude.
   
    @State private var position : MapCameraPosition
    
    init(country: Country, population: Int?, gdp: Double?) {
        self.country = country
        self.population = population
        self.gdp = gdp
        
        // Convert latitude/longitude strings to Double.
        let lat = Double(country.latitude) ?? 0.0
        let lon = Double(country.longitude) ?? 0.0
       
        _position = State(initialValue:.region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
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
                HStack {
                    Text("Region:")
                    Spacer()
                    Text(country.region.value)
                }
           /*/     HStack {
                    Text("Income Level:")
                    Spacer()
                    Text(country.incomeLevel.value)
                }
                HStack {
                    Text("ISO Code:")
                    Spacer()
                    Text(country.iso2Code)
                }*/
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
            
            Section(header: Text("Map")) {
                // Display the map with a marker for the country.
             /*   Map(coordinateRegion: $region, annotationItems: [country]) { country in
                    // For annotation, convert the coordinate strings to Double.
                    let lat = Double(country.latitude) ?? 0.0
                    let lon = Double(country.longitude) ?? 0.0
                    return MapMarker(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }*/
                // Use the new iOS 17 Map initializer with a MapContentBuilder.
                Map (position: $position){
                      
                        Marker("\(country.capitalCity)", coordinate: CLLocationCoordinate2D(latitude: Double(country.latitude) ?? 0.0, longitude: Double(country.longitude) ?? 0.0))
                                }
                .frame(height: 300)
            }
        }
        .navigationTitle(country.name)
    }
}
*/

