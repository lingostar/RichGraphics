import UIKit
import CoreMotion

// MARK: - Orientation-Aware Gravity
//
// CMAccelerometerData / CMDeviceMotion.gravity is reported in the device's
// intrinsic coordinate frame (x = right edge of device, y = top edge of
// device, z = out of screen). When the interface is in landscape, this
// frame is rotated 90° relative to what the user sees as "down".
//
// To get a gravity vector in the visible-screen coordinate frame, we have
// to rotate by the current interface orientation.

enum OrientationAwareGravity {

    /// Convert a device-frame gravity vector (e.g. CMAccelerometerData
    /// .acceleration) into a UIKit-screen gravity vector (top-left
    /// origin, +y = down on screen). Returns a unit-scale vector.
    static func uiKitVector(deviceX x: Double, deviceY y: Double) -> CGVector {
        switch currentInterfaceOrientation {
        case .landscapeLeft:
            // Home button on left. Device x → screen down, device y → screen right.
            return CGVector(dx: -y, dy: -x)
        case .landscapeRight:
            // Home button on right. Device x → screen up, device y → screen left.
            return CGVector(dx: y, dy: x)
        case .portraitUpsideDown:
            return CGVector(dx: -x, dy: y)
        case .portrait, .unknown:
            fallthrough
        @unknown default:
            return CGVector(dx: x, dy: -y)
        }
    }

    /// Convert a device-frame acceleration vector into a SpriteKit
    /// gravity vector (lower-left origin, +y = up on screen). Returns
    /// a unit-scale vector — multiply by 9.8 for natural Earth gravity.
    static func spriteKitVector(deviceX x: Double, deviceY y: Double) -> CGVector {
        switch currentInterfaceOrientation {
        case .landscapeLeft:
            // Device x → screen up (because home button is on left, top edge
            // of phone is on right which is "up" in the rotated UI).
            // Actually: device.x (which is "right of phone") is now pointing
            // physically downward in user view. So device.x positive = SK -y.
            // Let's derive carefully:
            //   landscape-left means UI is rotated +90° (CCW) relative to device.
            //   To map device → UI, rotate device vector by -90° (CW).
            //     (x, y) → (y, -x)
            // SK is lower-left, UIKit is upper-left, so SK.y = -UIKit.y.
            //   UIKit-screen vector: (y, -x)
            //   SK vector:           (y,  x)
            return CGVector(dx: y, dy: x)
        case .landscapeRight:
            //   landscape-right means UI is rotated -90° (CW) relative to device.
            //   Map device → UI by rotating +90° (CCW): (x, y) → (-y, x)
            //   UIKit: (-y, x)  →  SK: (-y, -x)
            return CGVector(dx: -y, dy: -x)
        case .portraitUpsideDown:
            //   180° rotation: (x, y) → (-x, -y) in UIKit, → (-x, y) in SK
            return CGVector(dx: -x, dy: y)
        case .portrait, .unknown:
            fallthrough
        @unknown default:
            //   No rotation. UIKit = (x, -y) since device.y up-on-phone but
            //   UIKit y-down-on-screen. SK keeps device y as-is.
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
