import UIKit
import Foundation

//https://hackernoon.com/grand-central-dispatch-gcd-in-ios-the-developers-guide
//Main queue is serial queue
//ConcurrentQueue doesn't care ordered position when using async keyword
//ConcurrentQueue and Main queue are the same if use sync keyword (a block will be run at the top to the bottom)

//Creating a New DispatchQueue for Each Task:
//
//Pros:
//
//Fine-grained control: You have more control over the tasks and can prioritize or cancel them individually.
//Isolation: You can avoid potential contention and race conditions that can arise when multiple tasks are performed concurrently on the same queue.
//Cons:
//
//Slightly higher overhead: Creating and tearing down queues can introduce a small amount of overhead. If you create many short-lived tasks, this overhead can add up.


//Using DispatchQueue.global for Background Tasks:
//Pros:
//
//Convenience: Global queues are preconfigured for common scenarios, such as background or user-interactive tasks.
//Efficient for many tasks: Global queues are well-suited for scenarios where you have multiple tasks that don't require fine-grained control.
//Cons:
//
//Limited control: You have less control over individual tasks. They all share the same queue and may contend for resources.
//The DispatchQueue.global is often used when you want a simple way to offload tasks to a background queue without worrying about queue management. You can specify the QoS (Quality of Service) level to prioritize tasks accordingly.
func mySerialQueue() {
  let serialQueue = DispatchQueue(label: "com.huy.serial")
  serialQueue.async {
    sleep(10)
    print("Task 1")
  }
  serialQueue.async {
    print("Task 2")
  }
    print("Done \(serialQueue.label)")

}

func myConcurrentQueue() {
    let concurrentQueue = DispatchQueue(label: "com.huy.concurrent", attributes: .concurrent)
    concurrentQueue.async {
    sleep(2)
    print("Task 1")
  }
    concurrentQueue.sync {
    print("Task 2")
  }
    print("Done \(concurrentQueue.label)")

}

//Actual: Done -> Task 1 sleep 10s -> Task 2
func myMainQueue() {
    let mainQueue = DispatchQueue.main
    mainQueue.async {
      sleep(10)
      print("Task 1")
    }
    mainQueue.sync {
      print("Task 2")
    }
    
    print("Done \(mainQueue.label)")
    
}

//Actual: Done -> Task 2(Global Queue) -> Task 1 (after sleep 10s)
func combineMainGlobalQueue() {
    let mainQueue = DispatchQueue.main
    let globalQueue = DispatchQueue.global()

    mainQueue.async {
      sleep(10)
      print("Task 1")
    }
    globalQueue.async {
      print("Task 2")
    }
    print("Done combineMainGlobalQueue")

}


 
func myDispatchGroup() {
    let concurrentQueue1 = DispatchQueue(label: "com.huy.concurrent1", attributes: .concurrent)
    let concurrentQueue2 = DispatchQueue(label: "com.huy.concurrent2", attributes: .concurrent)
    func myTask1(dispatchGroup:DispatchGroup){
        concurrentQueue1.async {
            sleep(5)
            print("\(concurrentQueue1.label) finished")
            dispatchGroup.leave()
        }
    }

    func myTask2(dispatchGroup:DispatchGroup){
        concurrentQueue2.async {
            print("\(concurrentQueue2.label) finished")
            dispatchGroup.leave()
        }
    }
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    myTask1(dispatchGroup: dispatchGroup)
    dispatchGroup.enter()
    myTask2(dispatchGroup: dispatchGroup)
 
    dispatchGroup.notify(queue: .main) {
        print("All tasks finished.")
    }
}

//When you call semaphore.wait(), it will decrement the semaphore's value by 1, meaning it acquires one permit.
//
//If another thread calls semaphore.wait() while the semaphore value is 1 (or greater), it will also decrement the value and acquire a permit, but if there is already one thread that acquired the permit, this call will block until the permit is released using semaphore.signal().
//
//When you call semaphore.signal(), it will increment the semaphore's value by 1, releasing the permit. If there were threads waiting for a permit, one of them will be allowed to proceed.
func myDispatchSemaphore() {
    let semaphore = DispatchSemaphore(value: 2) // Only 2 concurrent access permitted
    let myConcQueue1 = DispatchQueue(label: "com.huypham.barrier1", attributes: .concurrent)
    let myConcQueue2 = DispatchQueue(label: "com.huypham.barrier2", attributes: .concurrent)
    let currentThread = Thread.current
    print("Current thread: isMainThread \(currentThread.isMainThread)")
    myConcQueue1.async {
        semaphore.wait() // Acquire permit
        // Access the shared resource
        // ...
        sleep(2)
        print("Asynchronous Task 1 - Thread: \(Thread.current.isMainThread)")
        semaphore.signal() // Release permit
    }
    print("Done myDispatchSemaphore 1")
    myConcQueue2.async {
        semaphore.wait() // Acquire permit
        // Access the shared resource
        // ...
        print("Asynchronous Task 2 - Thread: \(Thread.current.isMainThread)")
        semaphore.signal() // Release permit
    }
}

//Barrier ensures no one task is being processed while the given one is executed.
func myDispatchBarrier(){
    let myConcQueue = DispatchQueue(label: "com.huypham.barrier", attributes: .concurrent)
 
    for j in 1...3 {
        myConcQueue.async(flags: .barrier) {
            print("Barrier \(j)")
        }
    }
    
    for i in 1...3 {
        myConcQueue.async() {
            print("Asynchronous Task \(i)")
        }
    }
}

// Custom operation for downloading an image
class ImageDownloadOperation: Operation {
    let url: URL
    let destinationURL: URL

    init(url: URL, destinationURL: URL) {
        self.url = url
        self.destinationURL = destinationURL
    }

    override func main() {
        // Simulate downloading the image (replace with actual networking code)
        sleep(1)
        print("Downloaded image from \(url)")

        // Save the image to the destination
        // Replace this with code to save the downloaded image to the destination URL
    }
}

func myNSOperationQueue() {
    // Create an NSOperationQueue
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 2 // Limit to 2 concurrent downloads

    // URLs of images to download
    let imageUrls = [
        URL(string: "https://example.com/image1.jpg")!,
        URL(string: "https://example.com/image2.jpg")!,
        URL(string: "https://example.com/image3.jpg")!,
    ]
   

    // Create ImageDownloadOperation instances for each image
    let downloadOperations = imageUrls.map { url in
        ImageDownloadOperation(url: url, destinationURL: url)
    }

    // Set operation dependencies
    downloadOperations[1].addDependency(downloadOperations[0])
    downloadOperations[2].addDependency(downloadOperations[1])

    // Set queue priority for operations
    downloadOperations[0].queuePriority = .high
    downloadOperations[1].queuePriority = .normal
    downloadOperations[2].queuePriority = .low

    // Add operations to the queue
    operationQueue.addOperations(downloadOperations, waitUntilFinished: false)
    print("Done myNSOperationQueue")
}

myNSOperationQueue()



