import UIKit
import CoreMotion

// MARK: - Orientation-Aware Gravity
//
// CMAccelerometerData / CMDeviceMotion.gravity is reported in the device's
// intrinsic coordinate frame:
//   +x = right edge of device (in portrait upright)
//   +y = top edge of device (in portrait upright)
//   +z = out of the screen toward the user
//
// When the interface is in landscape, that frame is rotated 90° relative
// to what the user sees as "down". To produce a gravity vector in the
// visible-screen coordinate frame, we rotate by the current interface
// orientation.
//
// Reference axes (user's perception of the screen):
//   • Portrait                — UI right = device +x, UI up = device +y
//   • Landscape Left          — home button on user's LEFT (phone tilted CW
//                               from portrait): UI right = device +y,
//                               UI up = device −x
//   • Landscape Right         — home button on user's RIGHT (phone tilted
//                               CCW from portrait): UI right = device −y,
//                               UI up = device +x
//   • Portrait Upside Down    — UI right = device −x, UI up = device −y

enum OrientationAwareGravity {

    /// Convert a device-frame gravity vector into a UIKit-screen gravity
    /// vector (top-left origin: +x = right on screen, +y = down on screen).
    /// Returns a unit-scale vector — multiply by gravity magnitude as needed.
    static func uiKitVector(deviceX x: Double, deviceY y: Double) -> CGVector {
        switch currentInterfaceOrientation {
        case .landscapeLeft:
            // UI right = +device.y, UI down = +device.x
            return CGVector(dx: y, dy: x)
        case .landscapeRight:
            // UI right = −device.y, UI down = −device.x
            return CGVector(dx: -y, dy: -x)
        case .portraitUpsideDown:
            // UI right = −device.x, UI down = +device.y
            return CGVector(dx: -x, dy: y)
        case .portrait, .unknown:
            fallthrough
        @unknown default:
            // UI right = +device.x, UI down = −device.y
            return CGVector(dx: x, dy: -y)
        }
    }

    /// Convert a device-frame acceleration vector into a SpriteKit gravity
    /// vector (lower-left origin: +x = right on screen, +y = up on screen).
    /// Returns a unit-scale vector — multiply by 9.8 for natural Earth gravity.
    static func spriteKitVector(deviceX x: Double, deviceY y: Double) -> CGVector {
        switch currentInterfaceOrientation {
        case .landscapeLeft:
            // SK right = +device.y, SK up = −device.x
            return CGVector(dx: y, dy: -x)
        case .landscapeRight:
            // SK right = −device.y, SK up = +device.x
            return CGVector(dx: -y, dy: x)
        case .portraitUpsideDown:
            // SK right = −device.x, SK up = −device.y
            return CGVector(dx: -x, dy: -y)
        case .portrait, .unknown:
            fallthrough
        @unknown default:
            // SK right = +device.x, SK up = +device.y
            return CGVector(dx: x, dy: y)
        }
    }

    private static var currentInterfaceOrientation: UIInterfaceOrientation {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .interfaceOrientation ?? .portrait
    }
}
