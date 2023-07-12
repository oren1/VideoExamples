/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
enum ProcessEffect {
  case builtIn
  case colorKernel
  case warpKernel
  case blendKernel
}
extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
      return image!
    }
}

class ImageProcessor {
  static let shared = ImageProcessor()
  let context = CIContext()

  @Published var output = UIImage()
  let orangeImage = UIImage.imageWithColor(color: UIColor.orange)
  // 1
  func process(painting: Painting, effect: ProcessEffect) {
    // 2
    guard
      let paintImage = UIImage(named: painting.image),
      let backgroundImage = UIImage(named: "rw-logo"),
      let input = CIImage(image: paintImage),
      let backgroundInput = CIImage(image: backgroundImage)
    else {
      print("Invalid input image")
      return
    }
    switch effect {
    // 3
    case .builtIn:
      applyBuiltInEffect(input: input)
    case .colorKernel:
      applyColorKernel(input: input)
    case .blendKernel:
      applyBlendKernel(input: input, backgroundInput: backgroundInput)
    default:
      print("Unsupported effect")
    }
  }

  
  private func renderAsUIImage(_ image: CIImage) -> UIImage? {
    if let cgImage = context.createCGImage(image, from: image.extent) {
      return UIImage(cgImage: cgImage)
    }
    return nil
  }
  
  // 1
  private func applyBuiltInEffect(input: CIImage) {
    // 2
    let noir = CIFilter(
      name: "CIPhotoEffectNoir",
      parameters: ["inputImage": input]
    )?.outputImage
    // 3
    let sunGenerate = CIFilter(
      name: "CISunbeamsGenerator",
      parameters: [
        "inputStriationStrength": 1,
        "inputSunRadius": 300,
        "inputCenter": CIVector(
          x: input.extent.width - input.extent.width / 5,
          y: input.extent.height - input.extent.height / 10)
      ])?
      .outputImage
    // 4
    let compositeImage = input.applyingFilter(
      "CIBlendWithMask",
      parameters: [
        kCIInputBackgroundImageKey: noir as Any,
        kCIInputMaskImageKey: sunGenerate as Any
      ])
    
    if let outputImage = renderAsUIImage(compositeImage) {
      output = outputImage
    }

  }

  private func applyColorKernel(input: CIImage) {
    let filter = ColorFilter()
    filter.inputImage = input
    if let outputImage = filter.outputImage,
      let renderImage = renderAsUIImage(outputImage) {
      output = renderImage
    }
  }
  
  private func applyBlendKernel(input: CIImage, backgroundInput: CIImage) {
    let filter = BlendFilter()
    filter.inputImage = input
    filter.backgroundImage = backgroundInput
    if let outputImage = filter.outputImage,
       let renderedImage = renderAsUIImage(outputImage) {
      output = renderedImage
    }
  }
  
}
