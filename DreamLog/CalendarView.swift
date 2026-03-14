//
//  CalendarView.swift
//  DreamLog
//
//  日历视图 - 按日期查看梦境
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedDate: Date = Date()
    @State private var showingMonthView = false
    
    var dreamsOnSelectedDate: [Dream] {
        dreamStore.dreams.filter { dream in
            Calendar.current.isDate(dream.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日历头部
                    CalendarHeader(
                        selectedDate: $selectedDate,
                        showingMonthView: $showingMonthView
                    )
                    
                    // 日历网格
                    CalendarGrid(
                        selectedDate: $selectedDate,
                        dreams: dreamStore.dreams
                    )
                    .padding(.horizontal)
                    
                    // 当日梦境
                    DreamsOnDateSection(
                        date: selectedDate,
                        dreams: dreamsOnSelectedDate
                    )
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("梦境日历 📅")
            .sheet(isPresented: $showingMonthView) {
                MonthPickerView(
                    selectedDate: $selectedDate,
                    dreams: dreamStore.dreams
                )
            }
        }
    }
}

// MARK: - 日历头部
struct CalendarHeader: View {
    @Binding var selectedDate: Date
    @Binding var showingMonthView: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("上个月")
            .accessibilityHint("双击查看上一个月的梦境")
            
            Spacer()
            
            Button(action: { showingMonthView = true }) {
                VStack(spacing: 4) {
                    Text(selectedDate, style: .date)
                        .font(.headline)
                        .foregroundColor(.white)
                        .accessibilityLabel("当前选择：\(selectedDate, style: .date)")
                    
                    Text("点击查看月份")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityHint("双击选择月份")
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? Date()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("下个月")
            .accessibilityHint("双击查看下一个月的梦境")
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("日历导航")
    }
}

// MARK: - 日历网格
struct CalendarGrid: View {
    @Binding var selectedDate: Date
    let dreams: [Dream]
    
    let calendar = Calendar.current
    let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        guard let startComponents = calendar.dateComponents([.year, .month, .weekday], from: monthInterval.start) else { return [] }
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate) else { return [] }
        
        var days: [Date] = []
        
        // 添加前置空白
        let firstWeekday = startComponents.weekday ?? 1
        for _ in 0..<firstWeekday - 1 {
            days.append(Date.distantPast)
        }
        
        // 添加日期
        for day in daysInMonth {
            if let date = calendar.date(from: DateComponents(year: startComponents.year, month: startComponents.month, day: day)) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 星期标题
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    if date == Date.distantPast {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            dreamCount: dreams.filter { calendar.isDate($0.date, inSameDayAs: date) }.count,
                            hasLucidDream: dreams.contains { calendar.isDate($0.date, inSameDayAs: date) && $0.isLucid }
                        ) {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 日历日期单元格
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let dreamCount: Int
    let hasLucidDream: Bool
    let action: () -> Void
    
    let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                if dreamCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(dreamCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(hasLucidDream ? Color.yellow : Color.accentColor)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .accessibilityLabel("\(dreamCount)个梦境\(hasLucidDream ? "，包含清醒梦" : "")")
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .background(
                Group {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                    } else {
                        Circle()
                            .fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(calendar.component(.day, from: date))日，\(dreamCount > 0 ? "\(dreamCount)个梦境" : "无梦境")")
        .accessibilityHint(isSelected ? "已选择" : "双击选择此日期")
    }
}

// MARK: - 当日梦境
struct DreamsOnDateSection: View {
    let date: Date
    let dreams: [Dream]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("当天的梦境")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !dreams.isEmpty {
                    Text("\(dreams.count)个梦")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if dreams.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("这天还没有记录梦境")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("记得醒来后快速记录哦")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            } else {
                ForEach(dreams, id: \.id) { dream in
                    MiniDreamCard(dream: dream)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

// MARK: - 迷你梦境卡片
struct MiniDreamCard: View {
    let dream: Dream
    
    var body: some View {
        NavigationLink(destination: DreamDetailView(dream: dream)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dream.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if dream.isLucid {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(dream.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(Array(dream.emotions.prefix(2)), id: \.self) { emotion in
                        Text(emotion.icon)
                            .font(.caption)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 月份选择器
struct MonthPickerView: View {
    @Binding var selectedDate: Date
    let dreams: [Dream]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<12, id: \.self) { monthOffset in
                        if let monthDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: Date()) {
                            MiniMonthCalendar(
                                monthDate: monthDate,
                                selectedDate: $selectedDate,
                                dreams: dreams
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择月份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 迷你月份日历
struct MiniMonthCalendar: View {
    let monthDate: Date
    @Binding var selectedDate: Date
    let dreams: [Dream]
    
    let calendar = Calendar.current
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: monthDate)
    }
    
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { return [] }
        guard let startComponents = calendar.dateComponents([.year, .month, .weekday], from: monthInterval.start) else { return [] }
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate) else { return [] }
        
        var days: [Date] = []
        
        let firstWeekday = startComponents.weekday ?? 1
        for _ in 0..<firstWeekday - 1 {
            days.append(Date.distantPast)
        }
        
        for day in daysInMonth {
            if let date = calendar.date(from: DateComponents(year: startComponents.year, month: startComponents.month, day: day)) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(monthName)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(daysInMonth, id: \.self) { date in
                    if date == Date.distantPast {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        let dreamCount = dreams.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
                        let hasLucid = dreams.contains { calendar.isDate($0.date, inSameDayAs: date) && $0.isLucid }
                        
                        Circle()
                            .fill(dreamCount > 0 ? (hasLucid ? Color.yellow.opacity(0.6) : Color.accentColor.opacity(0.6)) : Color.clear)
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    CalendarView()
        .environmentObject(DreamStore())
}
