/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <vector>

#include <yoga/Yoga.h>
#include <yoga/node/Node.h>

namespace facebook::yoga {

struct FlexLineRunningLayout {
  // Total flex grow factors of flex items which are to be laid in the current
  // line. This is decremented as free space is distributed.
  double totalFlexGrowFactors{0.0};

  // Total flex shrink factors of flex items which are to be laid in the current
  // line. This is decremented as free space is distributed.
  double totalFlexShrinkScaledFactors{0.0};

  // The amount of available space within inner dimensions of the line which may
  // still be distributed.
  double remainingFreeSpace{0.0};

  // The size of the mainDim for the row after considering size, padding, margin
  // and border of flex items. This is used to calculate maxLineDim after going
  // through all the rows to decide on the main axis size of owner.
  double mainDim{0.0};

  // The size of the crossDim for the row after considering size, padding,
  // margin and border of flex items. Used for calculating containers crossSize.
  double crossDim{0.0};
};

struct FlexLine {
  // List of children which are part of the line flow. This means they are not
  // positioned absolutely, or with `display: "none"`, and do not overflow the
  // available dimensions.
  const std::vector<yoga::Node*> itemsInFlow{};

  // Accumulation of the dimensions and margin of all the children on the
  // current line. This will be used in order to either set the dimensions of
  // the node if none already exist or to compute the remaining space left for
  // the flexible children.
  const double sizeConsumed{0.0};

  // Number of edges along the line flow with an auto margin.
  const size_t numberOfAutoMargins{0};

  // Layout information about the line computed in steps after line-breaking
  FlexLineRunningLayout layout{};
};

// Calculates where a line starting at a given index should break, returning
// information about the collective children on the liune.
//
// This function assumes that all the children of node have their
// computedFlexBasis properly computed(To do this use
// computeFlexBasisForChildren function).
FlexLine calculateFlexLine(
    yoga::Node* node,
    Direction ownerDirection,
    double ownerWidth,
    double mainAxisOwnerSize,
    double availableInnerWidth,
    double availableInnerMainDim,
    Node::LayoutableChildren::Iterator& iterator,
    size_t lineCount);

} // namespace facebook::yoga
