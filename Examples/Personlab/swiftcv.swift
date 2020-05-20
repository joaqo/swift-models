// Taken from: https://github.com/fastai/course-v3/blob/21402bf741fe4325dd217e6739d95e4b28101ee3/nbs/swift/SwiftCV/Sources/SwiftCV/TensorFlowConversion.swift
import TensorFlow
import SwiftCV

public protocol ConvertibleFromCvMat {
    init?(cvMat: SwiftCV.Mat)
}

extension ShapedArray : ConvertibleFromCvMat {
    /// Creates a `ShapedArray` with the same shape and scalars as the specified
    /// `Mat` instance.
    public init?(cvMat: SwiftCV.Mat) {
        let matShape: [Int] = [cvMat.rows, cvMat.cols, cvMat.channels]
        // Make sure that the array is contiguous in memory. This does a copy if
        // the array is not already contiguous in memory.
        let contiguousMat = cvMat.isContinuous ? cvMat : cvMat.clone()
        let ptr = UnsafeRawPointer(contiguousMat.dataPtr).assumingMemoryBound(to: Scalar.self)

        // This code avoids calling `init<S : Sequence>(shape: [Int], scalars: S)`,
        // which inefficiently copies scalars one by one. Instead,
        // `init(shape: [Int], scalars: [Scalar])` is called, which efficiently
        // does a `memcpy` of the entire `scalars` array.
        // Unnecessary copying is minimized.
        let dummyPointer = UnsafeMutablePointer<Scalar>.allocate(capacity: 1)
        let scalarCount = matShape.reduce(1, *)
        var scalars: [Scalar] = Array(repeating: dummyPointer.move(), count: scalarCount)
        dummyPointer.deallocate()

        scalars.withUnsafeMutableBufferPointer { buffPtr in
            buffPtr.baseAddress!.assign(from: ptr, count: scalarCount)
        }

        self.init(shape: matShape, scalars: scalars)
    }
}

extension Tensor : ConvertibleFromCvMat {
    /// Creates a tensor with the same shape and scalars as the specified
    /// `Mat` instance.
    public init?(cvMat: SwiftCV.Mat) {
        let matShape: [Int] = [cvMat.rows, cvMat.cols, cvMat.channels]
        let tensorShape = TensorShape(matShape)

        // Make sure that the array is contiguous in memory. This does a copy if
        // the array is not already contiguous in memory.
        let contiguousMat = cvMat.isContinuous ? cvMat : cvMat.clone()
        let ptr = UnsafeRawPointer(contiguousMat.dataPtr).assumingMemoryBound(to: Scalar.self)

        let buffPtr = UnsafeBufferPointer(start: ptr,
                count: Int(tensorShape.contiguousSize))
        self.init(shape: tensorShape, scalars: buffPtr)
    }
}