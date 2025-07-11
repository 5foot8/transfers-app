import Foundation
import PDFKit
import SwiftUI

struct TransferPDFExporter {
    static func generatePDF(incomingFlights: [IncomingFlight], outgoingFlights: [OutgoingFlight], reportDate: Date) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Transfers App",
            kCGPDFContextAuthor: "Manchester Airport Transfer Team"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        // A4 size: 210mm x 297mm = 595 x 842 points
        let pageWidth: CGFloat = 595.0
        let pageHeight: CGFloat = 842.0
        let margin: CGFloat = 40
        let rowHeight: CGFloat = 22
        let colWidths: [CGFloat] = [60, 60, 60, 70, 70, 60, 60, 60, 60] // Incoming, Origin, In Time, Outgoing, Dest, Scheduled, Bags, Actual, Notes
        let colTitles = ["Incoming", "Origin", "In Time", "Outgoing", "Dest", "Scheduled", "Bags", "Actual", "Notes"]
        let font = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.boldSystemFont(ofSize: 11)
        let headerFont = UIFont.boldSystemFont(ofSize: 15)
        let dateFont = UIFont.boldSystemFont(ofSize: 13)
        let rowBackgroundColor = UIColor(white: 0.97, alpha: 1)
        let groupBackgroundColor = UIColor(white: 0.93, alpha: 1)
        let dateString = formatDate(reportDate)
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format).pdfData { ctx in
            for terminal in Array(Set(incomingFlights.map { $0.terminal })).sorted() {
                ctx.beginPage()
                let context = ctx.cgContext
                var y = margin
                // Date and terminal header (once per section)
                let dateHeader = "Transfers for \(dateString)"
                dateHeader.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: dateFont])
                y += rowHeight * 1.1
                let terminalHeader = "Terminal \(terminal)"
                terminalHeader.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: headerFont])
                y += rowHeight * 1.3
                // Table header (once)
                var x = margin
                for (i, title) in colTitles.enumerated() {
                    title.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: boldFont, .foregroundColor: UIColor.darkGray])
                    x += colWidths[i]
                }
                y += rowHeight
                // Gather all rows for this terminal, grouped by incoming
                var allGroups: [[[String]]] = []
                for incoming in incomingFlights.filter({ $0.terminal == terminal }) {
                    let incomingTime = formatTime(incoming.scheduledTime)
                    let outgoingLinks = incoming.outgoingLinks.sorted { lhs, rhs in
                        let lhsFlight = outgoingFlights.first { $0.id == lhs.outgoingFlightID }
                        let rhsFlight = outgoingFlights.first { $0.id == rhs.outgoingFlightID }
                        return (lhsFlight?.scheduledTime ?? .distantFuture) < (rhsFlight?.scheduledTime ?? .distantFuture)
                    }
                    var groupRows: [[String]] = []
                    for (idx, link) in outgoingLinks.enumerated() {
                        guard let outgoing = outgoingFlights.first(where: { $0.id == link.outgoingFlightID }) else { continue }
                        groupRows.append([
                            idx == 0 ? incoming.flightNumber : "",
                            idx == 0 ? incoming.origin : "",
                            idx == 0 ? incomingTime : "",
                            outgoing.flightNumber,
                            outgoing.destination,
                            formatTime(outgoing.scheduledTime),
                            "\(link.bagCount)",
                            "", // Actual Bags Received (blank)
                            ""
                        ])
                    }
                    if !groupRows.isEmpty {
                        allGroups.append(groupRows)
                    }
                }
                // Draw all rows, alternating background per group
                var rowIdx = 0
                for (groupIdx, groupRows) in allGroups.enumerated() {
                    let bgColor = groupIdx % 2 == 0 ? rowBackgroundColor : groupBackgroundColor
                    for row in groupRows {
                        x = margin
                        // Group background
                        context.setFillColor(bgColor.cgColor)
                        context.fill(CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: rowHeight))
                        for (i, value) in row.enumerated() {
                            value.draw(at: CGPoint(x: x + 2, y: y + 4), withAttributes: [.font: font, .foregroundColor: UIColor.black])
                            x += colWidths[i]
                        }
                        // Draw thin rule below row
                        context.setStrokeColor(UIColor.lightGray.cgColor)
                        context.setLineWidth(0.5)
                        context.move(to: CGPoint(x: margin, y: y + rowHeight - 1))
                        context.addLine(to: CGPoint(x: pageWidth - margin, y: y + rowHeight - 1))
                        context.strokePath()
                        y += rowHeight
                        rowIdx += 1
                        if y > pageHeight - margin * 2 {
                            ctx.beginPage()
                            y = margin
                            // Repeat only the table header on new page
                            var x2 = margin
                            for (i, title) in colTitles.enumerated() {
                                title.draw(at: CGPoint(x: x2, y: y), withAttributes: [.font: boldFont, .foregroundColor: UIColor.darkGray])
                                x2 += colWidths[i]
                            }
                            y += rowHeight
                        }
                    }
                }
            }
        }
        return data
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 