//
//  RoundedShadowImageView.swift
//  vision-app-dev
//
//  Created by 張書涵 on 2018/2/13.
//  Copyright © 2018年 AliceChang. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {
   
    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15
    }
    

}
