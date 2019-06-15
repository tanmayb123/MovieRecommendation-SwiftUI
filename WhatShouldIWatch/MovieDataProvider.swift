//
//  MovieDataProvider.swift
//  WhatShouldIWatch
//
//  Created by Tanmay Bakshi on 2019-06-14.
//  Copyright © 2019 Tanmay Bakshi. All rights reserved.
//

import SwiftUI
import Combine
import DynamicJSON

struct Rating {
    static let nonexistant = Rating(int: -1, isHalf: false)
    var int: Int
    var isHalf: Bool
    var string: String {
        return "\(int)\(isHalf ? ".5" : "")"
    }
    var double: Double {
        return Double(int) + (isHalf ? 0.5 : 0)
    }
}

extension Rating {
    init(doubleValue: Double) {
        let str = [Character](String(format: "%g", doubleValue))
        self.int = Int("\(str[0])")!
        self.isHalf = str.contains(".")
    }
}

struct _Movie: Codable {
    var movieId: String
    var title: String
    var genres: String
}

@dynamicMemberLookup
class Movie: BindableObject {
    
    let didChange = PassthroughSubject<Movie, Never>()
    
    var movie: _Movie

    var rating: Rating {
        get {
            let ratings = UserDefaults.standard.dictionary(forKey: Constants.ratings) as! [String: Double]
            if ratings.keys.contains(self.movieId) {
                return Rating(doubleValue: ratings[self.movieId]!)
            }
            return Rating.nonexistant
        }
        set {
            var ratings = UserDefaults.standard.dictionary(forKey: Constants.ratings) as! [String: Double]
            ratings[self.movieId] = newValue.double
            UserDefaults.standard.set(ratings, forKey: Constants.ratings)
            didChange.send(self)
        }
    }
    
    var link: Link {
        MovieDataProvider.shared.link(for: self)
    }
    
    subscript(dynamicMember member: String) -> String {
        switch member {
        case "movieId":
            return movie.movieId
        case "title":
            return movie.title
        case "genres":
            return movie.genres
        default:
            return ""
        }
    }
    
    init(movie: _Movie) {
        self.movie = movie
    }
    
    func deleteRating() {
        var ratings = UserDefaults.standard.dictionary(forKey: Constants.ratings) as! [String: Double]
        ratings[self.movieId] = nil
        UserDefaults.standard.set(ratings, forKey: Constants.ratings)
        didChange.send(self)
    }
    
}

struct _Link: Codable {
    var movieId: String
    var imdbId: String
    var tmdbId: String
}

@dynamicMemberLookup
class Link {
    
    var link: _Link
    
    private var tmdbRequestURL = "https://api.themoviedb.org/3/movie"
    private var imageRequestURL = "https://image.tmdb.org/t/p/w185"
    private var tmdbAPIKey = "adade7b15f9fdfde3f714dbc4d1c9b37"
    
    private var cachedTmdbResponse: JSON? = nil
    private var cachedCoverImage: UIImage? = nil
    private var cachedBackdropImage: UIImage? = nil
    private var cachedDescription: String? = nil
    
    subscript(dynamicMember member: String) -> String {
        switch member {
        case "movieId":
            return link.movieId
        case "imdbId":
            return link.imdbId
        case "tmdbId":
            return link.tmdbId
        default:
            return ""
        }
    }
    
    init(link: _Link) {
        self.link = link
    }
    
    func getTmdbResponse() {
        guard cachedTmdbResponse == nil else {
            return
        }
        let url = URL(string: "\(tmdbRequestURL)/\(self.tmdbId)?api_key=\(tmdbAPIKey)&language=en-US")!
        let response = try! Data(contentsOf: url)
        cachedTmdbResponse = try! JSON(data: response)
    }
    
    func downloadCoverImage() -> UIImage {
        if let cachedCoverImage = cachedCoverImage {
            return cachedCoverImage
        }
        getTmdbResponse()
        let posterPath = cachedTmdbResponse!.poster_path.string!
        let posterURL = URL(string: "\(imageRequestURL)\(posterPath)")!
        let posterData = try! Data(contentsOf: posterURL)
        cachedCoverImage = UIImage(data: posterData)
        return cachedCoverImage!
    }
    
    func downloadBackdropImage() -> UIImage? {
        if let cachedBackdropImage = cachedBackdropImage {
            return cachedBackdropImage
        }
        getTmdbResponse()
        guard let backdropPath = cachedTmdbResponse!.backdrop_path.string else {
            return nil
        }
        let backdropURL = URL(string: "\(imageRequestURL)\(backdropPath)")!
        let backdropData = try! Data(contentsOf: backdropURL)
        cachedBackdropImage = UIImage(data: backdropData)
        return cachedBackdropImage!
    }
    
    func downloadDescription() -> String {
        if let cachedDescription = cachedDescription {
            return cachedDescription
        }
        getTmdbResponse()
        cachedDescription = cachedTmdbResponse!.overview.string!
        return cachedDescription!
    }
    
}

struct MovieDataProvider {
    
    var movies: [Movie]
    var links: [Link]
    
    static var shared = MovieDataProvider()
    
    private let defaults = UserDefaults.standard
    private let model = MovieRec()
    
    init() {
        let moviesJSONURL = Bundle.main.url(forResource: "movies", withExtension: "json")!
        let moviesArray = try! JSON(data: try! String(contentsOf: moviesJSONURL).data(using: .utf8)!).array!
        self.movies = moviesArray.map({ Movie(movie: try! JSONDecoder().decode(_Movie.self, from: $0.data())) })
        let linksJSONURL = Bundle.main.url(forResource: "links", withExtension: "json")!
        let linksArray = try! JSON(data: try! String(contentsOf: linksJSONURL).data(using: .utf8)!).array!
        self.links = linksArray.map({ Link(link: try! JSONDecoder().decode(_Link.self, from: $0.data())) })
    }
    
    func movie(for id: String) -> Movie {
        return movies.filter({ $0.movieId == id })[0]
    }
    
    func link(for movie: Movie) -> Link {
        return links.filter({ $0.movieId == movie.movieId })[0]
    }
    
    func setupStorage() {
        if defaults.dictionary(forKey: Constants.ratings) == nil {
            defaults.set([String: Double](), forKey: Constants.ratings)
        }
    }
    
    func ratedMovies() -> [Movie] {
        let ratings = defaults.dictionary(forKey: Constants.ratings) as! [String: Double]
        return movies.filter({ ratings.keys.contains($0.movieId) })
    }
    
    func performSearch(for title: String) -> [Movie] {
        let title = title.lowercased()
        var matchingMovies: [Movie] = []
        for movie in movies {
            let distance = movie.title.lowercased().levenshtein(title)
            let percentageDistance = Double(distance) / Double(movie.title.count)
            var percentageOverlap = 1 - percentageDistance
            if movie.title.lowercased().contains(title) {
                percentageOverlap *= 1.5
            }
            if percentageOverlap > 0.7 {
                matchingMovies.append(movie)
            }
        }
        return matchingMovies
    }
    
    func recommendations() -> [Movie] {
        let recommendations = try! model.prediction(interactions: [Int64: Double](uniqueKeysWithValues: ratedMovies().map({ (Int64($0.movieId)!, $0.rating.double) })), k: 10)
        let sortedRecommendations = recommendations.recommendations.keys.map({ ($0, recommendations.recommendations[$0]) }).sorted(by: { $0.1! < $1.1! }).map({ $0.0 })
        return movies.filter({ sortedRecommendations.contains(Int64($0.movieId)!) })
    }
    
}
