#!/usr/bin/env swift
//
//  generate-dashboard-icons.swift
//  LookInside
//
//  Draws dashboard card icons in the card icon style (node-model-internals.md,
//  trap 10): a 15×15 square with corner radius 1 filled with the family
//  colour, a 2 pt stroke one shade darker clipped to the canvas (so 1 pt shows
//  inside), and a glyph that is white in the light appearance and the
//  family's near-black in the dark one; secondary parts of a glyph are drawn
//  at reduced opacity. Each icon is written as a light and a dark vector PDF
//  with its Contents.json into Assets.xcassets/Dashboard.
//
//  Usage (from the LookInside repository):
//    swift Scripts/generate-dashboard-icons.swift             draw the icons that do not exist yet
//    swift Scripts/generate-dashboard-icons.swift --force     redraw every icon below
//    swift Scripts/generate-dashboard-icons.swift ruler view  draw only these (implies --force)
//
//  PDFs carry their creation date, so redrawing an unchanged icon still
//  changes the file; that is why existing icons are left alone by default.
//

import CoreGraphics
import Foundation

struct IconFamily {
    let fill: CGColor
    let stroke: CGColor
    let darkGlyph: CGColor
}

func color(_ hex: UInt32) -> CGColor {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let components: [CGFloat] = [
        CGFloat((hex >> 16) & 0xFF) / 255,
        CGFloat((hex >> 8) & 0xFF) / 255,
        CGFloat(hex & 0xFF) / 255,
        1,
    ]
    return CGColor(colorSpace: colorSpace, components: components)!
}

/// The families of node-model-internals.md, trap 10. Stroke colours of the
/// green and graphite families come from the existing PDFs; the others are
/// the fill darkened the same way.
let families: [String: IconFamily] = [
    "green": IconFamily(fill: color(0x45BB6D), stroke: color(0x379D5A), darkGlyph: color(0x002D0F)),
    "blue": IconFamily(fill: color(0x4A90E2), stroke: color(0x3B76BA), darkGlyph: color(0x042142)),
    "pink": IconFamily(fill: color(0xF95493), stroke: color(0xCC4579), darkGlyph: color(0x3D0A1E)),
    "orange": IconFamily(fill: color(0xE19517), stroke: color(0xB97A13), darkGlyph: color(0x382300)),
    "graphite": IconFamily(fill: color(0x77808F), stroke: color(0x5F6875), darkGlyph: color(0x14171C)),
]

/// Opacity of the secondary parts of a glyph, as the existing icons use.
let secondaryAlpha: CGFloat = 0.5

struct Icon {
    let name: String
    let family: String
    /// Draws the glyph; `glyph` is the colour for the appearance.
    let draw: (CGContext, CGColor) -> Void
}

func fill(_ context: CGContext, _ rect: CGRect, radius: CGFloat = 0.6, color: CGColor, alpha: CGFloat = 1) {
    context.saveGState()
    context.setAlpha(alpha)
    context.setFillColor(color)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
    context.restoreGState()
}

func stroke(_ context: CGContext, _ points: [CGPoint], width: CGFloat = 1.4, color: CGColor, alpha: CGFloat = 1) {
    context.saveGState()
    context.setAlpha(alpha)
    context.setStrokeColor(color)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addLines(between: points)
    context.strokePath()
    context.restoreGState()
}

func dot(_ context: CGContext, center: CGPoint, radius: CGFloat, color: CGColor, alpha: CGFloat = 1) {
    context.saveGState()
    context.setAlpha(alpha)
    context.setFillColor(color)
    context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    context.restoreGState()
}

let icons: [Icon] = [
    // UIView, NSView: a frame with content inside.
    Icon(name: "view", family: "orange") { context, glyph in
        context.saveGState()
        context.setStrokeColor(glyph)
        context.setLineWidth(1.4)
        context.addPath(CGPath(roundedRect: CGRect(x: 3, y: 3, width: 9, height: 9), cornerWidth: 1, cornerHeight: 1, transform: nil))
        context.strokePath()
        context.restoreGState()
        fill(context, CGRect(x: 5.4, y: 5.4, width: 4.2, height: 4.2), color: glyph, alpha: secondaryAlpha)
    },
    // UISearchBar, UISearchTextField, NSSearchField: a field with a magnifier.
    Icon(name: "searchfield", family: "green") { context, glyph in
        fill(context, CGRect(x: 2.1, y: 4.6, width: 10.8, height: 5.8), radius: 2.9, color: glyph, alpha: secondaryAlpha)
        context.saveGState()
        context.setStrokeColor(glyph)
        context.setLineWidth(1.1)
        context.strokeEllipse(in: CGRect(x: 3.7, y: 6.2, width: 2.6, height: 2.6))
        context.restoreGState()
        stroke(context, [CGPoint(x: 6.1, y: 6.4), CGPoint(x: 7.0, y: 5.5)], width: 1.1, color: glyph)
    },
    // UIPageControl: three dots, the current one opaque.
    Icon(name: "pagecontrol", family: "green") { context, glyph in
        dot(context, center: CGPoint(x: 4, y: 7.5), radius: 1.3, color: glyph, alpha: secondaryAlpha)
        dot(context, center: CGPoint(x: 7.5, y: 7.5), radius: 1.3, color: glyph)
        dot(context, center: CGPoint(x: 11, y: 7.5), radius: 1.3, color: glyph, alpha: secondaryAlpha)
    },
    // UIPickerView: rows around a selected one.
    Icon(name: "picker", family: "green") { context, glyph in
        fill(context, CGRect(x: 3.6, y: 10.2, width: 7.8, height: 1.4), color: glyph, alpha: secondaryAlpha)
        fill(context, CGRect(x: 2.1, y: 6.4, width: 10.8, height: 2.2), color: glyph)
        fill(context, CGRect(x: 3.6, y: 3.4, width: 7.8, height: 1.4), color: glyph, alpha: secondaryAlpha)
    },
    // UINavigationBar: a bar across the top of the content.
    Icon(name: "navigationbar", family: "graphite") { context, glyph in
        fill(context, CGRect(x: 2.1, y: 9.4, width: 10.8, height: 3), color: glyph)
        fill(context, CGRect(x: 2.1, y: 2.6, width: 10.8, height: 5.6), color: glyph, alpha: secondaryAlpha)
    },
    // UITabBar: three tabs along the bottom.
    Icon(name: "tabbar", family: "graphite") { context, glyph in
        fill(context, CGRect(x: 2.1, y: 6.8, width: 10.8, height: 5.6), color: glyph, alpha: secondaryAlpha)
        for originX in [2.1, 5.9, 9.7] as [CGFloat] {
            fill(context, CGRect(x: originX, y: 2.6, width: 3.2, height: 3), color: glyph)
        }
    },
    // UIToolbar, NSToolbar: items in a bar across the top.
    Icon(name: "toolbar", family: "graphite") { context, glyph in
        for originX in [2.1, 5.9, 9.7] as [CGFloat] {
            fill(context, CGRect(x: originX, y: 9.4, width: 3.2, height: 3), color: glyph)
        }
        fill(context, CGRect(x: 2.1, y: 2.6, width: 10.8, height: 5.6), color: glyph, alpha: secondaryAlpha)
    },
    // NSBrowser: columns, the last one active.
    Icon(name: "browser", family: "blue") { context, glyph in
        fill(context, CGRect(x: 2.1, y: 2.6, width: 3, height: 9.8), color: glyph, alpha: secondaryAlpha)
        fill(context, CGRect(x: 6, y: 2.6, width: 3, height: 9.8), color: glyph, alpha: secondaryAlpha)
        fill(context, CGRect(x: 9.9, y: 2.6, width: 3, height: 9.8), color: glyph)
    },
    // NSPathControl: path components separated by chevrons.
    Icon(name: "pathcontrol", family: "green") { context, glyph in
        stroke(context, [CGPoint(x: 3.2, y: 10), CGPoint(x: 5.7, y: 7.5), CGPoint(x: 3.2, y: 5)], color: glyph, alpha: secondaryAlpha)
        stroke(context, [CGPoint(x: 7.4, y: 10), CGPoint(x: 9.9, y: 7.5), CGPoint(x: 7.4, y: 5)], color: glyph)
        dot(context, center: CGPoint(x: 12.2, y: 7.5), radius: 0.8, color: glyph)
    },
    // NSRuleEditor, NSPredicateEditor: rows of criteria.
    Icon(name: "ruleeditor", family: "green") { context, glyph in
        dot(context, center: CGPoint(x: 3.6, y: 10), radius: 1.2, color: glyph)
        fill(context, CGRect(x: 6, y: 9.3, width: 6.9, height: 1.4), color: glyph, alpha: secondaryAlpha)
        dot(context, center: CGPoint(x: 3.6, y: 5), radius: 1.2, color: glyph)
        fill(context, CGRect(x: 6, y: 4.3, width: 6.9, height: 1.4), color: glyph, alpha: secondaryAlpha)
    },
    // NSRulerView: a ruler with ticks.
    Icon(name: "ruler", family: "orange") { context, glyph in
        fill(context, CGRect(x: 2.1, y: 4.4, width: 10.8, height: 6.2), color: glyph, alpha: secondaryAlpha)
        for (index, originX) in ([3.6, 5.6, 7.5, 9.4, 11.4] as [CGFloat]).enumerated() {
            let height: CGFloat = index % 2 == 0 ? 3.6 : 2.2
            stroke(context, [CGPoint(x: originX, y: 10.6), CGPoint(x: originX, y: 10.6 - height)], width: 1, color: glyph)
        }
    },
]

func pdfData(for icon: Icon, family: IconFamily, glyph: CGColor) -> Data {
    let data = NSMutableData()
    var mediaBox = CGRect(x: 0, y: 0, width: 15, height: 15)
    guard let consumer = CGDataConsumer(data: data as CFMutableData),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
    else {
        fatalError("cannot create a PDF context")
    }
    context.beginPDFPage(nil)
    let canvas = CGRect(x: 0, y: 0, width: 15, height: 15)
    let square = CGPath(roundedRect: canvas, cornerWidth: 1, cornerHeight: 1, transform: nil)
    context.saveGState()
    context.clip(to: canvas)
    context.setFillColor(family.fill)
    context.addPath(square)
    context.fillPath()
    context.setLineWidth(2)
    context.setStrokeColor(family.stroke)
    context.addPath(square)
    context.strokePath()
    context.restoreGState()
    context.saveGState()
    context.clip(to: canvas)
    icon.draw(context, glyph)
    context.restoreGState()
    context.endPDFPage()
    context.closePDF()
    return data as Data
}

func contentsJSON(for name: String) -> String {
    """
    {
      "images" : [
        {
          "idiom" : "universal",
          "filename" : "dashboard_\(name).pdf"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "idiom" : "universal",
          "filename" : "dashboard_\(name)_dark.pdf"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
}

let scriptDirectory = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let dashboardAssets = scriptDirectory.deletingLastPathComponent().appendingPathComponent("LookInside/Assets.xcassets/Dashboard")
let arguments = Array(CommandLine.arguments.dropFirst())
let forcesRedraw = arguments.contains("--force")
let requestedNames = Set(arguments.filter { !$0.hasPrefix("--") })

let unknownNames = requestedNames.subtracting(icons.map(\.name))
guard unknownNames.isEmpty else {
    FileHandle.standardError.write("unknown icons: \(unknownNames.sorted().joined(separator: ", "))\n".data(using: .utf8)!)
    exit(1)
}

var written: [String] = []
for icon in icons where requestedNames.isEmpty || requestedNames.contains(icon.name) {
    let imageSet = dashboardAssets.appendingPathComponent("dashboard_\(icon.name).imageset")
    if FileManager.default.fileExists(atPath: imageSet.path), !forcesRedraw, requestedNames.isEmpty {
        continue
    }
    guard let family = families[icon.family] else {
        fatalError("unknown family \(icon.family)")
    }
    try FileManager.default.createDirectory(at: imageSet, withIntermediateDirectories: true)
    let white = CGColor(gray: 1, alpha: 1)
    try pdfData(for: icon, family: family, glyph: white).write(to: imageSet.appendingPathComponent("dashboard_\(icon.name).pdf"))
    try pdfData(for: icon, family: family, glyph: family.darkGlyph).write(to: imageSet.appendingPathComponent("dashboard_\(icon.name)_dark.pdf"))
    try contentsJSON(for: icon.name).write(to: imageSet.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    written.append(icon.name)
}
print(written.isEmpty ? "every icon exists; pass --force to redraw" : "drew \(written.joined(separator: ", "))")
