//
//  ViewController.swift
//  CropTest
//
//  Created by oren shalev on 21/06/2023.
//

import UIKit
import CropViewController
import CropPickerView

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CropViewControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    var cropPickerView: CropPickerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cropPickerView = CropPickerView()
        self.view.addSubview(cropPickerView)
        
    }

    @IBAction func openCameraRoll(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func presentCropViewController(image: UIImage) {
      
      let cropViewController = CropViewController(image: image)
      cropViewController.delegate = self
        addChild(cropViewController)

         // Add the child's View as a subview
         self.view.addSubview(cropViewController.view)
        cropViewController.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height * 0.75)
        cropViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

         // tell the childviewcontroller it's contained in it's parent
        cropViewController.didMove(toParent: self)
//      present(cropViewController, animated: true, completion: nil)
    }

    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print(cropRect)
            // 'image' is the newly cropped version of the original image
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var newImage: UIImage

        if let possibleImage = info[.editedImage] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info[.originalImage] as? UIImage {
            newImage = possibleImage
        } else {
            return
        }

//        cropPickerView.image = newImage
        cropPickerView.image(newImage, crop: CGRect(x: 50, y: 30, width: 100, height: 80), isRealCropRect: false)
        cropPickerView.cropLineColor = UIColor.gray
        cropPickerView.scrollBackgroundColor = UIColor.gray
        cropPickerView.imageBackgroundColor = UIColor.gray
        cropPickerView.dimBackgroundColor = UIColor(white: 0, alpha: 0.1)
        cropPickerView.scrollMinimumZoomScale = 1
        cropPickerView.scrollMaximumZoomScale = 2
        cropPickerView.radius = 50
        cropPickerView.cropMinSize = 200
        cropPickerView.crop { (result) in
            if let error = (result.error as NSError?) {
                let alertController = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            self.imageView.image = result.image
        }
//        cropPickerView.image(image, crop: CGRect(x: 50, y: 30, width: 100, height: 80), isRealCropRect: true)
//        cropPickerView.image(image, isMin: false, crop: CGRect(x: 50, y: 30, width: 100, height: 80), isRealCropRect: true)
//        cropPickerView.image(image, isMin: false)
//        presentCropViewController(image: newImage)
        // do something interesting here!
        print(newImage.size)

        dismiss(animated: true)
    }
}

