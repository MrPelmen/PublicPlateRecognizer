//
//  ContentView.swift
//  PlateRecognizer
//
//  Created by Пермяков Андрей on 19.06.2022.
//

import SwiftUI

struct ContentView: View {
  @State private var galleryUIImage: UIImage?
  @State private var imageViewActive = false
  @State private var presentingPicker = false
  @State private var presentingSaved = false
  
  @StateObject private var camera = CameraVm()
  @EnvironmentObject private var platesVm: PlatesVm
  private var galleryImage: Image? {
    guard let uiImage = galleryUIImage else { return nil }
    return Image(uiImage: uiImage)
  }
  
  var body: some View {
    NavigationView {
      ZStack {
        VStack(spacing: 0) {
          cameraView
            .frame(height: Constants.cameraViewHeight)
            .clipped()
          buttonsView
            .background(.white)
          Spacer()
        }
        cameraSmallButtons.opacity(camera.isTaken ? 1 : 0)
      }
      .sheet(isPresented: $presentingPicker, onDismiss: {
        presentingPicker = false
        if let image = galleryUIImage { recognize(image: image) }
      }) {
        ImagePickerView(image: $galleryUIImage)
      }
      .onChange(of: presentingPicker) { switchCamera(off: $0) }
      .onChange(of: presentingSaved) { switchCamera(off: $0) }
      .navigationTitle("Licence Plate Scan")
      .navigationViewStyle(.stack)
      .navigationBarTitleDisplayMode(.inline)
    }
    .background(.green)
  }
  
  private var cameraSmallButtons: some View {
    VStack {
      HStack {
        NavigationLink(isActive: $imageViewActive, destination: {
          PlateDetailsView(
            image: Image(uiImage: platesVm.image ?? UIImage()),
            plateData: platesVm.plateData,
            recognizedPlateText: platesVm.recognizedPlateText
          )
        }) {
          scanSmallButton
        }
        .padding(.leading)
        .onChange(of: imageViewActive) { if !$0 { platesVm.clearOldData() } }
        Spacer()
        retakePhotoSmallButton
          .padding(.trailing)
      }
      .padding(.top, 50)
      Spacer()
    }
  }
  
  private var scanSmallButton: some View {
    ZStack {
      Circle()
        .frame(width: 55, height: 55)
        .foregroundColor(.white)
      smallButton(with: "viewfinder.circle") {
        recognizeImageData()
      }
    }
  }
  
  private var retakePhotoSmallButton: some View {
    ZStack {
      Circle()
        .frame(width: 55, height: 55 )
        .foregroundColor(.white)
      smallButton(with: "arrow.triangle.2.circlepath.camera") {
        platesVm.clearOldData()
        camera.retakePhoto()
      }
    }
  }
  
  private var cameraView: some View {
    CameraPreview(camera: camera)
      .zIndex(-1)
      .onAppear {
        camera.checkAuthorization()
      }
  }
  
  private var takePhotoButton: some View {
    Button {
      camera.takePhoto()
    } label: {
      ZStack {
        Circle()
          .frame(width: 115)
          .foregroundColor(.white)
        Circle()
          .frame(width: 98)
          .foregroundColor(.main.opacity(0.5))
        Circle()
          .frame(width: 88)
          .foregroundColor(.white)
        Circle()
          .frame(width: 80)
          .foregroundColor(.main)
      }
    }
    .disabled(camera.isTaken)
    .frame(width: 115, height: 115)
  }
  
  private var buttonsView: some View {
    VStack {
      takePhotoButton
      Spacer()
      HStack {
        Spacer()
        presentPhotoPickerButton
        Spacer()
        toggleTorchButton
        Spacer()
        viewSavedButton
        Spacer()
      }
      .foregroundColor(Color("main"))
    }
    .offset(x: 0, y: -(115 / 2))
  }
  
  private var presentPhotoPickerButton: some View {
    smallButton(with: "photo") {
      presentingPicker = true
    }
  }
  
  private var toggleTorchButton: some View {
    smallButton(with: camera.torchOn ? "bolt.fill" : "bolt" ) {
      camera.toggleTorch()
    }
  }
  
  private var viewSavedButton: some View {
    NavigationLink(isActive: $presentingSaved) {
      PlateListView()
        .background(.white)
    } label: {
      smallButton(with: "clock.arrow.circlepath") {
        presentingSaved = true
      }
    }
  }
}

// MARK: - Funcs.

extension ContentView {
  private func switchCamera(off: Bool) {
    if off {
      camera.pause()
    } else if !camera.isTaken {
      camera.continueSession()
    }
  }
  
  private func smallButton(
    with imageName: String,
    _ action: @escaping () -> ()
  ) -> some View {
    Button {
      action()
    } label: {
      Image(systemName: imageName)
        .resizable()
        .scaledToFit()
    }
    .foregroundColor(.main)
    .frame(width: 44, height: 44)
  }
  
  private func recognizeImageData() {
    guard let imageData = camera.imageData,
          let uiImage = UIImage(data: imageData)?.cameraFocusArea()
    else { return }
    platesVm.tryToRecognizeText(in: uiImage)
    imageViewActive = true
  }
  
  private func recognize(image: UIImage) {
    platesVm.tryToRecognizeText(in: image)
    imageViewActive = true
  }
}
