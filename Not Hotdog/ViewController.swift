//
//  ViewController.swift
//  Not Hotdog
//
//  Created by David  on 7/16/18.
//  Copyright © 2018 David Huang. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var hotdogLabel: UILabel!
    
 
    @IBAction func hotdogPressed(_ sender: UIButton) {
        hotdogLabel.isHidden = true
        
        UIButton.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: {
            (finish) in
            UIButton.animate(withDuration:0.1, animations: {
                sender.transform = CGAffineTransform.identity
            })
        })
        
        guard let capturePhotoOutput = self.capturePhotoOutput else{
            return
        }
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = false
        photoSettings.flashMode = .off
        
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
        
        
    }
    
    var captureSession : AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    
    func detect(image: CIImage){
        
        guard let model =  try? VNCoreMLModel(for: Inceptionv3().model) else{
            fatalError("CoreML model loading failed")
        }
        
        
        let request = VNCoreMLRequest(model: model) {
            (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else{
                fatalError("Request failed")
            }
            if let firstResult = result.first {
                if firstResult.identifier.contains("hotdog"){
                    self.hotdogLabel.isHidden = false
                    self.hotdogLabel.text = "That's A Hotdog!"
                    self.hotdogLabel.textColor = UIColor.green
                }else{
                    self.hotdogLabel.isHidden = false
                    self.hotdogLabel.text = "Not Hot Dog :("
                    self.hotdogLabel.textColor = UIColor.red
                    
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
        
        do{
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = false
            
            captureSession?.addOutput(capturePhotoOutput!)
            
        } catch{
            print(error)
        }
        
       
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?){
        // Make sure we get some photo sample buffer
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        // Convert photo same buffer to a jpeg image data by using // AVCapturePhotoOutput
        guard let imageData =
            AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                return
        }
        // Initialise a UIImage with our image data
        let capturedImage = UIImage.init(data: imageData , scale: 1.0)
        guard let ciImage = CIImage(image: capturedImage!) else {
            fatalError("Could not convert to CI Image")
        }
        
        detect(image: ciImage)
        
    }
}



