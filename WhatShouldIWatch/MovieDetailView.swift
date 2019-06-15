//
//  MovieDetailView.swift
//  WhatShouldIWatch
//
//  Created by Tanmay Bakshi on 2019-06-14.
//  Copyright © 2019 Tanmay Bakshi. All rights reserved.
//

import SwiftUI

struct MovieDetailView: View {
    @State var movie: Movie
    
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            VStack(spacing: 5) {
                Image(uiImage: movie.link.downloadCoverImage())
                RatingView(movie: movie)
            }
            Spacer()
            Text(movie.link.downloadDescription())
                .fontWeight(.bold)
                .lineLimit(nil)
                .lineSpacing(5)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            Spacer()
            Spacer()
        }
        .navigationBarTitle(Text(movie.title))
    }
}

#if DEBUG
struct MovieDetailView_Previews: PreviewProvider {
    static var previews: some View {
        return MovieDetailView(movie: MovieDataProvider.shared.movies[0])
    }
}
#endif
