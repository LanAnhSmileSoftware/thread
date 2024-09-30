import SwiftUI
import Combine

struct ImageItem: Identifiable {
    let id: Int
    var remainingTime: Int
    var isDownloaded: Bool = false
    var isVisible: Bool = false
}

class ImageDownloader: ObservableObject {
    @Published var items: [ImageItem] = []
    private var cancellables: [Int: AnyCancellable] = [:]
    private var downloadQueue: [Int] = []
    private var currentIndex = 0
    
    init() {
        items = (1...10).map { ImageItem(id: $0, remainingTime: 0) }
    }
    
    func startDownload() {
        items = (1...10).map { ImageItem(id: $0, remainingTime: Int.random(in: 5...10)) }
        downloadQueue = [1, 3, 5, 7, 9, 2, 4, 6, 8, 10]
        currentIndex = 0
        
        for itemId in downloadQueue {
            downloadImage(for: itemId)
        }
    }
    
    private func downloadImage(for itemId: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        
        cancellables[itemId] = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.items[index].remainingTime > 0 {
                    self.items[index].remainingTime -= 1
                } else {
                    self.items[index].isDownloaded = true
                    self.cancellables.removeValue(forKey: itemId)
                    self.checkAndShowNextImage()
                }
            }
    }
    
    private func checkAndShowNextImage() {
        while currentIndex < downloadQueue.count {
            let itemId = downloadQueue[currentIndex]
            if let index = items.firstIndex(where: { $0.id == itemId }),
               items[index].isDownloaded {
                items[index].isVisible = true
                currentIndex += 1
            } else {
                break
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var downloader = ImageDownloader()
    
    var body: some View {
        VStack {
            Button("Load") {
                downloader.startDownload()
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(downloader.items) { item in
                        VStack {
                            if item.isVisible {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                            } else if item.isDownloaded {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            } else {
                                Color.gray
                                    .frame(width: 100, height: 100)
                            }
                            Text("Image \(item.id)")
                            Text(item.remainingTime > 0 ? "\(item.remainingTime)s" : "")
                        }
                    }
                }
            }
        }
    }
}

