//
//  MovieView.swift
//  WhatShouldIWatch
//
//  Created by Tanmay Bakshi on 2019-06-13.
//  Copyright © 2019 Tanmay Bakshi. All rights reserved.
//

import SwiftUI

struct MovieView: View {
    @State var movies: [Movie] = MovieDataProvider.shared.ratedMovies()
    @State var searchTerm: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField($searchTerm, placeholder: Text("Search...")) {
                        self.processSearch()
                        UIApplication.shared.keyWindow?.endEditing(true)
                    }
                    Image(systemName: "xmark.circle.fill")
                        .tapAction {
                            self.searchTerm = ""
                            self.processSearch()
                            UIApplication.shared.keyWindow?.endEditing(true)
                        }
                }
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                VStack {
                    List(self.movies) { movie in
                        NavigationButton(destination: MovieDetailView(movie: movie)) {
                            HStack {
                                Image(uiImage: movie.link.downloadCoverImage())
                                    .resizable()
                                    .frame(width: 87, height: 127)
                                    .border(Color.gray, width: 5)
                                    .cornerRadius(10)
                                VStack(alignment: .leading) {
                                    ScrollView {
                                        Text(movie.title)
                                            .font(.largeTitle)
                                    }
                                    RatingView(movie: movie)
                                }
                            }
                        }
                    }
                    Button(action: {
                        self.movies = MovieDataProvider.shared.recommendations()
                    }) {
                        Text("RECOMMEND")
                    }
                }
            }
            .navigationBarTitle(Text("Movies"))
        }
    }
    
    private func processSearch() {
        if searchTerm == "" {
            movies = MovieDataProvider.shared.ratedMovies()
        } else {
            movies = MovieDataProvider.shared.performSearch(for: searchTerm)
        }
    }
}

#if DEBUG
struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        return MovieView()
    }
}
#endif
