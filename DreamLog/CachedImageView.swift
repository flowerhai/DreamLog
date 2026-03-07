//
//  CachedImageView.swift
//  DreamLog
//
//  缓存图片视图 - 支持内存和磁盘缓存的图片加载组件
//

import SwiftUI

// MARK: - 缓存图片视图

struct CachedImageView: View {
    let urlString: String?
    let placeholder: AnyView?
    let contentMode: ContentMode
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    init(
        urlString: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> AnyView? = { AnyView(Color.gray.opacity(0.1)) }
    ) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }
    
    var body: some View {
        Group {
            if isLoading {
                placeholder ?? AnyView(progressPlaceholder)
            } else if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loadFailed {
                placeholder ?? AnyView(errorPlaceholder)
            } else {
                placeholder ?? AnyView(Color.gray.opacity(0.1))
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private var progressPlaceholder: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorPlaceholder: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadImage() async {
        guard let urlString = urlString else {
            loadFailed = true
            isLoading = false
            return
        }
        
        if let image = await ImageCacheService.shared.loadImage(from: urlString) {
            loadedImage = image
        } else {
            loadFailed = true
        }
        
        isLoading = false
    }
}

// MARK: - 圆角缓存图片视图

struct CachedImageViewWithRoundedCorners: View {
    let urlString: String?
    let cornerRadius: CGFloat
    let contentMode: ContentMode
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    init(
        urlString: String?,
        cornerRadius: CGFloat = 12,
        contentMode: ContentMode = .fill
    ) {
        self.urlString = urlString
        self.cornerRadius = cornerRadius
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if isLoading {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.accentColor)
                    )
            } else if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else if loadFailed {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    )
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = urlString else {
            loadFailed = true
            isLoading = false
            return
        }
        
        if let image = await ImageCacheService.shared.loadImage(from: urlString) {
            loadedImage = image
        } else {
            loadFailed = true
        }
        
        isLoading = false
    }
}

// MARK: - 预览

#if DEBUG
struct CachedImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CachedImageView(urlString: "https://picsum.photos/seed/123/400/400")
                .frame(height: 200)
            
            CachedImageViewWithRoundedCorners(
                urlString: "https://picsum.photos/seed/456/400/400",
                cornerRadius: 16
            )
            .frame(height: 200)
        }
        .padding()
    }
}
#endif
