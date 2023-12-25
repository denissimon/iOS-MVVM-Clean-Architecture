//
//  DefaultImageRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

class DefaultImageRepository: ImageRepository {
    
    let apiInteractor: APIInteractor
    
    init(apiInteractor: APIInteractor) {
        self.apiInteractor = apiInteractor
    }
    
    func searchImages(_ imageQuery: ImageQuery, completionHandler: @escaping (ImagesDataResult) -> Void) -> Cancellable? {
        let endpoint = FlickrAPI.search(imageQuery)
        let task = RepositoryTask()
        task.networkTask = apiInteractor.requestEndpoint(endpoint) { result in
            guard !task.isCancelled else { return }
            completionHandler(result)
        }
        return task
    }
    
    func prepareImages(_ imageData: Data, completionHandler: @escaping (Images?) -> Void) {
        DispatchQueue.global().async {
            do {
                guard
                    !imageData.isEmpty,
                    let resultsDictionary = try JSONSerialization.jsonObject(with: imageData) as? [String: AnyObject],
                    let stat = resultsDictionary["stat"] as? String
                    else {
                        completionHandler(nil)
                        return
                }

                if stat != "ok" {
                    completionHandler(nil)
                    return
                }
                
                guard
                    let container = resultsDictionary["photos"] as? [String: AnyObject],
                    let photos = container["photo"] as? [[String: AnyObject]]
                    else {
                        completionHandler(nil)
                        return
                }
                
                let imagesFound: [Image] = photos.compactMap { photoObject in
                    guard
                        let imageID = photoObject["id"] as? String,
                        let farm = photoObject["farm"] as? Int,
                        let server = photoObject["server"] as? String,
                        let secret = photoObject["secret"] as? String
                        else {
                            return nil
                    }

                    let image = Image(imageID: imageID, farm: farm, server: server, secret: secret)

                    guard
                        let url = image.getImageURL(),
                        let imageData = try? Data(contentsOf: url as URL)
                        else {
                            return nil
                    }

                    if let thumbnailImage = Supportive.getImage(data: imageData) {
                        image.thumbnail = ImageWrapper(image: thumbnailImage)
                        return image
                    } else {
                        return nil
                    }
                }
                
                if imagesFound.isEmpty {
                    completionHandler(nil)
                } else {
                    let images = Images(data: imagesFound)
                    completionHandler(images)
                }
            } catch {
                completionHandler(nil)
            }
        }
    }
    
    func getLargeImage(url: URL, completionHandler: @escaping (ImageDataResult) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        task.networkTask = apiInteractor.fetchFile(url: url) { result in
            completionHandler(result)
        }
        return task
    }
}
