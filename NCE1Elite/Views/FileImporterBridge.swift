//
//  FileImporterBridge.swift
//  NCE1Elite
//
//  Direct UIKit-based file import — presents UIDocumentPickerViewController
//  from the app's root view controller, bypassing SwiftUI nested-presentation bugs.
//

import UIKit
import UniformTypeIdentifiers

/// Presents a UIDocumentPicker directly from the root view controller.
enum FileImporter {
    static func present(
        contentTypes: [UTType],
        allowsMultipleSelection: Bool = true,
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection

        let delegate = PickerDelegate(completion: completion)
        picker.delegate = delegate
        objc_setAssociatedObject(picker, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)

        guard let rootVC = topmostViewController() else {
            completion(.failure(NSError(domain: "FileImporter", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法获取根视图控制器"])))
            return
        }
        rootVC.present(picker, animated: true)
    }

    private static func topmostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let root = window.rootViewController else { return nil }
        return topmost(from: root)
    }

    private static func topmost(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topmost(from: presented)
        }
        if let nav = vc as? UINavigationController, let top = nav.topViewController {
            return topmost(from: top)
        }
        if let tab = vc as? UITabBarController, let sel = tab.selectedViewController {
            return topmost(from: sel)
        }
        return vc
    }
}

private var delegateKey: UInt8 = 0

private class PickerDelegate: NSObject, UIDocumentPickerDelegate {
    let completion: (Result<[URL], Error>) -> Void
    init(completion: @escaping (Result<[URL], Error>) -> Void) { self.completion = completion }

    func documentPicker(_ c: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion(.success(urls))
    }
    func documentPickerWasCancelled(_ c: UIDocumentPickerViewController) {
        completion(.success([]))
    }
}
