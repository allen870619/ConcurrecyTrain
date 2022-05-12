//
//  ViewController.swift
//  Concurrency
//
//  Created by Lee Yen Lin on 2022/3/22.
//

import UIKit
let imgUrl = "https://media.discordapp.net/attachments/929379945346629642/974239836154257418/IMG_2536.png?width=1608&height=743"
let fileUrl = "https://www.orimi.com/pdf-test.pdf"

class ViewController: UIViewController {
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var btnConcat: UIButton!
    @IBOutlet weak var btnFlat: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnTest: UIButton!
    
    // data
    var list = [UIImageView]()
    var task: Task<Void, Error>?
    
    let actor = ImgActor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // continuous
        btnConcat.addAction(UIAction{[self] _ in
            for _ in 0...10{
                let img = UIImageView()
                img.contentMode = .scaleAspectFit
                img.image = UIImage.strokedCheckmark
                mainStack.addArrangedSubview(img)
                list.append(img)
            }
            
            // load from url
            // order, single task
            task = Task{
                for i in 0...10{
                    list[i].image = try await actor.getImg(imgUrl)
                }
            }
            
        }, for: .touchUpInside)
        
        // Discontinuous
        btnFlat.addAction(UIAction{[self] _ in
            for _ in 0...10{
                let img = UIImageView()
                img.contentMode = .scaleAspectFit
                img.image = UIImage.strokedCheckmark
                self.mainStack.addArrangedSubview(img)
                self.list.append(img)
            }
            
            // load from url
            // non order, multi tasks
            for i in 0...10{
                task = Task{
                    list[i].image = await actor.img
                }
            }
        }, for: .touchUpInside)
        
        
        // test actor
        btnTest.addAction(UIAction{[self] _ in
            let actor2 = ImgActor2()
            task = Task{
                try await actor2.doA()
            }
        }, for: .touchUpInside)
        
        
        btnClear.addAction(UIAction{[self] _ in
            if let task = task {
                if !task.isCancelled{
                    self.task?.cancel()
                }else{
                    for i in self.mainStack.arrangedSubviews{
                        i.removeFromSuperview()
                    }
                    list.removeAll()
                }
            }else{
                for i in self.mainStack.arrangedSubviews{
                    i.removeFromSuperview()
                }
                list.removeAll()
            }
        }, for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // old method
//        let url = URL(string: url)!
//        var task = URLSession.shared.dataTask(with: url){ data, resp, err in
//            let img = UIImage(data: data!)
//            DispatchQueue.main.async {
//                // set img
//            }
//        }
//        task.resume()
    }
    
    func getImg() async throws -> UIImage{
        print("1")
        let Url = URL(string: imgUrl)!
        let req = URLRequest(url: Url)
        let (data, _) = try await URLSession.shared.data(for: req)
        let img = UIImage(data: data)
        print("2")
        guard let thumbnail = await img?.byPreparingThumbnail(ofSize: CGSize(width: 100, height: 100)) else {throw CustomError.thumbErr}
        print("3")
        let url1 = URL(string: fileUrl)!
        let req1 = URLRequest(url: url1)
        print("4")
        let (data1, _) = try await URLSession.shared.data(for: req1)
        print(data1)
        return thumbnail
    }
    
}

actor ImgActor{
    var img : UIImage? {
        get async{
            do{
                return try await getImg(imgUrl)
            }catch{
                return nil
            }
        }
    }
    
    func getImg(_ url: String) async throws -> UIImage{
        print("1")
        let url = URL(string: url)!
        let req = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: req)
        let img = UIImage(data: data)
        print("2")
        guard let thumbnail = await img?.byPreparingThumbnail(ofSize: CGSize(width: 300, height: 300)) else {throw CustomError.thumbErr}
        print("3")
        let url1 = URL(string: fileUrl)!
        let req1 = URLRequest(url: url1)
        print("4")
        let (data1, _) = try await URLSession.shared.data(for: req1)
        print(data1)
        return thumbnail
    }
}

actor ImgActor2{
    func doA() async throws{
        for i in 1...10{
            Task.detached{ // this is not sequence.
                do{
                    try await self.doB("detach\(i)")
                }catch{
                    print(error)
                }
            }
        }
        for i in 1...10{
            try await doB("attach \(i)")
            if i == 5{
                throw NSError(domain: "A", code: 1) // throw won't affect detached jobs.
            }
        }
        
    }
    
    func doB(_ from: String) async throws{
        print("doB \(from)")
        print("doneB")
    }
}



enum CustomError: Error{
    case one
    case thumbErr
}
