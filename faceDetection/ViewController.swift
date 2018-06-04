//
//  ViewController.swift
//  faceDetection
//
//  Created by HengVisal on 6/4/18.
//  Copyright © 2018 HengVisal. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController : UIViewController {
    
    var imageView : UIImageView!
    var session : AVCaptureSession!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var request : VNDetectFaceRectanglesRequest!
    var drawLine : UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Setup
        createComponent()
        addSupview()
        setupLayout()
        
        // FrameCature And Vision
        captureFrame()
        
    }
}

// MARK: - Create Component
extension ViewController {
    func createComponent() -> Void {
        // AVKit
        session = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        session.addInput(captureInput)
        session.startRunning()
        
        // PreviewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        
        // Drawline
        drawLine = UIView()
        drawLine.layer.borderColor = UIColor.red.cgColor
        drawLine.layer.borderWidth = 2
        drawLine.backgroundColor = UIColor.white
        drawLine.alpha = 0.4
    }
}

// MARK: - Add Supview
extension ViewController {
    func addSupview() -> Void {
        // Preview Layer
        self.view.layer.addSublayer(previewLayer)
    }
}

// MARK: - Setup Layout
extension ViewController {
    func setupLayout() -> Void {
        previewLayer.frame = self.view.frame
    }
}

// MARK: - Capture Frame
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureFrame() -> Void {
        
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoFrame"))
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        session.addOutput(captureOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        //Vision Request
        request = VNDetectFaceRectanglesRequest { (request, err) in
            guard let observations = request.results as? [VNFaceObservation] else {return}
            DispatchQueue.main.async {
                for face in observations{
                    print(face.boundingBox)
                    self.drawLine.frame = self.transformRect(fromRect: face.boundingBox, toViewRect: self.view)
                    self.view.addSubview(self.drawLine)
                }
            }
        }
        //Vision Handler
        var requestOptions:[VNImageOption : Any] = [:]
        // This request option is really important~ if allow our app to store image temporaily on the phone.
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification.\n\(error.localizedDescription)")
        }
    }
}

// MARK: - Draw The Box
extension ViewController {
    // Math Formulation to Caluculate the box
    func transformRect(fromRect: CGRect , toViewRect :UIView) -> CGRect {
        var toRect = CGRect()
        toRect.size.width = fromRect.size.width * toViewRect.frame.size.width
        toRect.size.height = fromRect.size.height * toViewRect.frame.size.height
        toRect.origin.y =  (toViewRect.frame.height) - (toViewRect.frame.height * fromRect.origin.y )
        toRect.origin.y  = toRect.origin.y -  toRect.size.height
        toRect.origin.x =  fromRect.origin.x * toViewRect.frame.size.width
        return toRect
    }
}



