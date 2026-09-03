import AppKit
import Foundation

// Local A4-landscape RTL expense-report renderer.
// Usage: swift generate_expense_report.swift <month> <total> <created-date>
//   <operations.tsv> <output.pdf>
// TSV columns: date, category, supplier, Hebrew description, amount.
guard CommandLine.arguments.count == 6 else {
    fputs("Usage: generate_expense_report.swift <month> <total> <created-date> <operations.tsv> <output.pdf>\n", stderr)
    exit(2)
}

let values = Array(CommandLine.arguments.dropFirst())
let month = values[0], total = values[1], createdDate = values[2]
let operationsURL = URL(fileURLWithPath: values[3])
let outputURL = URL(fileURLWithPath: values[4])
let operations = try String(contentsOf: operationsURL, encoding: .utf8)
    .split(whereSeparator: \.isNewline)
    .compactMap { line -> [String]? in
        let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        return fields.count == 5 ? fields : nil
    }
guard !operations.isEmpty else { fatalError("No operations in TSV") }
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
    ("מספר פעולות", "\(operations.count)", 554)
]
for (label, value, x) in cards {
    rounded(CGRect(x: x, y: 390, width: 245, height: 53), 8, pale)
    border.setStroke(); NSBezierPath(roundedRect: CGRect(x: x, y: 390, width: 245, height: 53), xRadius: 8, yRadius: 8).stroke()
    text(label, CGRect(x: x + 15, y: 423, width: 215, height: 14), attributes(10.5, soft, alignment: .center))
    text(value, CGRect(x: x + 15, y: 398, width: 215, height: 24), attributes(20, green, bold: true, alignment: .center))
}

// Physical left-to-right layout; users read the columns right-to-left.
// These widths must add up to the full table width (758 pt).  Keeping the
// description column flexible prevents the header and data row from ending at
// different horizontal positions.
let columns: [(String, CGFloat)] = [("סכום", 78), ("סטטוס", 64), ("קבלה", 62), ("תיאור", 262), ("ספק", 82), ("קטגוריה", 88), ("תאריך", 88), ("#", 34)]
let tableX: CGFloat = 42, headerY: CGFloat = 342, headerH: CGFloat = 30, rowH: CGFloat = 38
var x = tableX
green.setFill()
for (_, width) in columns { NSBezierPath(rect: CGRect(x: x, y: headerY, width: width, height: headerH)).fill(); x += width }
x = tableX
for (title, width) in columns {
    text(title, CGRect(x: x + 5, y: headerY + 8, width: width - 10, height: 14), attributes(9.5, .white, bold: true))
    x += width
}

for (operationIndex, operation) in operations.enumerated() {
    let rowY = headerY - CGFloat(operationIndex + 1) * rowH
    NSColor(calibratedRed: 0.99, green: 1, blue: 0.995, alpha: 1).setFill(); NSBezierPath(rect: CGRect(x: tableX, y: rowY, width: 758, height: rowH)).fill()
    let row = ["₪ \(operation[4])", "", "קיימת", operation[3], operation[2], operation[1], operation[0], "\(operationIndex + 1)"]
    x = tableX
    for (index, (_, width)) in columns.enumerated() {
        if index == 1 {
            rounded(CGRect(x: x + 7, y: rowY + 10, width: width - 14, height: 18), 9, NSColor(calibratedRed: 0.90, green: 0.97, blue: 0.94, alpha: 1))
            text("מאושר", CGRect(x: x + 7, y: rowY + 13, width: width - 14, height: 12), attributes(8.2, green, bold: true, alignment: .center))
        } else {
            text(row[index], CGRect(x: x + 4, y: rowY + 9, width: width - 8, height: 22), attributes(index == 3 ? 7.8 : 8.5, ink, bold: index == 0))
        }
        x += width
    }
    border.setStroke(); NSBezierPath(rect: CGRect(x: tableX, y: rowY, width: 758, height: rowH)).stroke()
}

rounded(CGRect(x: 42, y: 58, width: 758, height: 50), 7, pale)
text("כל הסכומים מוצגים בשקלים חדשים. הקבלות שמורות אצל ועד הבית לצורכי מעקב ובקרה.", CGRect(x: 60, y: 76, width: 720, height: 18), attributes(12, soft))
text("נוצר בתאריך \(createdDate)", CGRect(x: 42, y: 24, width: 758, height: 16), attributes(10, soft))

NSGraphicsContext.restoreGraphicsState(); pdf.endPDFPage(); pdf.closePDF()
