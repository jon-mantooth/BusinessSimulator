//
//  CalendarView.swift
//  BusinessSimulator
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss

    let currentDate: Date

    private let calendar = Foundation.Calendar(identifier: .gregorian)
    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let gold = Color(red: 0.82, green: 0.54, blue: 0.20)
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthDates: [Date?] {
        guard
            let monthInterval = calendar.dateInterval(
                of: .month,
                for: currentDate
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: currentDate
            )
        else {
            return []
        }

        let firstDate = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDate)
        let leadingEmptyDays = firstWeekday - 1

        let dates = dayRange.compactMap { day in
            calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDate
            )
        }

        return Array(repeating: nil, count: leadingEmptyDays) + dates
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(
                    currentDate.formatted(
                        .dateTime.month(.wide).year()
                    )
                )
                .font(.system(.title, design: .serif))
                .fontWeight(.bold)
                .foregroundStyle(darkBrown)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(darkBrown.opacity(0.65))
                }
                .accessibilityLabel("Close calendar")
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 6),
                    count: 7
                ),
                spacing: 10
            ) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(darkBrown.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            // Reserved for a future special-events key.
            Color.clear
                .frame(height: 18)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.92),
                    Color(red: 1.0, green: 0.93, blue: 0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(gold.opacity(0.85), lineWidth: 2)
        }
        .padding(16)
    }

    private func dayCell(for date: Date) -> some View {
        let isCurrentDate = calendar.isDate(date, inSameDayAs: currentDate)
        let isWeekend = calendar.isDateInWeekend(date)

        return Text(calendar.component(.day, from: date).formatted())
            .font(.body)
            .fontWeight(isCurrentDate ? .bold : .regular)
            .foregroundStyle(
                isWeekend
                    ? darkBrown.opacity(0.38)
                    : darkBrown
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(isCurrentDate ? gold.opacity(0.18) : .clear)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(
                        isCurrentDate ? gold : .clear,
                        lineWidth: 2
                    )
            }
    }
}
