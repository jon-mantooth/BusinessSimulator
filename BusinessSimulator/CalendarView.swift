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

    private var backgroundImageName: String {
        let monthNames = [
            "january",
            "february",
            "march",
            "april",
            "may",
            "june",
            "july",
            "august",
            "september",
            "october",
            "november",
            "december"
        ]
        let month = calendar.component(.month, from: currentDate)
        return monthNames[month - 1]
    }

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
        GeometryReader { geometry in
            let calendarWidth = geometry.size.width
            let calendarHeight = calendarWidth * 1.5

            ZStack(alignment: .topTrailing) {
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: calendarWidth,
                        height: calendarHeight
                    )

                VStack(alignment: .leading, spacing: 10) {
                    Text(
                        currentDate.formatted(
                            .dateTime.month(.wide).year()
                        )
                    )
                    .font(
                        .system(
                            size: calendarWidth * 0.075,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .foregroundStyle(darkBrown)

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 4),
                            count: 7
                        ),
                        spacing: 5
                    ) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(darkBrown.opacity(0.58))
                                .frame(maxWidth: .infinity)
                        }

                        ForEach(
                            Array(monthDates.enumerated()),
                            id: \.offset
                        ) { _, date in
                            if let date {
                                dayCell(for: date)
                            } else {
                                Color.clear
                                    .frame(height: 32)
                            }
                        }
                    }
                }
                .frame(
                    width: calendarWidth * 0.84,
                    alignment: .topLeading
                )
                .padding(.top, calendarHeight * 0.51)
                .padding(.horizontal, calendarWidth * 0.08)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
                .padding(20)
                .accessibilityLabel("Close calendar")
            }
            .frame(width: calendarWidth, height: calendarHeight)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
        }
        .ignoresSafeArea()
    }

    private func dayCell(for date: Date) -> some View {
        let isCurrentDate = calendar.isDate(date, inSameDayAs: currentDate)
        let isWeekend = calendar.isDateInWeekend(date)

        return Text(calendar.component(.day, from: date).formatted())
            .font(.system(size: 17, design: .serif))
            .fontWeight(isCurrentDate ? .bold : .regular)
            .foregroundStyle(
                isWeekend
                    ? darkBrown.opacity(0.38)
                    : darkBrown
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 32)
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
