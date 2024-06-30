import UIKit
import Combine

class NetworkManger:ObservableObject{
    
    @Published var posts:[PostModel] = []
    private var postUrl = "https://jsonplaceholder.typicode.com/posts"
    private var cancellable = Set<AnyCancellable>()
    
    init() {
        
        getPost()
    }
    
    private func downloadPosts<T: Decodable>(ResponseType:T.Type) -> AnyPublisher<T,Error>{
        
        guard let url = URL(string: postUrl) else { return Fail(error: APIError.invalidUrl).eraseToAnyPublisher()}
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .tryMap(handelOutput)
            .decode(type: T.self, decoder:JSONDecoder())
            .eraseToAnyPublisher()
        
        
    }
    
    private func getPost(){
        
        downloadPosts(ResponseType: [PostModel].self)
            .sink { (completion) in
                switch completion {
                    case .finished:
                        print("DEBUG POST DWONLOAD COMPLETE")
                    case .failure(let error):
                        print("DEBUG POST DWONLOAD FAILD WITH \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] (recivedPosts)  in
                self?.posts = recivedPosts
                print(self?.posts ?? [])
            }.store(in: &cancellable)
    }
    
    
    private func handelOutput(output:URLSession.DataTaskPublisher.Output) throws -> Data{
        
        guard
            let response = output.response as? HTTPURLResponse,
            response.statusCode  >= 200 && response.statusCode < 300 else{
            throw URLError(URLError.Code.badServerResponse)
        }
        return output.data
    }
}

struct PostModel:Identifiable,Codable {
    
    let userId:Int
    let id:Int
    let title:String
    let body:String
    
}
enum APIError: Error {
    case invalidResponse
    case invalidData
    case invalidUrl
    
}
var vm = NetworkManger()

