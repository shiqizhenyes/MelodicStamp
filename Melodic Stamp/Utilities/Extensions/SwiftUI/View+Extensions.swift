//
//  View+Extensions.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/20.
//

import SwiftUI

extension View {
    func observeAnimation<Value: VectorArithmetic>(for observedValue: Value, onChange: ((Value) -> ())? = nil, onComplete: (() -> ())? = nil) -> some View {
        modifier(AnimationObserverModifier(for: observedValue, onChange: onChange, onComplete: onComplete))
    }
}

extension View {
    @ViewBuilder func aliveHighlight(_ isHighlighted: Bool, cornerRadius: CGFloat = 8) -> some View {
        modifier(AliveHighlightViewModifier(isHighlighted: isHighlighted, cornerRadius: cornerRadius))
    }
}
