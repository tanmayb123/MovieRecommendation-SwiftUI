//
//  RatingView.swift
//  WhatShouldIWatch
//
//  Created by Tanmay Bakshi on 2019-06-14.
//  Copyright © 2019 Tanmay Bakshi. All rights reserved.
//

import SwiftUI

struct RatingView: View {
    @State var movie: Movie
    
    var body: some View {
        HStack {
            ForEach(1...5) { starIndex in
                if starIndex <= self.movie.rating.int {
                    Rectangle()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color.yellow)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                        .tapAction {
                            self.ratingSelected(index: starIndex)
                        }
                        .gesture(LongPressGesture().onEnded { _ in
                            self.movie.deleteRating()
                        })
                } else if (starIndex - 1) == self.movie.rating.int && self.movie.rating.isHalf {
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 12.5, height: 25)
                            .foregroundColor(Color.yellow)
                        Rectangle()
                            .frame(width: 12.5, height: 25)
                            .foregroundColor(Color.gray)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                    .tapAction {
                        self.ratingSelected(index: starIndex)
                    }
                } else {
                    Rectangle()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color.gray)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
                        .tapAction {
                            self.ratingSelected(index: starIndex)
                        }
                }
            }
        }
    }
    
    func ratingSelected(index: Int) {
        movie.rating = Rating(int: index, isHalf: false)
    }
}
