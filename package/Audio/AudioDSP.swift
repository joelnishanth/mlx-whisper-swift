// Extracted from Codec/S3Tokenizer/S3TokenizerUtils.swift
// Copyright (c) Anthony DePasquale (MLX port)
// STFT and mel filterbank functions for audio processing

import Foundation
import MLX

/// Compute STFT of a signal
func stft(
  _ x: MLXArray,
  window: MLXArray,
  nFft: Int,
  hopLength: Int,
  winLength _: Int,
  center: Bool = true,
  padMode _: String = "reflect"
) -> MLXArray {
  var xArray = x

  var w = window
  if w.shape[0] < nFft {
    let padSize = nFft - w.shape[0]
    w = MLX.concatenated([w, MLXArray.zeros([padSize])])
  }

  if center {
    xArray = reflectPad(xArray, padding: nFft / 2)
  }

  let numFrames = 1 + (xArray.shape[0] - nFft) / hopLength
  if numFrames <= 0 {
    fatalError("Input is too short for STFT")
  }

  let shape = [numFrames, nFft]
  let strides = [hopLength, 1]
  let frames = MLX.asStrided(xArray, shape, strides: strides)

  let windowedFrames = frames * w
  let spec = MLX.rfft(windowedFrames)

  return spec
}

/// Reflect padding for 1D array
private func reflectPad(_ x: MLXArray, padding: Int) -> MLXArray {
  if padding == 0 {
    return x
  }

  let n = x.shape[0]
  if n == 1 {
    return MLX.concatenated([
      MLXArray.full([padding], values: x[0]),
      x,
      MLXArray.full([padding], values: x[0]),
    ])
  }

  var prefixArray = reverseAlongAxis(x[1 ..< min(padding + 1, n)], axis: 0)
  var suffixArray = reverseAlongAxis(x[max(0, n - padding - 1) ..< (n - 1)], axis: 0)

  while prefixArray.shape[0] < padding {
    let additional = min(padding - prefixArray.shape[0], n - 1)
    prefixArray = MLX.concatenated([reverseAlongAxis(x[1 ..< (additional + 1)], axis: 0), prefixArray])
  }

  while suffixArray.shape[0] < padding {
    let additional = min(padding - suffixArray.shape[0], n - 1)
    suffixArray = MLX.concatenated([suffixArray, reverseAlongAxis(x[(n - additional - 1) ..< (n - 1)], axis: 0)])
  }

  return MLX.concatenated([prefixArray[0 ..< padding], x, suffixArray[0 ..< padding]])
}

/// Create mel filterbank (slaney normalization)
func melFilters(
  sampleRate: Int,
  nFft: Int,
  nMels: Int,
  fMin: Float = 0.0,
  fMax: Float? = nil
) -> MLXArray {
  let actualFMax = fMax ?? Float(sampleRate) / 2.0

  func hzToMel(_ hz: Float) -> Float {
    let fSp: Float = 200.0 / 3.0
    let minLogHz: Float = 1000.0
    let minLogMel = minLogHz / fSp
    let logstep: Float = log(6.4) / 27.0

    if hz >= minLogHz {
      return minLogMel + log(hz / minLogHz) / logstep
    } else {
      return hz / fSp
    }
  }

  func melToHz(_ mel: Float) -> Float {
    let fSp: Float = 200.0 / 3.0
    let minLogHz: Float = 1000.0
    let minLogMel = minLogHz / fSp
    let logstep: Float = log(6.4) / 27.0

    if mel >= minLogMel {
      return minLogHz * exp(logstep * (mel - minLogMel))
    } else {
      return fSp * mel
    }
  }

  let melMin = hzToMel(fMin)
  let melMax = hzToMel(actualFMax)
  let melPoints = (0 ... nMels + 1).map { i in
    melToHz(melMin + Float(i) * (melMax - melMin) / Float(nMels + 1))
  }

  let fftFreqs = (0 ..< (nFft / 2 + 1)).map { i in
    Float(i) * Float(sampleRate) / Float(nFft)
  }

  var filterbank = [[Float]](repeating: [Float](repeating: 0, count: nFft / 2 + 1), count: nMels)

  for m in 0 ..< nMels {
    let fLeft = melPoints[m]
    let fCenter = melPoints[m + 1]
    let fRight = melPoints[m + 2]

    for k in 0 ..< (nFft / 2 + 1) {
      let freq = fftFreqs[k]

      if freq >= fLeft, freq <= fCenter {
        filterbank[m][k] = (freq - fLeft) / (fCenter - fLeft)
      } else if freq > fCenter, freq <= fRight {
        filterbank[m][k] = (fRight - freq) / (fRight - fCenter)
      }
    }

    let enorm = 2.0 / (melPoints[m + 2] - melPoints[m])
    for k in 0 ..< (nFft / 2 + 1) {
      filterbank[m][k] *= enorm
    }
  }

  return MLXArray(filterbank.flatMap { $0 }).reshaped([nMels, nFft / 2 + 1])
}
