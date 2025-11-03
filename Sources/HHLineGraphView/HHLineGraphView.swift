// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

struct GraphValue {
    static let ValueMaxCount = 20
    var value: Double
    var label: String?
}


struct HHLineGraphView: View {

    private let kPaddingHorizontal:CGFloat = 25
    private let kPaddingVertical:CGFloat = 20
    private let kValueMaxCount = GraphValue.ValueMaxCount
    let graphHeight: CGFloat
    let padding: EdgeInsets
    private var values: [GraphValue] = []
    
    init(values: [GraphValue],
         graphHeight: CGFloat = 240,
         pading: EdgeInsets = .init(top: 20, leading: 25, bottom: 20, trailing: 25)) {
        self.values = Array(values.suffix(kValueMaxCount))
        self.graphHeight = max(240, graphHeight)
        self.padding = pading
    }
    
    var body: some View {
        ZStack {
            GeometryReader { reader in
                Graph(data: self.values,
                      frame: CGRect(
                        x: 0, y: 0,
                        width: reader.frame(in: .local).width,
                        height: reader.frame(in: .local).height)
                ).offset(x: 0, y: 0)
            }.frame(height: graphHeight)
        }
        .padding(padding)
    }
    
}

struct Graph: View {
    let data: [GraphValue]
    let frame: CGRect
    let peakDotColor: Color
    let lineColor: Color
    let fillColors: [Color]
    
    init(data: [GraphValue], frame: CGRect, peakDotColor: Color = Color(.systemPink), lineColor: Color =  Color(.systemPink), fillColors: [Color] = [Color(.systemPink).opacity(0.56), Color(.systemPink).opacity(0.3)]) {
        self.data = data
        self.frame = frame
        self.peakDotColor = peakDotColor
        self.lineColor = lineColor
        self.fillColors = fillColors
    }
    
    private let kLabelValueWidth: CGFloat = 30
    private let kLabelHeight: CGFloat = 40
    private let kLeadingDotMargin: CGFloat = 20
    private var stepWidth: CGFloat {
        if data.count < 2 {
            return frame.size.width - kLabelValueWidth - kLeadingDotMargin
        }
        return (frame.size.width - kLabelValueWidth - kLeadingDotMargin) / CGFloat(data.count - 1)
    }
    
    struct HeightInfo {
        let stepHeight: CGFloat
        let stepValue: Double
        let count: Int
        let lowerValue: Double
        let higerValue: Double
        
        init(_ height: CGFloat, stepValue: Double, count: Int,
             lower: Double, higer: Double) {
            self.stepHeight = height
            self.stepValue = stepValue
            self.count = count
            self.lowerValue = lower
            self.higerValue = higer
        }
    }
    
    private var matrixHeight: CGFloat {
        return frame.size.height - kLabelHeight
    }
    
    var body: some View {
        self.chart.frame(minWidth: 100, minHeight: 100)
    }
    
    /// 등고선 단위 계산
    /// - Returns: (등고선 단위 높이 point, 단위 value, 등고선 갯수)
    private func calculateStepHeightAndValue(values: [Double]) -> HeightInfo {
        var min: Double
        var max: Double
        if let minValue = values.min(), let maxValue = values.max() {
            if minValue != maxValue {
                min = minValue
                max = maxValue
            } else {
                min = maxValue
                max = maxValue
            }
        } else {
            return HeightInfo(0, stepValue: 0, count: 0, lower: 0, higer: 0)
        }
        let minValue = Double(Int(min - 0.5))
        var maxValue = Double(Int(max + 1.5))
        let matrixHeight = self.matrixHeight
        let stepHeight = matrixHeight / CGFloat(maxValue - minValue)
        var stepCount = Int(matrixHeight / stepHeight)// + 2 // 위아래 한단계씩 여유를 두고
        var stepValue = (max - min) / Double(stepCount)
        // stepCount 정정
        if stepValue < 1 || stepCount < 2 {
            stepCount = Int(max - min + 0.5) + 2
        }
        if stepCount < 5 {
            stepCount = 5
        } else if stepCount > 10 {
            stepCount = 10
        }
        // stepValue 를 정수로 변경
        stepValue = ((maxValue - minValue) / Double(stepCount) + 0.5).nearInt().toDouble()
        // maxValue 바로 잡음
        maxValue = minValue + (stepValue * Double(stepCount))
        return HeightInfo(matrixHeight / CGFloat(stepCount),
                        stepValue: stepValue,
                        count: stepCount,
                        lower: minValue,
                        higer: maxValue)
    }
    // 꼭지점 위치 계산
    private func peakPoints(values: [Double], step: CGPoint, info: HeightInfo) -> [CGPoint] {
        var xyPoints: [CGPoint] = []
        if (values.count < 2){
            return xyPoints
        }
        guard var min = values.min(), var max = values.max() else { return xyPoints }
        // 해당값의 비율이 최대값과 최소값의 차이에서 위치를 구해
        min = info.lowerValue
        max = info.higerValue
        let valueHeight = max - min
        let matrixHeight = self.matrixHeight
        for i in 0..<values.count {
            let ratio = valueHeight > 0 ? CGFloat((values[i] - min) / valueHeight) : 0
            let p2 = CGPoint(
                x: kLabelValueWidth + step.x * CGFloat(i) + kLeadingDotMargin,
                y: matrixHeight - (matrixHeight * ratio))
            xyPoints.append(p2)
        }
        return xyPoints
    }
    
    private func peakLine(step: CGPoint, points: [CGPoint]) -> Path {
        var path = Path()
        if (points.count < 2){
            return path
        }
        path.move(to: CGPoint(x: kLabelValueWidth, y: points[0].y - (step.y / 2)))
        for i in 0..<points.count {
            path.addLine(to: points[i])
        }
        debugPrint(points.count)
        return path
    }
    
    private func lineChart(step: CGPoint, points:[CGPoint]) -> Path {
        var path = Path()
        if (points.count < 2){
            return path
        }
        path.move(to: points[0])
        for pointIndex in 1..<points.count {
            path.addLine(to: points[pointIndex])
        }
        path.addLine(to: CGPoint(x: frame.width, y: frame.height - kLabelHeight))
        path.addLine(to: CGPoint(x: kLabelValueWidth, y: frame.height - kLabelHeight))
        path.addLine(to: CGPoint(x: kLabelValueWidth, y: points[0].y - (step.y / 2)))
        path.addLine(to: points[0])
        return path
    }
    
    private func lineDot(points:[CGPoint]) -> Path {
        var path = Path()
        for p in points {
            path.addEllipse(in: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7))
        }
        return path
    }
    
    private struct AltitudeLineValue: Hashable, Identifiable {
        let high: CGFloat
        let text: String
        
        var id: CGFloat { high }
    }
    
    private func altitudeLine(step: CGPoint, info: HeightInfo) -> some View {
        let basisY = frame.height - kLabelHeight
        var altitudes: [AltitudeLineValue] = []
        var h: CGFloat = basisY
        var path = Path()
        var i = 0
        let baseValue = info.lowerValue
        while frame.height > 0 && h >= 0 {
            path.move(to: CGPoint(x: kLabelValueWidth, y: h))
            path.addLine(to: CGPoint(x: frame.width, y: h))
            var valueString: String
            let value = info.stepValue * Double(i) + baseValue
            if value.truncatingRemainder(dividingBy: 1.0) == 0 {
                valueString = "\(Int(value))"
            } else {
                valueString = String(format: "%.1f", value)
            }
            
            altitudes.append(AltitudeLineValue(high: h, text: valueString))
            
            if step.y <= 0 {
                h = -1 // 스텝이 0 이면 무한되지 않고 바로 끝나도록 한다.
            } else {
                h -= step.y
            }
            i += 1
        }
        
        return ZStack {
            path.stroke(Color(.systemGray).opacity(0.7), style: StrokeStyle())
                .drawingGroup()
            ForEach(altitudes, id:\.self) { it in
                Text(it.text)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.secondary.opacity(0.7))
                    .position(x: 0, y: it.high)
                    .id(it.hashValue)
            }
        }
    }
    
    private struct ValueLineLabel: Hashable, Identifiable {
        let offset: Int
        let text: String?
        
        var id: Int { offset }
    }
    
    private func valueLine(step: CGPoint, labels: [String?]) -> some View {
        var path = Path()
        let basisY = matrixHeight
        var wOffset: CGFloat = kLabelValueWidth + kLeadingDotMargin
        for _ in  0..<labels.count {
            path.move(to: CGPoint(x: wOffset, y: basisY - 7.5))
            path.addLine(to: CGPoint(x: wOffset, y: basisY + 7.5))
            wOffset += step.x
        }
        
        let values = labels
            .enumerated()
            .map { ValueLineLabel(offset: $0.offset, text: $0.element) }
        
        return ZStack {
            path.stroke(Color(.systemGray).opacity(0.7), style: StrokeStyle())
            
            ForEach(values, id: \.offset) { it in
                Text(it.text ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(.systemPurple).opacity(0.7))
                    .position(
                        x: kLabelValueWidth  + kLeadingDotMargin + (step.x * CGFloat(it.offset)),
                        y: frame.height - 12)
                    .id(it.hashValue)
                
            }
        }
    }
    
    var chart: some View {
        var values = self.data.map { $0.value }
        if !values.isEmpty && values.count < 2 {
            values.append(values[0])
        }
        let labels = self.data.map { $0.label }
        let info = self.calculateStepHeightAndValue(values: values)
        let step = CGPoint(x: stepWidth, y: info.stepHeight)
        let peaks = self.peakPoints(values: values, step: step, info: info)
        return ZStack {
            altitudeLine(step: step, info: info)
            
            valueLine(step: step, labels: labels)
                
            if !peaks.isEmpty {
                peakLine(step: step, points: peaks)
                    .stroke()
                    .foregroundStyle(lineColor)
                
                lineChart(step: step, points: peaks)
                    .fill(LinearGradient(gradient: Gradient(colors: fillColors), startPoint: .top, endPoint: .bottom))
                    .drawingGroup()
                
                lineDot(points: peaks)
                    .foregroundColor(peakDotColor)
                    .drawingGroup()
            }
        }
    }
    
    
}

fileprivate extension Double {
    func nearInt() -> Int {
        return Int(self + 0.5)
    }
}

fileprivate extension Int {
    func toDouble() -> Double {
        return Double(self)
    }
}

// MARK: - Preview


struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Rectangle().frame(width: 36, height: 36, alignment: .center)
                    .cornerRadius(18).foregroundColor(.yellow)
                Text("님의 몸무게").foregroundColor(Color.white)
                Spacer()
            }
            .padding(20)
            .background(Color.black)
            
            HHLineGraphView(values: [
                GraphValue(value: 58, label: "4.12"),
                GraphValue(value: 54.6, label: "4.17"),
                GraphValue(value: 53.7, label: "4.21"),
                GraphValue(value: 52.5, label: "4.22"),
                GraphValue(value: 53.8, label: "4.25"),
                GraphValue(value: 57, label: "4.27"),
                GraphValue(value: 60, label: "4.28"),
            ])
        }
        .background(backgroundColor)
    }
    
    static var backgroundColor: Color {
    #if os(iOS)
        return Color(UIColor.systemBackground)
    #else
        return Color(nsColor: NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua: return .black
            default:
                return .white
            }
        })
    #endif
    }
}
