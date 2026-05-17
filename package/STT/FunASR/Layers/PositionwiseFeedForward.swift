// Originally from Codec/S3Gen/Transformer/PositionwiseFeedForward.swift
// Copyright (c) 2025 Resemble AI (original model implementation)
// Copyright (c) Anthony DePasquale (MLX port)
// License: licenses/chatterbox.txt

import Foundation
import MLX
import MLXNN

class PositionwiseFeedForward: Module {
  @ModuleInfo(key: "w_1") var w1: Linear
  @ModuleInfo(key: "w_2") var w2: Linear
  let activation: UnaryLayer
  let dropoutRate: Float

  init(
    idim: Int,
    hiddenUnits: Int,
    dropoutRate: Float,
    activation: UnaryLayer? = nil
  ) {
    _w1.wrappedValue = Linear(idim, hiddenUnits)
    _w2.wrappedValue = Linear(hiddenUnits, idim)
    self.activation = activation ?? ReLU()
    self.dropoutRate = dropoutRate
  }

  func callAsFunction(_ xs: MLXArray) -> MLXArray {
    var x = w1(xs)
    x = activation(x)
    return w2(x)
  }
}
