//
//  StaticTableSelectableCellModel.swift
//  Antidote
//
//  Created by Dmytro Vorobiov on 02/12/15.
//  Copyright © 2015 dvor. All rights reserved.
//

import Foundation

class StaticTableSelectableCellModel: StaticTableBaseCellModel {
    var didSelectHandler: (StaticTableBaseCell -> Void)?
}
