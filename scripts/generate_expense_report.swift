import AppKit
import Foundation

// Local A4-landscape RTL expense-report renderer.
// Usage: swift generate_expense_report.swift <month> <total> <date> <category>
//   <supplier> <description> <amount> <created-date> <output.pdf>
guard CommandLine.arguments.count == 10 else {
    fputs("Usage: generate_expense_report.swift <month> <total> <date> <category> <supplier> <description> <amount> <created-date> <output.pdf>\n", stderr)
    exit(2)
}

let values = Array(CommandLine.arguments.dropFirst())
let month = values[0], total = values[1], date = values[2], category = values[3]
let supplier = values[4], description = values[5], amount = values[6], createdDate = values[7]
let outputURL = URL(fileURLWithPath: values[8])
let page = CGRect(x: 0, y: 0, width: 842, height: 595)

func attributes(_ size: CGFloat, _ color: NSColor, bold: Bool = false, alignment: NSTextAlignment = .right) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.baseWritingDirection = .rightToLeft
    return [
        .font: NSFont(name: bold ? "Arial-BoldMT" : "ArialMT", size: size) ?? NSFont.systemFont(ofSize: size),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
}

func text(_ value: String, _ rect: CGRect, _ attrs: [NSAttributedString.Key: Any]) {
    (attrs[.foregroundColor] as? NSColor)?.set()
    NSAttributedString(string: value, attributes: attrs).draw(in: rect)
}

func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

var mediaBox = page
guard let pdf = CGContext(outputURL as CFURL, mediaBox: &mediaBox, nil) else { fatalError("Cannot create PDF") }
pdf.beginPDFPage(nil)
let graphics = NSGraphicsContext(cgContext: pdf, flipped: false)
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = graphics
NSColor.white.setFill(); NSBezierPath(rect: page).fill()

let ink = NSColor(calibratedRed: 0.12, green: 0.17, blue: 0.22, alpha: 1)
let green = NSColor(calibratedRed: 0.08, green: 0.34, blue: 0.30, alpha: 1)
let pale = NSColor(calibratedRed: 0.96, green: 0.98, blue: 0.97, alpha: 1)
let soft = NSColor(calibratedRed: 0.43, green: 0.49, blue: 0.54, alpha: 1)
let border = NSColor(calibratedRed: 0.84, green: 0.89, blue: 0.87, alpha: 1)

green.setFill(); NSBezierPath(rect: CGRect(x: 42, y: 554, width: 758, height: 4)).fill()
text("ועד הבית", CGRect(x: 42, y: 524, width: 758, height: 18), attributes(12, green, bold: true))
text("דו״ח הוצאות לחודש \(month)", CGRect(x: 42, y: 485, width: 758, height: 37), attributes(29, ink, bold: true))
text("סיכום הוצאות מאושרות לפי רישומי ועד הבית", CGRect(x: 42, y: 460, width: 758, height: 20), attributes(13, soft))

let cards: [(String, String, CGFloat)] = [
    ("סה״כ הוצאות", "₪ \(total)", 42),
    ("הוצאות מאושרות", "₪ \(total)", 298),
    ("מספר פעולות", "1", 554)
]
for (label, value, x) in cards {
    rounded(CGRect(x: x, y: 360, width: 245, height: 83), 8, pale)
    border.setStroke(); NSBezierPath(roundedRect: CGRect(x: x, y: 360, width: 245, height: 83), xRadius: 8, yRadius: 8).stroke()
    text(label, CGRect(x: x + 15, y: 412, width: 215, height: 18), attributes(12, soft, alignment: .center))
    text(value, CGRect(x: x + 15, y: 378, width: 215, height: 30), attributes(25, green, bold: true, alignment: .center))
}

// Physical left-to-right layout; users read the columns right-to-left.
// These widths must add up to the full table width (758 pt).  Keeping the
// description column flexible prevents the header and data row from ending at
// different horizontal positions.
let columns: [(String, CGFloat)] = [("סכום", 78), ("סטטוס", 64), ("קבלה", 62), ("תיאור", 262), ("ספק", 82), ("קטגוריה", 88), ("תאריך", 88), ("#", 34)]
let tableX: CGFloat = 42, headerY: CGFloat = 292, headerH: CGFloat = 34, rowH: CGFloat = 58
var x = tableX
green.setFill()
for (_, width) in columns { NSBezierPath(rect: CGRect(x: x, y: headerY, width: width, height: headerH)).fill(); x += width }
x = tableX
for (title, width) in columns {
    text(title, CGRect(x: x + 5, y: headerY + 10, width: width - 10, height: 15), attributes(10.5, .white, bold: true))
    x += width
}

let rowY = headerY - rowH
NSColor(calibratedRed: 0.99, green: 1, blue: 0.995, alpha: 1).setFill(); NSBezierPath(rect: CGRect(x: tableX, y: rowY, width: 758, height: rowH)).fill()
let row = ["₪ \(amount)", "", "קיימת", description, supplier, category, date, "1"]
x = tableX
for (index, (_, width)) in columns.enumerated() {
    if index == 1 {
        rounded(CGRect(x: x + 8, y: rowY + 18, width: width - 16, height: 22), 10, NSColor(calibratedRed: 0.90, green: 0.97, blue: 0.94, alpha: 1))
        text("מאושר", CGRect(x: x + 8, y: rowY + 22, width: width - 16, height: 14), attributes(9.5, green, bold: true, alignment: .center))
    } else {
        text(row[index], CGRect(x: x + 5, y: rowY + 22, width: width - 10, height: 16), attributes(10.5, ink, bold: index == 0))
    }
    x += width
}
border.setStroke(); NSBezierPath(rect: CGRect(x: tableX, y: rowY, width: 758, height: rowH)).stroke()

rounded(CGRect(x: 42, y: 104, width: 758, height: 52), 7, pale)
text("כל הסכומים מוצגים בשקלים חדשים. הקבלות שמורות אצל ועד הבית לצורכי מעקב ובקרה.", CGRect(x: 60, y: 123, width: 720, height: 18), attributes(12, soft))
text("נוצר בתאריך \(createdDate)", CGRect(x: 42, y: 51, width: 758, height: 16), attributes(10, soft))

NSGraphicsContext.restoreGraphicsState(); pdf.endPDFPage(); pdf.closePDF()
