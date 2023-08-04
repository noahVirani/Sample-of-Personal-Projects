//
//  CameraView.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/17/23.
//
import SwiftUI
import UIKit
import AVFoundation
import Vision

struct CameraView: UIViewRepresentable {
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var cameraView: UIView
        var cameraLayer: AVCaptureVideoPreviewLayer! = nil
        var score: Binding<Int>
        var lObject: Binding<String>
        let sObject: Binding<String>
        var win: Binding<Bool>
        
        var requests = [VNRequest]()
        var captureSession = AVCaptureSession()
        let videoDataOutput = AVCaptureVideoDataOutput()
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
        
        
        init(cameraView: UIView, score: Binding<Int>, lObject: Binding<String>, sObject: Binding<String>, win: Binding<Bool>) {
            self.cameraView = cameraView
            self.score = score
            self.lObject = lObject
            self.sObject = sObject
            self.win = win
        }
        
        func setup() {
            
            DispatchQueue.global(qos: .userInitiated).async {
                print("This is run on a background queue")
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    print("This is run on the main queue, after the previous code in outer block")
                    self.setupAVCapture()
                    self.setupVision()
                    
                }
            }
        
        }
        
        @discardableResult
        func setupVision() -> NSError? {
            // Setup Vision parts
            let error: NSError! = nil
            print("HiiVision")
            guard let modelURL = Bundle.main.url(forResource: "m", withExtension: "mlmodel") else {
                print("UHOH")
                return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
                    
            }
            do {
                print("HiiVision2")
                let compiledUrl = try MLModel.compileModel(at: modelURL)
                let model = try MLModel(contentsOf: compiledUrl)
                
                let visionModel = try VNCoreMLModel(for: model)
                
                let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                    DispatchQueue.main.async(execute: {
                        // perform all the UI updates on the main queue
                        if let results = request.results {
                            self.checkForObjectInScene(results)
                        }
                    })
                })
                self.requests = [objectRecognition]
            } catch let error as NSError {
                print("Model loading went wrong: \(error)")
            }
            return error
        }
        
        let inside = ["person", "bicycle", "car", "stop-sign", "bench", "dog", "backpack", "tie", "bottle", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "bed", "sofa", "diningtable", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "book", "clock", "vase", "scissors", "toothbrush", "pottedplant", "chair", "orannge", "pizza" ]
       
        
        func checkForObjectInScene(_ results: [Any]) {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            
            var pCount = score.wrappedValue
            
            for observation in results where observation is VNRecognizedObjectObservation {
                guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                    continue
                }
                let topLabelObservation = objectObservation.labels[0]
                
                
                if topLabelObservation.identifier == sObject.wrappedValue {
                    pCount+=1
                    
                    self.win.wrappedValue = true
                    self.sObject.wrappedValue = inside.randomElement()!
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                                       // To change the time, change 0.2 seconds above
                        self.win.wrappedValue = false
                    }
                }
                
                print(topLabelObservation.identifier)
                score.wrappedValue = pCount
                lObject.wrappedValue = topLabelObservation.identifier
            }
            
            CATransaction.commit()
        }
        
        func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
            let curDeviceOrientation = UIDeviceOrientation.portrait
            let exifOrientation: CGImagePropertyOrientation
            
            switch curDeviceOrientation {
            case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
                exifOrientation = .up
            case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
                exifOrientation = .upMirrored
            case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
                exifOrientation = .down
            case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
                exifOrientation = .up
            default:
                exifOrientation = .up
            }
            return exifOrientation
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            let exifOrientation = exifOrientationFromDeviceOrientation()
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
            do {
                try imageRequestHandler.perform(self.requests)
            } catch {
                print(error)
            }
        }
        
        func setupAVCapture() {
            var deviceInput: AVCaptureDeviceInput!
            var bufferSize: CGSize = .zero
            print("Hiiii")
            // Select a video device, make an input
            guard let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualWideCamera], mediaType: .video, position: .back).devices.first else {
                cameraView.backgroundColor = UIColor.blue
                return
            }
            
            
            
            do {
                deviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch {
                print("Could not create video device input: \(error)")
                return
            }
            
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .hd1920x1080
            
            // Add a video input
            guard captureSession.canAddInput(deviceInput) else {
                print("Could not add video device input to the session")
                captureSession.commitConfiguration()
                return
            }
            print("Hii")
            captureSession.addInput(deviceInput)
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                // Add a video data output
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            } else {
                print("Could not add video data output to the session")
                captureSession.commitConfiguration()
                return
            }
            let captureConnection = videoDataOutput.connection(with: .video)
            // Always process the frames
            captureConnection?.isEnabled = true
            do {
                try  videoDevice.lockForConfiguration()
                let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
                bufferSize.width = CGFloat(dimensions.width)
                bufferSize.height = CGFloat(dimensions.height)
                videoDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
            captureSession.commitConfiguration()
            cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 1.0)).scaledBy(x: 1, y: -1))
            cameraLayer.connection?.automaticallyAdjustsVideoMirroring = false
            cameraLayer.connection?.isVideoMirrored = true
            
            let rootLayer = cameraView.layer
            cameraLayer.frame = cameraView.bounds
            rootLayer.addSublayer(cameraLayer)
        }
    }
    
    var cameraView: UIView = UIView(frame: UIScreen.main.bounds)
    @Binding var score: Int
    @Binding var lObject: String
    @Binding var sObject: String
    @Binding var win: Bool
    
    func makeUIView(context: Context) -> UIView {
        
        
        context.coordinator.setup()
        
        return cameraView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraView: cameraView, score: $score, lObject: $lObject, sObject: $sObject, win: $win)
    }
}
