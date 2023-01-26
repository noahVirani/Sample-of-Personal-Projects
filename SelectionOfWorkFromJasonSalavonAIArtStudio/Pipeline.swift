//
//  Pipeline.swift

//
//  Created by Noah Virani on 6/25/21
//  Copyright © 2021 Jason Salavon Studio. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import Vision

// MARK: - Global Variables
//private var face: [VNFaceObservation]?
//private var batch = batchProvider()
private var ciImagebackground: CIImage!
private var rollTolerance: CGFloat = 5.0
private var queue = DispatchQueue(label: "backgroundsync")
private var facePathCI: CIImage!

// MARK: - Pipeline
public protocol Pipeline: class, Orientable {
    var currentBackgroundModel: Model? { get }
    var rotationToggle: Bool { get set }
    var centerNose: Bool { get set }
    var postProcess: Bool { get set }
//    var ciImagebackground: CIImage! { get set }
    var postProcessBlend: Float { get set }
//    var pixelBuffer: CVImageBuffer? { get }
    var exifOrientation: CGImagePropertyOrientation? { get set }
    var imageRequestHandler: VNSequenceRequestHandler! { get }
    var request: VNDetectFaceLandmarksRequest { get }
    var lastobservation: CGRect! { get set }
    var previewView: PreviewView! { get }
    var numberOfPixelBuffers: Int { get }
    var tMask: Bool { get set }
    var viewFacePath: Bool { get }
    var scalingPercentage: Float { get set }
    var pixelBufferArray : [CVPixelBuffer?] { get }
    var context: CIContext! { get }
    var faceMask: Bool {get set}
    var facePathCrop: Bool {get set}
}

//extension Pipeline {
//    var request: VNDetectFaceLandmarksRequest {
//        get { return VNDetectFaceLandmarksRequest() }
//    }
//}

extension Pipeline {
    
    /// Detect faces in an image
    public func detectFaces(pixelBuffer: CVPixelBuffer) -> [VNFaceObservation]? {
        do {
            //  In theory, we can speed up face detection by giving it a pre detected face region. it doesnt seem to do much in practice, and does not really apply to multiple faces in this way.
//            requests[0].regionOfInterest = lastobservation
            request.regionOfInterest = lastobservation
            
            if #available(iOS 13.0, *) {
                request.revision = VNDetectFaceLandmarksRequestRevision3
                request.constellation = .constellation65Points
            }
            
            if self.exifOrientation == nil {
                self.exifOrientation = .up
            }
            
            //run face detection using our global imageRequestHandler
            try imageRequestHandler.perform([request], on: pixelBuffer, orientation: exifOrientation!)
            
            guard let results = request.results as? [VNFaceObservation] else {
                lastobservation = CGRect(x: 0, y: 0, width: 1, height: 1)
                return nil
            }
            
            return results
            
            
            
        } catch {
            print("error")
            return nil
        }
    }
    
    private func rotateAndCrop(ciImage: CIImage, oldbounds: CGRect, newbounds: CGRect, rotationAngle: CGFloat) -> CIImage {
        let centerx = oldbounds.midX
        let centery = oldbounds.midY
        let rotateFace: CGAffineTransform = CGAffineTransform(rotationAngle: rotationAngle)
        let shiftToOrigin: CGAffineTransform = CGAffineTransform(translationX: -centerx, y: -centery)
        let shiftFromOrigin: CGAffineTransform = CGAffineTransform(translationX: centerx, y: centery)
        
        let rotatedImage = ciImage.transformed(by: shiftToOrigin).transformed(by: rotateFace).transformed(by: shiftFromOrigin)
        let croppedImage = rotatedImage.clamped(to: newbounds).cropped(to: newbounds)
        return croppedImage
    }
    
    private func rotateFacePath(facePath: UIBezierPath, angle: CGFloat) {
        let centerx = facePath.bounds.midX
        let centery = facePath.bounds.midY
        let shiftToOrigin = CGAffineTransform(translationX: -centerx, y: -centery)
        let shiftFromOrigin = CGAffineTransform(translationX: centerx, y: centery)
        facePath.apply(shiftToOrigin)
        facePath.apply(CGAffineTransform(rotationAngle: angle))
        facePath.apply(shiftFromOrigin)
    }
    
    private func rotateBounds(bounds: CGRect, angle: CGFloat) -> CGRect {
        let centerx = bounds.midX
        let centery = bounds.midY
        let shiftToOrigin = CGAffineTransform(translationX: -centerx, y: -centery)
        let shiftFromOrigin = CGAffineTransform(translationX: centerx, y: centery)
        var newbounds = bounds
        newbounds = newbounds.applying(shiftToOrigin)
        newbounds = newbounds.applying(CGAffineTransform(rotationAngle: angle))
        newbounds = newbounds.applying(shiftFromOrigin)
        return newbounds.scaleToSquare()
    }
    
    /// For each face in the image: crop as a square + add to the inference batch
    public func processFaceInImage(displaying: Bool,
                            gallery: Bool,
                            pixelBuffer: CVPixelBuffer,
                            faces: [VNFaceObservation]?,
                            batch: batchProvider,
                            model: Model?,
                            _ width: CGFloat,
                            _ height: CGFloat) -> (newboundsarr: [CGRect], rollarr: [CGFloat], scalearr: [(CGFloat, CGFloat)], path: UIBezierPath?)? {
        //define the batch provider for this frame, we use batches to process multiple faces with a single inference call.
        //create CIImage from the pixelbuffer
        do {
            var ciImageFull = CIImage(cvImageBuffer: pixelBuffer, options: [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB()])
            var faceCt = 0
            
            //orient and clamp the full image to what we expect it to be.
            if displaying == true && gallery == false {
                /// we hard-code the portrait orientation here because we don't want to rotate the image when showing the live pipeline.
                ciImageFull = ciImageFull.oriented(self.exifOrientationForDeviceOrientation(.portrait))
            }
            
            //copy the full image to preserve the background
            ciImagebackground = (ciImageFull.copy() as! CIImage)
            facePathCI = CIImage.empty()
            
            //declare array to track positions of all faces found
            var newboundsarr: [CGRect] = []
            var scalearr: [(CGFloat, CGFloat)] = []
            var rollarr: [CGFloat] = []
            var fpath: UIBezierPath? = nil
            
            for face in faces ?? [] {
                //get a new ciImage that we can crop, mutate etc.
                guard let curModel = model else { return nil }
                var ciImage = ciImageFull.copy() as! CIImage
                ciImage = ciImage.samplingLinear()
                
                //TODO opt out if face is too contorted
                // if face.confidence > 0.9 { //confidence doesn't seem useful for our needs - results always seem highly confident
                // maybe some ratio math on face pts - ratios b/w nose & outer cheek pt, etc.
                
                //limit ourselves to  numPixBuffers faces for performance considerations.
                if faceCt < numberOfPixelBuffers {
                    
                    // for the next 20 lines or so, we see fucntions I (Isaac) wrote for genmo. They are a little unhinged, but get the job done. I'll document more when the first documentation pass is done.
                    let size = CGSize(width: width, height: height)
                    let faceBoundingBox = face.boundingBox.scaled(to: size)
                    
                    //convert the (normalized, weird coordinate system) points output by Vision, into the CI working space coordinates.
                    let allPoints = FaceTracer.convertPointsForFace(face.landmarks?.allPoints, faceBoundingBox)
                    // flatten an array points to an array of numbers
                    var allpointsONED: [CGFloat] = []
                    let all_points = (face.landmarks?.allPoints?.normalizedPoints)!
                    for point in all_points {
                        //print(point)
                        allpointsONED.append(point.x)
                        allpointsONED.append(1 - point.y) //our training points are inverted in y
                    }
                    
                    var bounds: CGRect!
                    var newbounds: CGRect!
                    var roll: CGFloat!
                    //create a bezierpath from the faceContour, we use the bounding box for cropping.
                    //Set up FacePath for preview drawing
                    //                if self.viewFacePath {
                    //                    print("got you1")
                    //                    // [left-eyebrown, right-eyebrown, face-contour]
                    //                    let facePts = [Array(allPoints[0...3]),Array(allPoints[4...7]),Array(allPoints[40...50])]
                    //                    //if there are no face points found, get put of here... we need face points to crop etc.
                    //                    if facePts[0].count == 0 {
                    //                        return nil
                    //                    }
                    //                    //[left-eye, right-eye, nose, mouth]
                    //                    let facePts2 = [Array(allPoints[8...15]),Array(allPoints[16...23]),Array(allPoints[51...62]),Array(allPoints[24...39])]
                    //                    let facePath = FaceTracer.getFacePath2(lineArray: facePts, lineArray2: facePts2, height: size.height, box: faceBoundingBox)
                    //                    bounds = facePath.path.bounds
                    //                    let facePathImage = FaceTracer.imagePath(paths: facePath.fullPaths, size: size)
                    //
                    //                    facePathCI = CIImage(image: facePathImage!)! //.clamped(to: ciImagebackground.extent)
                    //
                    //                    let transformFace:CGAffineTransform = CGAffineTransform(scaleX: ciImagebackground.extent.width/facePathCI.extent.width, y: ciImagebackground.extent.height/facePathCI.extent.height)
                    //                    facePathCI = facePathCI.transformed(by: transformFace)
                    if !self.tMask {
                        //print("got you2")
                        //[faceContour]
                        let facePts = [Array(allPoints[40..<51])]
                        //if there are no face points found, get out of here... we need face points to crop etc.
                        if facePts[0].count == 0 {
                            return nil
                        }
                        let facePath = FaceTracer.getFacePath(lineArray: facePts, height: size.height)
                        if facePathCrop {
                            fpath = facePath.path
                        }
                        bounds = facePath.path.bounds
                        roll = facePath.roll
                        if self.rotationToggle {
                            let angle: CGFloat = (CGFloat.pi * roll / 180.00)
                            let path = facePath.path
                            rotateFacePath(facePath: path, angle: angle)
                            newbounds = path.bounds
                            rotateFacePath(facePath: path, angle: -angle)
                        }
                        else {
                            newbounds = bounds
                        }
                        
                        
                        if self.viewFacePath {
                            let facePathImage = FaceTracer.imagePath(paths: [facePath.path], size: size)
                            
                            facePathCI = CIImage(image: facePathImage!)! //.clamped(to: ciImagebackground.extent)
                            
                            let transformFace = CGAffineTransform(scaleX: ciImagebackground.extent.width/facePathCI.extent.width,
                                                                  y: ciImagebackground.extent.height/facePathCI.extent.height)
                            facePathCI = facePathCI.transformed(by: transformFace)
                        }
                    } else { // t-shaped mask
                        //process face points for tMask
                        let facePts = [Array(allPoints)]
                        //let facePts = [Array(allPoints[40..<51])]
                        //if there are no face points found, get put of here... we need face points to crop etc.
                        if facePts[0].count == 0 {
                            return nil
                        }
                        let facePath = FaceTracer.getFaceTPath(lineArray: facePts, height: size.height)
                        if facePathCrop {
                            fpath = facePath.path
                        }
                        bounds = facePath.path.bounds
                        roll = facePath.roll
                        if self.rotationToggle {
                            let path = facePath.path
                            let angle: CGFloat = (CGFloat.pi * roll / 180.00)
                            rotateFacePath(facePath: path, angle: angle)
                            newbounds = path.bounds
                            rotateFacePath(facePath: path, angle: -angle)
                        }
                        else {
                            newbounds = bounds
                        }
                    
                        
                        if self.viewFacePath {
                            let facePathImage = FaceTracer.imagePath(paths: [facePath.path], size: size)
                            
                            facePathCI = CIImage(image: facePathImage!)! //.clamped(to: ciImagebackground.extent)
                            
                            let transformFace = CGAffineTransform(scaleX: ciImagebackground.extent.width/facePathCI.extent.width,
                                                                  y: ciImagebackground.extent.height/facePathCI.extent.height)
                            facePathCI = facePathCI.transformed(by: transformFace)
                        }
                    }
                    
                    // centerNose
                    if  (curModel.name == "trump") ||
                        (curModel.name == "putin") {
                        self.centerNose = true
                        self.facePathCrop = true
                    }
                    else {
                        self.centerNose = false
                    }
//                    if (curModel.name == "8mabel_sg.00.03.1"){
//                        self.scalingPercentage = -(1.0 - 1.0)
//                    }
                    
                    if self.centerNose {
                        let nosePoint_ = FaceTracer.convertPointsForFace(face.landmarks?.noseCrest, faceBoundingBox) //face.landmarks?.noseCrest?.pointsInImage(imageSize: size)[2]
                        let nosePT = CGPoint(x: nosePoint_[2].x, y: nosePoint_[2].y) //select nose points
                        let nosepath = FaceTracer.getNosePath(lineArray: [[nosePT]], height: size.height)
                        
                        let noseBounds = nosepath.bounds //CGPoint(x: nosePoint_.x, y: size.height - nosePoint_.y)
                        
                        let newNoseBounds = CGRect(x: noseBounds.origin.x,
                                                   y: size.height - noseBounds.origin.y - bounds.height,
                                                   width: noseBounds.width,
                                                   height: noseBounds.height)
                        
                        bounds = bounds.moveCenter(to: newNoseBounds.center)

                        if self.rotationToggle {
                            newbounds = newbounds.moveCenter(to: newNoseBounds.center)
                        } else {
                            newbounds = bounds
                        }
                    }
                    
                    // contruct transform to correct for face roll
                    let rotationAngle: CGFloat = (CGFloat.pi * roll / 180.00)
                    rollarr.append(roll)
                    
                    var oldBounds: CGRect
                    if self.centerNose {
                        oldBounds = bounds
                    } else {
                        oldBounds = CGRect(x: bounds.origin.x,
                                           y: size.height - bounds.origin.y - bounds.height,
                                           width: bounds.width,
                                           height: bounds.height)
                    }
                    
                    // scale to square since our models are trained in square
                    oldBounds = oldBounds.scaleToSquare()
                    var newBounds: CGRect = newbounds.scaleToSquare()
                    
                    // Setting the percentage will change the bounding box
                    // In order to get larger input bounds
                    oldBounds = oldBounds.insetBy(dx: oldBounds.width*2*CGFloat(self.scalingPercentage),
                                                  dy: oldBounds.height*2*CGFloat(self.scalingPercentage))
                    newboundsarr.append(oldBounds)
                    
                    
                    if self.rotationToggle && (roll.magnitude >= rollTolerance) {
                        
                        if !centerNose {
                            newBounds = CGRect(x: newbounds.origin.x,
                                               y: size.height - newbounds.origin.y - newbounds.height,
                                               width: newbounds.width,
                                               height: newbounds.height)
                            newBounds = newBounds.scaleToSquare()
                        }
                        
                        newBounds = newBounds.insetBy(dx: newBounds.width*2*CGFloat(self.scalingPercentage),
                                                      dy: newBounds.height*2*CGFloat(self.scalingPercentage))
                        
                        ciImage = rotateAndCrop(ciImage: ciImage, oldbounds: oldBounds,
                                                newbounds: newBounds, rotationAngle: rotationAngle)
                        
                    }
                    else {
                        ciImage = ciImage.clamped(to: oldBounds).cropped(to: oldBounds)
//                        scalearr.append((1, 1))
                    }
                    
                    //construct a transform to scale the image to the model input sizes
                    
                    let scaleX = CGFloat(curModel.outputDimensions.0)/ciImage.extent.width
                    let scaleY = CGFloat(curModel.outputDimensions.1)/ciImage.extent.height

                    scalearr.append((scaleX,scaleY))
                    
                    let transformPatch = CGAffineTransform(scaleX: CGFloat(curModel.inputDimensions.0)/ciImage.extent.width,
                                                           y: CGFloat(curModel.inputDimensions.1)/ciImage.extent.height)
                    let translate = CGAffineTransform(translationX: -oldBounds.origin.x,
                                                      y: -oldBounds.origin.y)
                    
                    ciImage = ciImage.transformed(by: translate).transformed(by: transformPatch)
                    
                    guard let coremlpixelBuffer = self.pixelBufferArray[faceCt] else {
                        print("returning due to no pixbuffarr")
                        return nil
                    }
                    self.context.render(ciImage, to: coremlpixelBuffer)
                    
                    if curModel.mlModel.modelDescription.inputDescriptionsByName.keys.contains("marker_input_2:0") {
                        let nullFaceMarkerModels: [String] = [] // names of models that use 0s in place of facemarkers
                        let markerArray = try MLMultiArray(shape: [NSNumber(value: 130)], dataType: .double)
                        for i in 0..<markerArray.count {
                            if nullFaceMarkerModels.contains(curModel.name) {
                                markerArray[i] =  NSNumber(value: 0)
                            } else {
                                markerArray[i] = NSNumber(value: Double(allpointsONED[i]))
                            }
                        }
                        
                        let input = modelInput(input_3_2_0: coremlpixelBuffer, marker_input_2_0: markerArray)
                        batch.addFeatureProvider(featureProvider: input)
                        self.tMask = true
                        self.scalingPercentage = -(1.025 - 1.0) // value human readable
                    } else if curModel.mlModel.modelDescription.inputDescriptionsByName.keys.contains("marker_ones_2:0") {
                        let markerArray = try MLMultiArray(shape: [NSNumber(value: 130)], dataType: .double)
                        for i in 0..<markerArray.count {
                            markerArray[i] =  NSNumber(value: 1)
                        }
                                            
                        let input = modelInput(input_3_2_0: coremlpixelBuffer, marker_ones_2_0: markerArray)
                        batch.addFeatureProvider(featureProvider: input)
                        self.tMask = true
//                        self.scalingPercentage = -(1.025 - 1.0) // value human readable
                    } else {
                        let input = modelInput(input_3_2_0: coremlpixelBuffer)
                        batch.addFeatureProvider(featureProvider: input)
                        self.tMask = true
//                        self.scalingPercentage = -(1.025 - 1.0) // value human readable
                    }
                    
                    faceCt += 1
                }
            }
            return (newboundsarr: newboundsarr, rollarr: rollarr, scalearr: scalearr, path: fpath)
            
        } catch {
            print("error processing the face: ", error)
            return nil
        }
    }
    
    
    /// Run inference on the batch. Gets an array of [(CIImage(rgb image), CIImage(mask image))]
    func runInferenceOnBatch(_ batch: batchProvider) -> [(CIImage,CIImage?)]? {
        guard let curModel = currentBackgroundModel else { return nil }
        let stylizedImages = curModel.inferBatch(batch, curModel.mlModel)
        
        for image in stylizedImages {
            //if any of the inferences failed, they return CIImages with 0 extent.
            //if the inferences failed, we don't want to continue
            if image.0.extent.size == CGSize(width: 0, height: 0) {
                return nil
            }
        }
        
        if self.viewFacePath {
            ciImagebackground = facePathCI.composited(over: ciImagebackground)
        }
        
        return stylizedImages
    }
    
    public func mergeFaceIntoOriginal(_ width: CGFloat,
                               _ height: CGFloat,
                               stylizedImages: [(CIImage,CIImage?)],
                               postProcess: Bool = false,
                               blendValue: Float = 1.0,
                               runLivePipeline: Bool = false,
                               boundsArr: [CGRect],
                               rollArr: [CGFloat],
                               scaleArr: [(CGFloat, CGFloat)],
                               facePath: UIBezierPath? = nil,
                               genmoEnabled: Bool = false,
                               ciImageBackground: CIImage) -> CIImage? {
        
        var images: [(CIImage, CIImage?)] = []
        
        if self.rotationToggle {
            
            if stylizedImages.count > rollArr.count {
                return nil
            }
            
            for (i, image) in stylizedImages.enumerated() {
                let roll = rollArr[i]
                
                if (roll.magnitude < rollTolerance) && !genmoEnabled || roll.magnitude == 0 {
                    images.append(image)
                    continue
                }
                
                var rgb = image.0
                var mask = image.1
                let scaleX = scaleArr[i].0
                let scaleY = scaleArr[i].1
                
                var rotationAngle: CGFloat
                if genmoEnabled {
                    rotationAngle = -roll
                } else {
                    rotationAngle = -(CGFloat.pi * roll / 180.00)
                }
                
                let scaleUp: CGAffineTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                let scaleDown: CGAffineTransform = CGAffineTransform(scaleX: 1/scaleX, y: 1/scaleY)
                
                rgb = rgb.transformed(by: scaleDown)
                var newbounds: CGRect
                var oldbounds: CGRect
                if genmoEnabled {
                    oldbounds = rgb.extent
                    newbounds = rotateBounds(bounds: rgb.extent, angle: rotationAngle)
                } else {
                    newbounds = boundsArr[i]
                    newbounds.origin = rgb.extent.origin
                    oldbounds = newbounds
                }
                rgb = rotateAndCrop(ciImage: rgb, oldbounds: oldbounds, newbounds: newbounds, rotationAngle: rotationAngle)
                rgb = rgb.transformed(by: CGAffineTransform(translationX: -rgb.extent.origin.x, y: -rgb.extent.origin.y))
                rgb = rgb.transformed(by: scaleUp)
                
                if mask != nil {
                    mask = mask!.transformed(by: scaleDown)
                    mask = rotateAndCrop(ciImage: mask!, oldbounds: oldbounds, newbounds: newbounds, rotationAngle: rotationAngle)
                    mask = mask!.transformed(by: CGAffineTransform(translationX: -mask!.extent.origin.x, y: -mask!.extent.origin.y))
                    mask = mask!.transformed(by: scaleUp)
                }
                
                images.append((rgb, mask))
            }
        }
        else {
            images = stylizedImages
        }
        
        // failure to get around a nil exception for ciImagebackground
//        if ciImagebackground == nil {
//            if let buf = self.pixelBuffer {
//                let ciImageFull = CIImage(cvImageBuffer: buf, options: nil)
//                ciImagebackground = ciImageFull.copy() as! CIImage
//            } else {
//                return nil
//            }
//        }
        
        var mergedImage = ProcessImageBatch.drawImageCIBatch(image: images,
                                                             inImage: ciImageBackground,
                                                             width: width,
                                                             height: height,
                                                             postProcess: postProcess,
                                                             faceMask: faceMask,
                                                             postProcessBlend: blendValue,
                                                             runLivePipeline: runLivePipeline,    // TEMP -- REFACTOR TO REMOVE THIS
                                                             bounds: boundsArr,
                                                             path: facePath)
        if self.viewFacePath {
            mergedImage = facePathCI.composited(over: mergedImage)
        }
                
        return mergedImage
    }
}



// MARK: - Gallery Photo
public protocol GalleryPhoto: Pipeline {
    var staticPreviewImage: UIImageView! { get }
    var chosenImage : UIImage! { get }
}

extension GalleryPhoto {
    @discardableResult
    public func directFaceDetection2(pixelBuffer: CVPixelBuffer) -> CIImage? {
        var width: CGFloat! = 0
        var height: CGFloat! = 0
        let batch = batchProvider()
        var mergedImage: CIImage?
        
        getDimensionsFromPixelBuffer(&width, &height, pixelBuffer)
        exifOrientation = .up
        orientBuffer(&width, &height, exifOrientation ?? .leftMirrored)
        
        let faces = detectFaces(pixelBuffer: pixelBuffer)
        if faces?.count != 0 {
            guard let newbounds = processFaceInImage(displaying: false,
                                                     gallery: true,
                                                     pixelBuffer: pixelBuffer,
                                                     faces: faces,
                                                     batch: batch,
                                                     model: currentBackgroundModel,
                                                     width,
                                                     height) else { return nil }
            guard let stylizedImage = runInferenceOnBatch(batch) else { return nil }
            let boundsArr = newbounds.newboundsarr
            let rollArr = newbounds.rollarr
            let scaleArr = newbounds.scalearr
            mergedImage = self.mergeFaceIntoOriginal(width,
                                                     height,
                                                     stylizedImages: stylizedImage,
                                                     postProcess: postProcess,
                                                     blendValue: postProcessBlend,
                                                     runLivePipeline: true,
                                                     boundsArr: boundsArr,
                                                     rollArr: rollArr,
                                                     scaleArr: scaleArr,
                                                     ciImageBackground: ciImagebackground)

            return mergedImage
        }
        return nil
    }
}



// MARK: - Gallery Video
public protocol GalleryVideo: Pipeline {
    var previewImage: UIImageView! { get }
    var lastProcessedImage: UIImage? { get set }
    var captureDelegate: GalleryCaptureDelegate? { get }
    var staticVideoURL: URL! { get }
    var galleryAudioTrack: AVAsset? { get }
}

extension GalleryVideo {
    @discardableResult
    public func directFaceDetection2(pixelBuffer: CVPixelBuffer, time: CMTime) -> CIImage? {
        var width: CGFloat! = 0
        var height: CGFloat! = 0
        let batch = batchProvider()
        var mergedImage: CIImage?
        
        getDimensionsFromPixelBuffer(&width, &height, pixelBuffer)
        exifOrientation = .up
        orientBuffer(&width, &height, exifOrientation ?? .leftMirrored)
        
        if currentBackgroundModel == nil {
            handleUnmodifiedGalleryMedia(width, height, pixelBuffer: pixelBuffer, time: time)
        } else {
            let faces = detectFaces(pixelBuffer: pixelBuffer)
            if faces?.count == 0 {
                lastobservation = CGRect(x: 0, y: 0, width: 1, height: 1)
                handleUnmodifiedGalleryMedia(width, height, pixelBuffer: pixelBuffer, time: time)
            } else {
                guard let newbounds = processFaceInImage(displaying: false,
                                                         gallery: true,
                                                         pixelBuffer: pixelBuffer,
                                                         faces: faces,
                                                         batch: batch,
                                                         model: currentBackgroundModel,
                                                         width,
                                                         height) else { return nil }
                guard let stylizedImage = runInferenceOnBatch(batch) else { return nil }
                let boundsArr = newbounds.newboundsarr
                let rollArr = newbounds.rollarr
                let scaleArr = newbounds.scalearr
                mergedImage = self.mergeFaceIntoOriginal(width,
                                                         height,
                                                         stylizedImages: stylizedImage,
                                                         postProcess: postProcess,
                                                         blendValue: postProcessBlend,
                                                         runLivePipeline: true,
                                                         boundsArr: boundsArr,
                                                         rollArr: rollArr,
                                                         scaleArr: scaleArr,
                                                         ciImageBackground: ciImagebackground)
                
                guard let mergedImage = mergedImage else { return nil }

                renderImageToDelegate(width, height, mergedImage, time)
                
                // TEMP -- make this a function
                // switch to the main thread to perform UI updates.
                DispatchQueue.main.async {
                    self.lastProcessedImage = UIImage(ciImage: mergedImage) //camera capture frame
                    self.previewImage.image = UIImage(ciImage: mergedImage)
                }
            }
        }
        return mergedImage
    }
    
    private func handleUnmodifiedGalleryMedia(_ width: CGFloat, _ height: CGFloat, pixelBuffer: CVPixelBuffer, time: CMTime) {
        DispatchQueue.main.async {
            //copy the current buffer to CoreImage, orient it, render to new buffer for recording
            
            //create CIImage from the pixelbuffer
            var ciImageFull: CIImage? = CIImage(cvImageBuffer: pixelBuffer, options: nil)
            
            //orient and clamp the full image to what we expect it to be.
            ciImageFull = ciImageFull!.oriented(self.exifOrientation ?? .leftMirrored)
            
            var newpixelbuffer: CVPixelBuffer? = nil
            CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, nil, &newpixelbuffer)
            self.context.render(ciImageFull!, to: newpixelbuffer!)
            self.previewImage.image = UIImage(ciImage: ciImageFull!)
            
            self.captureDelegate?.addGalleryFrame(frame: newpixelbuffer!, time: time)
            ciImageFull = nil
            newpixelbuffer = nil
        }
    }
    
    private func renderImageToDelegate(_ width: CGFloat, _ height: CGFloat, _ mergedImage: CIImage, _ time: CMTime) {
        var newpixelbuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, nil, &newpixelbuffer)
        self.context.render(mergedImage, to: newpixelbuffer!)
        self.captureDelegate?.addGalleryFrame(frame: newpixelbuffer!, time: time)
    }
    
}


// MARK: - LivePipeline
// Cases B & C (see function description above)
public protocol LivePipeline: Pipeline {
    var previewImage: UIImageView! { get }
    var lastProcessedImage: UIImage? { get set }
    var initialRecordingOrientation: UIDeviceOrientation? { get }
    var timeBetweenFrames: Double { get }
    var captureButton: CaptureButton! { get }
    var OTFVideoRecorder: OnTheFlyVideoWriter? { get }
}

extension LivePipeline {
    @discardableResult
    public func directFaceDetection2(pixelBuffer: CVPixelBuffer) -> CIImage? {
        var width: CGFloat! = 0
        var height: CGFloat! = 0
        let batch = batchProvider()
        var mergedImage: CIImage!
        
        getDimensionsFromPixelBuffer(&width, &height, pixelBuffer)
        /// we hard-code the portrait orientation here because we don't actually want to rotate the image when showing the live pipeline.
        exifOrientation = exifOrientationForDeviceOrientation(.portrait)
        
        if currentBackgroundModel == nil {
            handleUnmodifiedLiveRecordBuffer(pixelBuffer: pixelBuffer)
        } else {
            let faces = detectFaces(pixelBuffer: pixelBuffer)
            if faces?.count == 0 {
                lastobservation = CGRect(x: 0, y: 0, width: 1, height: 1)
                handleUnmodifiedLiveRecordBuffer(pixelBuffer: pixelBuffer)
            } else {
                // FIXME: make this a 'guard let'
                queue.sync {
                    let newbounds = self.processFaceInImage(displaying: true,
                                                            gallery: false,
                                                            pixelBuffer: pixelBuffer,
                                                            faces: faces,
                                                            batch: batch,
                                                            model: currentBackgroundModel,
                                                            width,
                                                            height)
                    let stylizedImage = self.runInferenceOnBatch(batch)
                    guard let boundsArr = newbounds?.newboundsarr,
                        let rollarr = newbounds?.rollarr,
                        let images = stylizedImage,
                        let scalearr = newbounds?.scalearr else {return}
                    mergedImage = self.mergeFaceIntoOriginal(width, height, stylizedImages: images, postProcess: postProcess, blendValue: postProcessBlend, runLivePipeline: true, boundsArr: boundsArr, rollArr: rollarr, scaleArr: scalearr, facePath: newbounds?.path, ciImageBackground: ciImagebackground)
                }
                
                guard let mergedImage = mergedImage else {return nil}
                
                if self.captureButton.getCameraStatus() == .recording {
                    renderToRecordingDelegate(orientation: orientation,
                                              position: devicePosition,
                                              mergedImage: mergedImage)
                }
                
                // switch to the main thread to perform UI updates.
                DispatchQueue.main.async {
                    self.lastProcessedImage = UIImage(ciImage:mergedImage)//camera capture frame
                    //hide the video preview
                    //self.previewView.videoPreviewLayer.isHidden = true
                    //unhide the image preview... Ideally we would be outputting to a video optimized layer but hey, we're not ios experts
                    self.previewImage.isHidden = false
                    self.previewImage.image = UIImage(ciImage: mergedImage)
                }
            }
        }
        return nil
    }
    
    private func handleUnmodifiedLiveRecordBuffer(orientation: UIDeviceOrientation? = nil,
                                                  position: AVCaptureDevice.Position? = nil,
                                                  pixelBuffer: CVPixelBuffer) {
        DispatchQueue.main.async {
            
            
            if self.captureButton.getCameraStatus() == .recording {
                //copy the current buffer to CoreImage, orient it, render to new buffer for recording
                
                //create CIImage from the pixelbuffer
                var ciImageFull: CIImage? = CIImage(cvImageBuffer: pixelBuffer, options: nil)
                
                //orient and clamp the full image to what we expect it to be.
                ciImageFull = ciImageFull!.oriented(self.exifOrientationForDeviceOrientation(self.initialRecordingOrientation!))
                                
                let width = ciImageFull!.extent.width
                let height = ciImageFull!.extent.height
                
                var newpixelbuffer: CVPixelBuffer? = nil
                
                CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, nil, &newpixelbuffer)
                
                self.context.render(ciImageFull!, to: newpixelbuffer!)
                self.previewImage.image = UIImage(ciImage: ciImageFull!)
                
                //MARK: Manually set timestamp for recording
                let timescale = CMTimeScale(bitPattern: UInt32(1/self.timeBetweenFrames))
                let time = CMTime.init(seconds: 0.3, preferredTimescale: timescale) // CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
                self.captureButton.captureDelegate?.addLiveFrame(frame: newpixelbuffer!, time: time)
                ciImageFull = nil
                newpixelbuffer = nil
            } else {
                //self.previewView.videoPreviewLayer.isHidden = false ///why? we arent processing anything, lets just use the video display that is already set up
                self.previewImage.isHidden = true /// why? this is on top of the video display
                
                //create CIImage from the pixelbuffer
                var ciImageFull: CIImage? = CIImage(cvImageBuffer: pixelBuffer, options: nil)
                
                //orient and clamp the full image to what we expect it to be.
                ciImageFull = ciImageFull!.oriented(self.exifOrientationForDeviceOrientation(.portrait))
                self.lastProcessedImage = UIImage(ciImage: ciImageFull!)
            }
        }
    }
    
    private func renderToRecordingDelegate(orientation: UIDeviceOrientation? = nil,
                                           position: AVCaptureDevice.Position? = nil,
                                           mergedImage: CIImage) {
        //render the image to a new pixelbuffer, send new buffer to the recording delegate
        
        var width = mergedImage.extent.width
        var height = mergedImage.extent.height
        
        if self.initialRecordingOrientation!.isLandscape {
            let tempWidth = width
            width = height
            height = tempWidth
        }
        
        var mergedImage2: CIImage = mergedImage.oriented(self.exifOrientationForDeviceOrientation(.portrait)).oriented(self.exifOrientationForDeviceOrientation(self.initialRecordingOrientation!))
        
        /// When using the back camera, we need to flip the orientation
        if self.devicePosition == .back {
            mergedImage2 = mergedImage2.oriented(.down)
        }
        
        // FIXME:- make this a CVPixelBufferPool so I'm not continually instantinating a new CVPixelBuffer
        // from apple docs: "If you need to create and release a number of pixel buffers, you should instead use a pixel buffer pool (see CVPixelBufferPool) for efficient reuse of pixel buffer memory."
        // https://developer.apple.com/documentation/corevideo/1456758-cvpixelbuffercreate
        var newpixelbuffer: CVPixelBuffer? = nil
        
        CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, nil, &newpixelbuffer)
        
        self.context.render(mergedImage2, to: newpixelbuffer!)
        
        //MARK: Manually set timestamp for recording
        let timescale = CMTimeScale(bitPattern: UInt32(1/timeBetweenFrames))
        let time = CMTime.init(seconds: 0.3, preferredTimescale: timescale)//
        self.captureButton.captureDelegate?.addLiveFrame(frame: newpixelbuffer!, time: time)
    }
    
    /// Returns **true** if the current device orientation is different from the device's orientation when the recording began; returns **false** otherwise.
    /// Currently, this function never gets used.
    private func orientationDidChangeFromInitialOrientation() -> Bool {
        if ((self.orientation == .landscapeLeft || self.orientation == .landscapeRight) &&
            (self.initialRecordingOrientation! == .portraitUpsideDown || self.initialRecordingOrientation! == .portrait) ||
            (self.orientation == .portrait || self.orientation == .portraitUpsideDown) &&
            (self.initialRecordingOrientation! == .landscapeLeft || self.initialRecordingOrientation! == .landscapeRight)) {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Private Functions
private func getDimensionsFromPixelBuffer(_ width: inout CGFloat, _ height: inout CGFloat, _ pixelBuffer: CVPixelBuffer) {
    width = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
    height = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
}
