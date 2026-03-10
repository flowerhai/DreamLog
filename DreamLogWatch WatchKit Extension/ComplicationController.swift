//
//  ComplicationController.swift
//  DreamLog WatchKit Extension
//
//  表盘复杂功能控制器
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "dreamlog-complication",
                displayName: "DreamLog",
                supportedFamilies: CLKComplicationFamily.allCases
            )
        ]
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: Set<CLKComplicationDescriptor>) {
        // 处理共享的复杂功能描述符
    }
    
    // MARK: - Timeline Configuration
    
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let template = getTemplate(for: complication)
        let entry = CLKComplicationTimelineEntry(
            date: Date(),
            complicationTemplate: template
        )
        handler(entry)
    }
    
    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        var entries: [CLKComplicationTimelineEntry] = []
        
        // 提供未来 24 小时的条目
        for hourOffset in 1..<min(limit, 24) {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: Date()) ?? Date().addingTimeInterval(TimeInterval(hourOffset * 3600))
            let template = getTemplate(for: complication)
            let entry = CLKComplicationTimelineEntry(
                date: entryDate,
                complicationTemplate: template
            )
            entries.append(entry)
        }
        
        handler(entries)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(
        for complicationFamily: CLKComplicationFamily,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        let template = getTemplateForFamily(complicationFamily)
        handler(template)
    }
    
    // MARK: - Template Helpers
    
    private func getTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate()
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate()
        case .circularSmall:
            return createCircularSmallTemplate()
        case .extraLarge:
            return createExtraLargeTemplate()
        case .graphicCorner:
            return createGraphicCornerTemplate()
        case .graphicCircular:
            return createGraphicCircularTemplate()
        case .graphicRectangular:
            return createGraphicRectangularTemplate()
        case .graphicBezel:
            return createGraphicBezelTemplate()
        @unknown default:
            return createModularSmallTemplate()
        }
    }
    
    private func getTemplateForFamily(_ family: CLKComplicationFamily) -> CLKComplicationTemplate {
        switch family {
        case .modularSmall:
            return createModularSmallTemplate()
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate()
        case .circularSmall:
            return createCircularSmallTemplate()
        case .extraLarge:
            return createExtraLargeTemplate()
        case .graphicCorner:
            return createGraphicCornerTemplate()
        case .graphicCircular:
            return createGraphicCircularTemplate()
        case .graphicRectangular:
            return createGraphicRectangularTemplate()
        case .graphicBezel:
            return createGraphicBezelTemplate()
        @unknown default:
            return createModularSmallTemplate()
        }
    }
    
    // MARK: - Template Creation
    
    private func createModularSmallTemplate() -> CLKComplicationTemplate {
        let image = UIImage(named: "ComplicationIcon") ?? UIImage(systemName: "moon.fill") ?? UIImage()
        let imageProvider = CLKImageProvider(onePieceImage: image)
        let template = CLKComplicationTemplateModularSmallRingImage()
        template.imageProvider = imageProvider
        template.fillFraction = 0.7
        template.ringStyle = .closed
        
        return template
    }
    
    private func createUtilitarianSmallTemplate() -> CLKComplicationTemplate {
        let image = UIImage(named: "ComplicationIcon") ?? UIImage(systemName: "moon.fill") ?? UIImage()
        let imageProvider = CLKImageProvider(onePieceImage: image)
        let template = CLKComplicationTemplateUtilitarianSmallSquare()
        template.imageProvider = imageProvider
        
        return template
    }
    
    private func createCircularSmallTemplate() -> CLKComplicationTemplate {
        let image = UIImage(named: "ComplicationIcon") ?? UIImage(systemName: "moon.fill") ?? UIImage()
        let imageProvider = CLKImageProvider(onePieceImage: image)
        let template = CLKComplicationTemplateCircularSmallSimpleImage()
        template.imageProvider = imageProvider
        
        return template
    }
    
    private func createExtraLargeTemplate() -> CLKComplicationTemplate {
        let textProvider = CLKSimpleTextProvider(text: "🌙")
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = textProvider
        template.line2TextProvider = CLKSimpleTextProvider(text: "Dream")
        
        return template
    }
    
    private func createGraphicCornerTemplate() -> CLKComplicationTemplate {
        let image = UIImage(named: "ComplicationIcon") ?? UIImage(systemName: "moon.fill") ?? UIImage()
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        let template = CLKComplicationTemplateGraphicCornerStackText()
        template.imageProvider = imageProvider
        template.innerTextProvider = CLKSimpleTextProvider(text: "DreamLog")
        template.outerTextProvider = CLKSimpleTextProvider(text: "🌙")
        
        return template
    }
    
    private func createGraphicCircularTemplate() -> CLKComplicationTemplate {
        let image = UIImage(named: "ComplicationIcon") ?? UIImage(systemName: "moon.fill") ?? UIImage()
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeRange()
        template.imageProvider = imageProvider
        template.centerTextProvider = CLKSimpleTextProvider(text: "7")
        template.lowerBoundTextProvider = CLKSimpleTextProvider(text: "0")
        template.upperBoundTextProvider = CLKSimpleTextProvider(text: "14")
        template.gaugeStyle = .openFull
        template.fillFraction = 0.5
        
        return template
    }
    
    private func createGraphicRectangularTemplate() -> CLKComplicationTemplate {
        let textProvider = CLKSimpleTextProvider(text: "记录梦境")
        let image = UIImage(named: "ComplicationIcon") ?? UIImage(systemName: "moon.fill") ?? UIImage()
        let template = CLKComplicationTemplateGraphicRectangularStandardImage()
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        template.textProvider = textProvider
        
        return template
    }
    
    private func createGraphicBezelTemplate() -> CLKComplicationTemplate {
        let textProvider = CLKSimpleTextProvider(text: "DreamLog")
        let template = CLKComplicationTemplateGraphicBezelCircularText()
        template.circularTemplate = createGraphicCircularTemplate()
        template.textProvider = textProvider
        
        return template
    }
}
