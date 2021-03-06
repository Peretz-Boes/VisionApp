//
//  RoundedShadowButton.swift
//  vision
//
//  Created by peretz on 2017-11-19.
//  Copyright © 2017 peretz. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {
    
    override func awakeFromNib() {
        self.layer.shadowColor=UIColor.darkGray.cgColor
        self.layer.shadowRadius=15
        self.layer.shadowOpacity=0.75
        self.layer.cornerRadius=self.layer.frame.height/2
    }
    
}
