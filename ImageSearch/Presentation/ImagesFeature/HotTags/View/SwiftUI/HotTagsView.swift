import SwiftUI

struct HotTagsView: View {
    
    @StateObject var viewModelBridgeWrapper: HotTagsViewModelBridgeWrapper
    
    var coordinatorActions: HotTagsCoordinatorActions?
        
    var body: some View {
        VStack {
            List {
                HStack {
                    Spacer()
                    Picker("", selection: $viewModelBridgeWrapper.selectedSegment) {
                        ForEach(TagsSegmentType.allCases, id: \.self) { option in
                            Text(NSLocalizedString(option.rawValue, comment: ""))
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 152)
                    .padding(.vertical, 4)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                
                ForEach(viewModelBridgeWrapper.data, id: \.id) { tag in
                    TagCell(tag: tag)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModelBridgeWrapper.viewModel?.triggerDidSelect(tagName: tag.name)
                            if let hostingController = viewModelBridgeWrapper.hostingController {
                                coordinatorActions?.closeHotTags(hostingController)
                            }
                    }
                }
            }
            .listStyle(.plain)
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
            .onAppear {
                viewModelBridgeWrapper.viewModel?.getHotTags()
            }
        }
    }
}

struct TagCell: View {
    
    var tag: TagListItemVM
    
    var body: some View {
        HStack {
            Text("\(tag.name)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 18))
        }
        .padding(8)
    }
}

#Preview {
    let viewModelBridgeWrapper = HotTagsViewModelBridgeWrapper(viewModel: DefaultHotTagsViewModel(getHotTagsUseCase: DefaultGetHotTagsUseCase(tagRepository: DefaultTagRepository(apiInteractor: URLSessionAPIInteractor(with: NetworkService()))), didSelect: Event<String>()))
    HotTagsView(viewModelBridgeWrapper: viewModelBridgeWrapper)
}
