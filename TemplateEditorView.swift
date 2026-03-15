//
//  TemplateEditorView.swift
//  DreamLog
//
//  Phase 47: Dream Newsletter & Auto-Publishing
//  发布模板编辑器视图
//

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    
    let template: PublishTemplate?
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var platform: PublishPlatform
    @State private var titleTemplate: String
    @State private var contentTemplate: String
    @State private var includeTags: Bool
    @State private var includeEmotions: Bool
    @State private var includeAIAnalysis: Bool
    @State private var includeImages: Bool
    @State private var hashtagStyle: String
    @State private var customFooter: String
    @State private var showingVariables = false
    
    init(template: PublishTemplate?, isPresented: Binding<Bool>) {
        self.template = template
        _isPresented = isPresented
        
        if let template = template {
            _name = State(initialValue: template.name)
            _platform = State(initialValue: PublishPlatform(rawValue: template.platform) ?? .medium)
            _titleTemplate = State(initialValue: template.titleTemplate)
            _contentTemplate = State(initialValue: template.contentTemplate)
            _includeTags = State(initialValue: template.includeTags)
            _includeEmotions = State(initialValue: template.includeEmotions)
            _includeAIAnalysis = State(initialValue: template.includeAIAnalysis)
            _includeImages = State(initialValue: template.includeImages)
            _hashtagStyle = State(initialValue: template.hashtagStyle)
            _customFooter = State(initialValue: template.customFooter ?? "")
        } else {
            _name = State(initialValue: "新模板")
            _platform = State(initialValue: .medium)
            _titleTemplate = State(initialValue: "{{title}}")
            _contentTemplate = State(initialValue: "{{content}}\n\n{{#if tags}}\n标签：{{tags}}\n{{/if}}")
            _includeTags = State(initialValue: true)
            _includeEmotions = State(initialValue: true)
            _includeAIAnalysis = State(initialValue: false)
            _includeImages = State(initialValue: true)
            _hashtagStyle = State(initialValue: "suffix")
            _customFooter = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("模板名称", text: $name)
                    
                    Picker("目标平台", selection: $platform) {
                        ForEach(PublishPlatform.allCases) { platform in
                            Text(platform.displayName).tag(platform)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("内容模板") {
                    TextField("标题模板", text: $titleTemplate)
                        .font(.caption)
                    
                    TextEditor(text: $contentTemplate)
                        .font(.caption)
                        .frame(minHeight: 200)
                    
                    NavigationLink {
                        TemplateVariablesView()
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("可用变量说明")
                        }
                    }
                }
                
                Section("包含内容") {
                    Toggle("包含标签", isOn: $includeTags)
                    Toggle("包含情绪", isOn: $includeEmotions)
                    Toggle("包含 AI 解析", isOn: $includeAIAnalysis)
                    Toggle("包含图片", isOn: $includeImages)
                }
                
                Section("标签样式") {
                    Picker("标签位置", selection: $hashtagStyle) {
                        Text("行内").tag("inline")
                        Text("文末").tag("suffix")
                        Text("不显示").tag("none")
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("自定义页脚 (可选)", text: $customFooter)
                        .font(.caption)
                }
                
                Section {
                    Button(action: save) {
                        Text("保存模板")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || contentTemplate.isEmpty)
                    
                    if template != nil {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Text("删除模板")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(template == nil ? "新建模板" : "编辑模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func save() {
        if let existingTemplate = template {
            existingTemplate.name = name
            existingTemplate.platform = platform.rawValue
            existingTemplate.titleTemplate = titleTemplate
            existingTemplate.contentTemplate = contentTemplate
            existingTemplate.includeTags = includeTags
            existingTemplate.includeEmotions = includeEmotions
            existingTemplate.includeAIAnalysis = includeAIAnalysis
            existingTemplate.includeImages = includeImages
            existingTemplate.hashtagStyle = hashtagStyle
            existingTemplate.customFooter = customFooter
        } else {
            let newTemplate = PublishTemplate(
                name: name,
                platform: platform.rawValue,
                titleTemplate: titleTemplate,
                contentTemplate: contentTemplate,
                includeTags: includeTags,
                includeEmotions: includeEmotions,
                includeAIAnalysis: includeAIAnalysis,
                includeImages: includeImages,
                hashtagStyle: hashtagStyle,
                customFooter: customFooter.isEmpty ? nil : customFooter
            )
            modelContext.insert(newTemplate)
        }
        
        try? modelContext.save()
        isPresented = false
    }
    
    private func delete() {
        if let template = template {
            modelContext.delete(template)
            try? modelContext.save()
        }
        isPresented = false
    }
}

// MARK: - 模板变量说明视图

struct TemplateVariablesView: View {
    var body: some View {
        List {
            Section("基础变量") {
                VariableRow(variable: "{{title}}", description: "梦境标题")
                VariableRow(variable: "{{content}}", description: "梦境内容")
                VariableRow(variable: "{{date}}", description: "记录日期")
            }
            
            Section("条件内容") {
                VariableRow(variable: "{{tags}}", description: "标签列表（逗号分隔）")
                VariableRow(variable: "{{tagsJoined}}", description: "标签列表（带#号）")
                VariableRow(variable: "{{tagsFirst3}}", description: "前 3 个标签")
                VariableRow(variable: "{{emotions}}", description: "情绪列表")
                VariableRow(variable: "{{aiAnalysis}}", description: "AI 解析内容")
                VariableRow(variable: "{{contentTruncated}}", description: "截断的内容（适合 Twitter）")
            }
            
            Section("条件语句") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("条件块语法：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    CodeBlock(code: """
                    {{#if tags}}
                    这里有标签时显示的内容
                    {{/if}}
                    """)
                    
                    Text("只有在条件满足时，块内内容才会显示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Section("使用示例") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medium 风格：")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    CodeBlock(code: """
                    {{title}}
                    
                    {{content}}
                    
                    {{#if aiAnalysis}}
                    ## AI 梦境解析
                    
                    {{aiAnalysis}}
                    {{/if}}
                    
                    _Tags: {{tags}}_
                    """)
                    
                    Divider()
                    
                    Text("微信公众号风格：")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    CodeBlock(code: """
                    【梦境记录】{{title}}
                    
                    🌙 {{content}}
                    
                    {{#if emotions}}
                    💭 情绪：{{emotions}}
                    {{/if}}
                    
                    {{#if tags}}
                    🏷️ 标签：{{tags}}
                    {{/if}}
                    
                    ---
                    来自 DreamLog 梦境日记
                    """)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle("可用变量")
    }
}

struct VariableRow: View {
    let variable: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(variable)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CodeBlock: View {
    let code: String
    
    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

#Preview {
    TemplateEditorView(template: nil, isPresented: .constant(true))
}
