//
//  Utils.swift
//  SwiftYogaKit
//
//  Created by v on 2020/9/26.
//  Copyright © 2020 facebook. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import Yoga

func YGScaleFactor() -> CGFloat {
    struct once {
        #if os(macOS)
        static let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1
        #else
        static let scaleFactor = UIScreen.main.scale
        #endif
    }

    return once.scaleFactor
}

func YGGlobalConfig() -> YGConfigRef {
    struct once {
        static let config: YGConfigRef = {
            let config = YGConfigNew()
            YGConfigSetExperimentalFeatureEnabled(config, .webFlexBasis, true)
            YGConfigSetPointScaleFactor(config, YGFloat(YGScaleFactor()))
            return config!
        }()
    }

    return once.config
}

func YGSanitizeMeasurement(_ constrainedSize: CGFloat, _ measuredSize: CGFloat, _ measureMode: YGMeasureMode) -> CGFloat {
    var result: CGFloat

    if measureMode == YGMeasureMode.exactly {
        result = constrainedSize
    } else if measureMode == YGMeasureMode.atMost {
        result = min(constrainedSize, measuredSize)
    } else {
        result = measuredSize
    }

    return result
}

func YGMeasureView(_ node: YGNodeRef!, _ width: YGFloat, _ widthMode: YGMeasureMode, _ height: YGFloat, _ heightMode: YGMeasureMode) -> YGSize {
    let constrainedWidth: CGFloat = (widthMode == YGMeasureMode.undefined) ? .greatestFiniteMagnitude : CGFloat(width)
    let constrainedHeight: CGFloat = (heightMode == YGMeasureMode.undefined) ? .greatestFiniteMagnitude : CGFloat(height)

    let view = Unmanaged<UIView>.fromOpaque(YGNodeGetContext(node)).takeUnretainedValue()
    let yoga = view.yoga
    if yoga.isBaseView {
        return YGSizeZero
    }

    #if os(macOS)
    let fittingSize = view.fittingSize
    let sizeThatFits = CGSize(width: min(fittingSize.width, constrainedWidth), height: min(fittingSize.height, constrainedHeight))
    #else
    let sizeThatFits = view.sizeThatFits(CGSize(width: constrainedWidth, height: constrainedHeight))
    #endif

    let w = YGFloat(YGSanitizeMeasurement(constrainedWidth, sizeThatFits.width, widthMode))
    let h = YGFloat(YGSanitizeMeasurement(constrainedHeight, sizeThatFits.height, heightMode))

    return YGSize(width: w, height: h)
}

func YGNodeHasExactSameChildren(_ node: YGNodeRef, _ subviews: [UIView]) -> Bool {
    let count = subviews.count
    guard YGNodeGetChildCount(node) == count else {
        return false
    }

    for i in 0 ..< count {
        let yoga = subviews[i].yoga
        if YGNodeGetChild(node, UInt32(i))?.hashValue != yoga.node.hashValue {
            return false
        }
    }

    return true
}

func YGAttachNodesFromViewHierachy(_ view: UIView) {
    let yoga = view.yoga
    let node = yoga.node

    if yoga.isLeaf {
        YGNodeRemoveAllChildren(node)
        YGNodeSetMeasureFunc(node, YGMeasureView)
        return
    }

    YGNodeSetMeasureFunc(node, nil)

    let subviewsToInclude = view.subviews.filter {
                                                    let yoga = $0.yoga
                                                    return yoga.isEnabled && yoga.isIncludedInLayout
                                                 }

    if !YGNodeHasExactSameChildren(node, subviewsToInclude) {
        YGNodeRemoveAllChildren(node)

        for i in 0 ..< subviewsToInclude.count {
            YGNodeInsertChild(node, subviewsToInclude[i].yoga.node, UInt32(i))
        }
    }

    subviewsToInclude.forEach { (subview) in
        YGAttachNodesFromViewHierachy(subview)
    }
}

func YGApplyLayoutToViewHierarchy(_ view: UIView, _ preserveOrigin: Bool) {
    let yoga = view.yoga
    guard yoga.isEnabled, yoga.isIncludedInLayout, !yoga.isApplingLayout else {
        return
    }

    yoga.isApplingLayout = true

    let node = yoga.node
    let topLeft = CGPoint(x: CGFloat(YGNodeLayoutGetLeft(node)), y: CGFloat(YGNodeLayoutGetTop(node)))
    let size = CGSize(width: CGFloat(max(YGNodeLayoutGetWidth(node), 0)), height: CGFloat(max(YGNodeLayoutGetHeight(node), 0)))
    var origin = CGPoint.zero

    #if os(macOS)
    if preserveOrigin {
        origin = view.frame.origin
    }
    #else
    let transformIsIdentity = view.transform.isIdentity

    if preserveOrigin {
        if transformIsIdentity {
            origin = view.frame.origin
        } else {
            let x = view.center.x - view.bounds.width * 0.5
            let y = view.center.y - view.bounds.height * 0.5
            origin = CGPoint(x: x, y: y)
        }
    }
    #endif

    var frame = CGRect(origin: origin, size: size).offsetBy(dx: topLeft.x, dy: topLeft.y)

    #if os(macOS)
    if let superview = view.superview, !superview.isFlipped, superview.yoga.isEnabled, superview.yoga.isIncludedInLayout {
        let height = CGFloat(max(YGNodeLayoutGetHeight(superview.yoga.node), 0))
        frame.origin.y = height - frame.maxY
    }

    view.frame = frame
    #else
    if transformIsIdentity {
        view.frame = frame
    } else {
        var bounds  = view.bounds
        bounds.size = size
        view.bounds = bounds
        view.center = CGPoint(x: frame.midX, y: frame.midY)
    }
    #endif
    
    if !yoga.isLeaf {
        for subview in view.subviews {
            YGApplyLayoutToViewHierarchy(subview, false)
        }
    }

    yoga.isApplingLayout = false
}