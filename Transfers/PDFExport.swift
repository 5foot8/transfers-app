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
        let colWidths: [CGFloat] = [60, 40, 60, 70, 40, 60, 60, 60, 60] // Incoming, Origin, In Time, Outgoing, Dest, Scheduled, Bags, Actual, Notes
        let colTitles = ["Incoming", "Origin", "In Time", "Outgoing", "Dest", "Scheduled", "Bags", "Actual", "Notes"]
        let font = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.boldSystemFont(ofSize: 11)
        let headerFont = UIFont.boldSystemFont(ofSize: 15)
        let dateFont = UIFont.boldSystemFont(ofSize: 13)
        let rowBackgroundColor = UIColor(white: 0.97, alpha: 1)
        let groupBackgroundColor = UIColor(white: 0.93, alpha: 1)
        let dateString = formatDate(reportDate)
        // --- Collect code-to-name mappings ---
        var codeToName: [String: String] = [:]
        func extractCodeAndName(_ s: String) -> (String, String) {
            // e.g. "DOHA (DOH)" -> ("DOH", "DOHA")
            if let open = s.lastIndex(of: "("), let close = s.lastIndex(of: ")"), open < close {
                let name = s[..<open].trimmingCharacters(in: .whitespaces)
                let code = s[s.index(after: open)..<close].trimmingCharacters(in: .whitespaces)
                return (String(code), String(name))
            } else if s.count == 3 {
                return (s, s)
            } else {
                return (s, s)
            }
        }
        // --- Airline prefix helper ---
        func airlinePrefix(_ flightNumber: String) -> String {
            let prefix = flightNumber.prefix { $0.isLetter }
            return prefix.isEmpty ? flightNumber : String(prefix)
        }
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format).pdfData { ctx in
            // --- SUMMARY PAGE ---
            ctx.beginPage()
            var y = margin
            let summaryTitle = "Transfer Summary for \(dateString)"
            summaryTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: headerFont])
            y += rowHeight * 1.3
            // Per-flight bag totals (in and out)
            "Flights (Arrivals):".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: boldFont])
            y += rowHeight
            for flight in incomingFlights.sorted(by: { $0.scheduledTime < $1.scheduledTime }) {
                let bagTotal = flight.outgoingLinks.reduce(0) { $0 + $1.bagCount }
                let line = "\(flight.flightNumber)  (\(formatTime(flight.scheduledTime)))  Bags: \(bagTotal)"
                line.draw(at: CGPoint(x: margin + 12, y: y), withAttributes: [.font: font])
                y += rowHeight * 0.9
            }
            y += rowHeight * 0.5
            "Flights (Departures):".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: boldFont])
            y += rowHeight
            for flight in outgoingFlights.filter({ !$0.bagsFromIncoming.isEmpty }).sorted(by: { $0.scheduledTime < $1.scheduledTime }) {
                let bagTotal = flight.bagsFromIncoming.values.reduce(0, +)
                let line = "\(flight.flightNumber)  (\(formatTime(flight.scheduledTime)))  Bags: \(bagTotal)"
                line.draw(at: CGPoint(x: margin + 12, y: y), withAttributes: [.font: font])
                y += rowHeight * 0.9
            }
            y += rowHeight * 0.7
            // Per-airline bag totals
            "Airline Totals (Arrivals):".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: boldFont])
            y += rowHeight
            let inAirlines = Dictionary(grouping: incomingFlights, by: { airlinePrefix($0.flightNumber) })
            for (prefix, flights) in inAirlines.sorted(by: { $0.key < $1.key }) {
                let bagTotal = flights.reduce(0) { $0 + $1.outgoingLinks.reduce(0) { $0 + $1.bagCount } }
                let line = "\(prefix): \(bagTotal) bags"
                line.draw(at: CGPoint(x: margin + 12, y: y), withAttributes: [.font: font])
                y += rowHeight * 0.9
            }
            y += rowHeight * 0.5
            "Airline Totals (Departures):".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: boldFont])
            y += rowHeight
            let outAirlines = Dictionary(grouping: outgoingFlights.filter { !$0.bagsFromIncoming.isEmpty }, by: { airlinePrefix($0.flightNumber) })
            for (prefix, flights) in outAirlines.sorted(by: { $0.key < $1.key }) {
                let bagTotal = flights.reduce(0) { $0 + $1.bagsFromIncoming.values.reduce(0, +) }
                let line = "\(prefix): \(bagTotal) bags"
                line.draw(at: CGPoint(x: margin + 12, y: y), withAttributes: [.font: font])
                y += rowHeight * 0.9
            }
            // --- END SUMMARY PAGE ---
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
                    let (originCode, originName) = extractCodeAndName(incoming.origin)
                    codeToName[originCode] = originName
                    let outgoingLinks = incoming.outgoingLinks.sorted { lhs, rhs in
                        let lhsFlight = outgoingFlights.first { $0.id == lhs.outgoingFlightID }
                        let rhsFlight = outgoingFlights.first { $0.id == rhs.outgoingFlightID }
                        return (lhsFlight?.scheduledTime ?? .distantFuture) < (rhsFlight?.scheduledTime ?? .distantFuture)
                    }
                    var groupRows: [[String]] = []
                    for (idx, link) in outgoingLinks.enumerated() {
                        guard let outgoing = outgoingFlights.first(where: { $0.id == link.outgoingFlightID }) else { continue }
                        let (destCode, destName) = extractCodeAndName(outgoing.destination)
                        codeToName[destCode] = destName
                        groupRows.append([
                            idx == 0 ? incoming.flightNumber : "",
                            idx == 0 ? originCode : "",
                            idx == 0 ? incomingTime : "",
                            outgoing.flightNumber,
                            destCode,
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
            // --- Draw the key/legend at the end ---
            ctx.beginPage()
            var legendY = margin
            let legendTitle = "IATA Code Key"
            legendTitle.draw(at: CGPoint(x: margin, y: legendY), withAttributes: [.font: headerFont])
            legendY += rowHeight * 1.3
            let sortedCodes = codeToName.keys.sorted()
            for code in sortedCodes {
                let name = codeToName[code] ?? ""
                let legendLine = "\(code) = \(name)"
                legendLine.draw(at: CGPoint(x: margin, y: legendY), withAttributes: [.font: font])
                legendY += rowHeight * 0.9
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