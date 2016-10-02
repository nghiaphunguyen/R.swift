//
//  Image.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  Copyright © 2015 Mathijs Kadijk. All rights reserved.
//

import Foundation

struct ImageGenerator: Generator {
  let externalStruct: Struct?
  let internalStruct: Struct? = nil

  init(assetFolders: [AssetFolder], images: [Image]) {
    let assetFolderImageNames = assetFolders
      .flatMap { $0.imageAssets }

    let imagesNames = images
      .groupBy { $0.name }
      .values
      .flatMap { $0.first?.name }

    let allFunctions = assetFolderImageNames + imagesNames
    let groupedFunctions = allFunctions.groupBySwiftIdentifiers { $0 }

    groupedFunctions.printWarningsForDuplicatesAndEmpties(source: "image", result: "image")

    let imageLets = groupedFunctions
      .uniques
      .map { name in
        Let(
          comments: ["Image `\(name)`."],
          isStatic: true,
          name: SwiftIdentifier(name: name),
          typeDefinition: .Inferred(Type.ImageResource),
          value: "\(Type.ImageResource.name)(bundle: _R.hostingBundle, name: \"\(name)\")"
        )
      }

    externalStruct = Struct(
      comments: ["This `R.image` struct is generated, and contains static references to \(imageLets.count) images."],
      type: Type(module: .Host, name: "image"),
      implements: [],
      typealiasses: [],
      properties: imageLets.map(anyProperty),
      functions: groupedFunctions.uniques.map(ImageGenerator.functionForImageName),
      structs: []
    )
  }

  static func functionForImageName(name: String) -> Function {
    return Function(
      comments: ["`UIImage(named: \"\(name)\", bundle: ..., traitCollection: ...)`"],
      isStatic: true,
      name: SwiftIdentifier(name: name),
      generics: nil,
      parameters: [
        Function.Parameter(
          name: "compatibleWithTraitCollection",
          localName: "traitCollection",
          type: Type._UITraitCollection.asOptional(),
          defaultValue: "nil"
        )
      ],
      doesThrow: false,
      returnType: Type._UIImage,
      body: "return \(Type._UIImage.name)(resource: R.image.\(SwiftIdentifier(name: name)), compatibleWithTraitCollection: traitCollection)!"
    )
  }
}
