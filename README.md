# Covid19 Detector iOS Application
 Covid-19 Detector iOS application with embedded deep learning classifier for detecting Covid-19, viral and bacterial pneumonia from frontal chest X-ray scans.

![alt text](https://raw.githubusercontent.com/rekalantar/Covid19-Detector-iOS-Application/master/application_demo.png)

### Software requirements:
Xcode/
Cocoapods/
Firebase package/
TensorFlowLite package

### Instructions:
(1) Clone directory and insert command 'pod install' in project root directory from the terminal

(2) Open the 'CovidCXR.xcworkspace' created and run the app through the iPhone/iPad simulator

(3) Click 'Load' on the app home page to upload photo from gallery and click 'detect' for inference

(4) To take photos for detection from device directly, an external iOS device needs to be connected and run instead of the simulator

(5) The 'Draw' button on the image can be activated to outline areas-of-interest on images

(5) Loaded images from gallery can be uploaded to database. Note: for patient security all texts from scans are automatically remove before uploading

