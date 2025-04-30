import SwiftUI

struct HotTagsView: View {
    
    @StateObject var viewModelBridgeWrapper: HotTagsViewModelBridgeWrapper
    
    var coordinatorActions: HotTagsCoordinatorActions?
        
    var body: some View {
        VStack {
            Picker("", selection: $viewModelBridgeWrapper.selectedSegment) {
                ForEach(TagsSegmentType.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            List {
                ForEach(viewModelBridgeWrapper.data as! [Tag]) { tag in
                    TagCell(tag: tag)
                        .frame(height: 38)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let imageQuery = ImageQuery(query: tag.name)
                            viewModelBridgeWrapper.viewModel?.triggerDidSelect(with: imageQuery)
                            if let hostingController = viewModelBridgeWrapper.hostingController {
                                coordinatorActions?.closeHotTags(hostingController)
                            }
                    }
                }
            }
            .navigationTitle(viewModelBridgeWrapper.screenTitle)
            .toolbar {
                Button {
                    if let hostingController = viewModelBridgeWrapper.hostingController {
                        coordinatorActions?.closeHotTags(hostingController)
                    }
                } label: {
                    Text("Done")
                        .bold()
                }
            }
            .onAppear( perform: {
                viewModelBridgeWrapper.viewModel?.getHotTags()
            })
        }
    }
}

struct TagCell: View {
    
    var tag: Tag
    
    var body: some View {
        HStack {
            Text("\(tag.name)")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
