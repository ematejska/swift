// RUN: %target-run-eager-swift
//
// Note: GPE testing is disabled because GPE does not interact well with
// VJP-based AD. See SR-9638.
//
// REQUIRES: executable_test
//
// FIXME(TF-199): Indirect passing differentiation crashes with `-O`.
// UNSUPPORTED: swift_test_mode_optimize
//
// Tensor indirect passing AD runtime tests.

import TensorFlow
import StdlibUnittest
import TensorFlowUnittest

var TensorADTests = TestSuite("TensorIndirectAD")

TensorADTests.testAllBackends("Generic") {
  // TODO(TF-213): Remove unnecessary conformances after generic signature minimization bug fix.
  func indirect<Scalar : Differentiable & FloatingPoint>(_ x: Tensor<Scalar>) -> Tensor<Scalar>
    where Scalar == Scalar.CotangentVector
  {
    return (x + 3) * (x + 3)
  }
  expectEqual(Tensor(8), gradient(at: Tensor(1), in: indirect))
  expectEqual(Tensor(16), pullback(at: Tensor(1), in: indirect)(Tensor(2)))
}

TensorADTests.testAllBackends("Concrete") {
  @differentiable
  func indirect(_ x: Tensor<Float>) -> Tensor<Float> {
    return x * 1 * 1 * x
  }
  expectEqual(Tensor(12), pullback(at: Tensor<Float>(3), in: indirect)(Tensor(2)))
  expectEqual(Tensor(18), pullback(at: Tensor<Float>(3), in: indirect)(Tensor(3)))
}

// TODO(TF-213): Remove unnecessary conformances after generic signature minimization bug fix.
extension Tensor where Scalar : Differentiable & FloatingPoint,
                       Scalar.TangentVector : AdditiveArithmetic,
                       Scalar.CotangentVector : AdditiveArithmetic {
  @differentiable(vjp: vjpFoo)
  func foo(_ x: Scalar) -> Scalar {
    return x
  }
  func vjpFoo(_ x: Scalar) -> (Scalar, (Scalar.CotangentVector) -> Scalar.CotangentVector) {
    return (x, { v in v })
  }
}
TensorADTests.testAllBackends("GenericMethod") {
  expectEqual(Tensor(0), pullback(at: Tensor<Float>(2), in: { $0.foo(2) })(2))
  expectEqual(2.0, pullback(at: 1, in: { Tensor<Float>(1).foo($0) })(2))
  expectEqual((Tensor(0), 1), pullback(at: Tensor<Float>(1), 1, in: { $0.foo($1) })(1))
}

// Protocol with differentiable function requirement.
protocol Addable : Differentiable & FloatingPoint {
  @differentiable(wrt: (x, y))
  static func add(_ x: Self, _ y: Self) -> Self
}
extension Double : Addable {
  @differentiable(wrt: (x, y))
  static func add(_ x: Double, _ y: Double) -> Double {
    return x + y
  }
}
TensorADTests.testAllBackends("ResultSelection") {
  // TODO(TF-213): Remove unnecessary conformances after generic signature minimization bug fix.
  func indirect<T : Addable>(_ x: T, _ y: T) -> (T, T) where T.TangentVector : AdditiveArithmetic,
                                                             T.CotangentVector : AdditiveArithmetic {
    let first = T.add(x, x)
    return (T.add(first, first), T.add(y, 2))
  }
  expectEqual((4, 0), gradient(at: Double(3), 3, in: { x, y in indirect(x, y).0 }))
  expectEqual((0, 1), gradient(at: Double(3), 3, in: { x, y in indirect(x, y).1 }))
}

TensorADTests.testAllBackends("GenericLayerMember") {
  // Tests TF-203.
  // TODO(TF-213): Remove unnecessary conformances after generic signature minimization bug fix.
  struct GenericLayerWrapper<T: Layer> : Layer
    where T.TangentVector : AdditiveArithmetic, T.CotangentVector : AdditiveArithmetic,
          T.Input.TangentVector : AdditiveArithmetic, T.Input.CotangentVector : AdditiveArithmetic,
          T.Output.TangentVector : AdditiveArithmetic, T.Output.CotangentVector : AdditiveArithmetic
  {
    var layer: T
    @differentiable(wrt: (self, input))
    func applied(to input: T.Input) -> T.Output {
      return layer.applied(to: input)
    }
  }
}

TensorADTests.testAllBackends("GenericLayerMembers") {
  // Tests TF-235.
  // TODO(TF-213): Remove unnecessary conformances after generic signature minimization bug fix.
  struct Sequential<LHS: Layer, RHS: Layer>: Layer
    where LHS.Output == RHS.Input,
          LHS.TangentVector: AdditiveArithmetic,
          RHS.TangentVector: AdditiveArithmetic,
          LHS.CotangentVector: AdditiveArithmetic,
          RHS.CotangentVector: AdditiveArithmetic,
          LHS.Input.CotangentVector: AdditiveArithmetic,
          LHS.Output.CotangentVector: AdditiveArithmetic,
          RHS.Output.CotangentVector: AdditiveArithmetic,
          RHS.Output.TangentVector: AdditiveArithmetic {
    let lhs: LHS
    let rhs: RHS

    init(_ lhs: LHS, _ rhs: RHS) {
      self.lhs = lhs
      self.rhs = rhs
    }

    @differentiable(wrt: (self, input))
    func applied(to input: LHS.Input) -> RHS.Output {
      let intermediateValue = lhs.applied(to: input)
      return rhs.applied(to: intermediateValue)
    }
  }

  // TODO(TF-213): Remove unnecessary conformances after generic signature minimization bug fix.
  struct LayerTriple<T: Layer, U: Layer, V : Layer>: Layer
    where T.Output == U.Input, U.Output == V.Input,
          T.TangentVector: AdditiveArithmetic,
          U.TangentVector: AdditiveArithmetic,
          V.TangentVector: AdditiveArithmetic,
          T.CotangentVector: AdditiveArithmetic,
          U.CotangentVector: AdditiveArithmetic,
          V.CotangentVector: AdditiveArithmetic,
          T.Input.CotangentVector: AdditiveArithmetic,
          T.Output.CotangentVector: AdditiveArithmetic,
          U.Output.CotangentVector: AdditiveArithmetic,
          U.Output.TangentVector: AdditiveArithmetic {
    let first: T
    let second: U
    let third: V

    init(_ first: T, _ second: U, _ third: V) {
      self.first = first
      self.second = second
      self.third = third
    }

    @differentiable(wrt: (self, input))
    func applied(to input: T.Input) -> V.Output {
      let intermediate1 = first.applied(to: input)
      let intermediate2 = second.applied(to: intermediate1)
      return third.applied(to: intermediate2)
    }
  }

  // FIXME(TF-242): Pullback indirect results should not be released.
  // Otherwise, pullback calls segfault.
  /*
  func testFixedInput() {
    let lhs = Dense<Float>(inputSize: 3, outputSize: 4, activation: relu)
    let rhs = Dense<Float>(inputSize: 4, outputSize: 5, activation: sigmoid)
    let combined = Sequential(lhs, rhs)

    let input = Tensor<Float>(ones: [2, 3])
    let seed = Tensor<Float>(ones: [input.shape[0], rhs.weight.shape[1]])
    let (𝛁lhs, 𝛁rhs) = pullback(at: lhs, rhs) { lhs, rhs in
      rhs.applied(to: lhs.applied(to: input))
    }(seed)
    let 𝛁combined = pullback(at: combined) { $0.applied(to: input) }(seed + 1)
    expectEqual(Sequential.CotangentVector(lhs: 𝛁lhs, rhs: 𝛁rhs), 𝛁combined)
  }
  testFixedInput()

  func testWrtInput(_ input: Tensor<Float>) {
    let lhs = Dense<Float>(inputSize: 3, outputSize: 4, activation: relu)
    let rhs = Dense<Float>(inputSize: 4, outputSize: 5, activation: sigmoid)
    let combined = Sequential(lhs, rhs)

    let seed = Tensor<Float>(ones: [input.shape[0], rhs.weight.shape[1]])
    let (𝛁lhs, 𝛁rhs) = pullback(at: lhs, rhs) { lhs, rhs in
      rhs.applied(to: lhs.applied(to: input))
    }(seed)
    let 𝛁combined = pullback(at: combined) { $0.applied(to: input) }(seed)
    expectEqual(Sequential.CotangentVector(lhs: 𝛁lhs, rhs: 𝛁rhs), 𝛁combined)
  }
  testWrtInput(Tensor(randomUniform: [2, 3]))
  */
}

runAllTests()