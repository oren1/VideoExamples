//
//  ViewController.swift
//  FilterTest
//
//  Created by oren shalev on 14/06/2023.
//

import UIKit
import CoreImage

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var context: CIContext!
    var currentFilter: CIFilter!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slide: UISlider!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        context = CIContext()
        currentFilter = CIFilter(name: "CIVibrance")
    }
    
    @IBAction func selectPhoto(_ sender: Any) {
        pickPhoto()
    }
    
    @objc func pickPhoto() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        let beginImage = CIImage(image: image)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        applyProcessing()
        //        let imageName = UUID().uuidString
        //        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        //
        //        if let jpegData = image.jpegData(compressionQuality: 0.8) {
        //            try? jpegData.write(to: imagePath)
        //        }
        
        dismiss(animated: true)
    }
    
    @IBAction func slideChange(_ sender: UISlider) {
        applyProcessing()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func applyProcessing() {

        let inputKeys = currentFilter.inputKeys
        print("inputKeys", inputKeys)
           if inputKeys.contains(kCIInputAmountKey) { currentFilter.setValue(slide.value, forKey: kCIInputAmountKey) }
//           if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(slide.value * 200, forKey: kCIInputRadiusKey) }
//           if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(slide.value * 10, forKey: kCIInputScaleKey) }
//           if inputKeys.contains(kCIInputCenterKey) &&
//                self.imageView.image != nil { currentFilter.setValue(CIVector(x: self.imageView.image!.size.width / 2, y: self.imageView.image!.size.height / 2), forKey: kCIInputCenterKey) }

           if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
               let processedImage = UIImage(cgImage: cgimg)
               self.imageView.image = processedImage
               
           }
//        guard let image = currentFilter.outputImage else { return }
//        currentFilter.setValue(slide.value, forKey: kCIInputIntensityKey)
//
//        if let cgimg = context.createCGImage(image, from: image.extent) {
//            let processedImage = UIImage(cgImage: cgimg)
//            imageView.image = processedImage
//        }
    }
    
    @IBAction func changeFilter(_ sender: Any) {
        let ac = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "CIExposureAdjust", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
    }

    func setFilter(action: UIAlertAction) {
        // make sure we have a valid image before continuing!
        guard let currentImage = imageView.image else { return }

        // safely read the alert action's title
        guard let actionTitle = action.title else { return }

        currentFilter = CIFilter(name: actionTitle)

        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

        applyProcessing()
    }
}

