//
//  DateRangeExportView.swift
//  Claude Usage
//
//  Date range picker for exporting usage history (Pro feature).
//

import SwiftUI

struct DateRangeExportView: View {
    let profileId: UUID
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedFormat: UsageHistoryService.ExportFormat = .json
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Usage History")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                Text("Date Range")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("To")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $endDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }

                // Quick presets
                HStack(spacing: 8) {
                    ForEach([7, 14, 30, 90], id: \.self) { days in
                        Button("\(days)d") {
                            startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                            endDate = Date()
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Format")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedFormat) {
                    Text("JSON").tag(UsageHistoryService.ExportFormat.json)
                    Text("CSV").tag(UsageHistoryService.ExportFormat.csv)
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)

                Button("Export") {
                    export()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting || startDate > endDate)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func export() {
        isExporting = true
        UsageHistoryService.shared.exportToFile(
            for: profileId,
            format: selectedFormat,
            startDate: startDate,
            endDate: endDate
        )
        isExporting = false
        dismiss()
    }
}
