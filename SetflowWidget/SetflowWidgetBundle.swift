//
//  SetflowWidgetBundle.swift
//  SetflowWidget
//
//  Created by macbook on 12/03/2026.
//

import WidgetKit
import SwiftUI

@main
struct SetflowWidgetBundle: WidgetBundle {
    var body: some Widget {
        SetflowWidget()
        SetflowWidgetControl()
        SetflowWidgetLiveActivity()
    }
}
