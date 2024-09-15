import Cocoa
import CoreMotion

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let airpods = CMHeadphoneMotionManager()
    var motionData: [(time: Double, quW: Double, quX: Double, quY: Double, quZ: Double, accX: Double, accY: Double, accZ: Double)] = []
    var startTime: Date?

    // UI 컴포넌트
    var startButton: NSButton!
    var stopButton: NSButton!
    var saveButton: NSButton!
    var dataLabel: NSTextField!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupWindow()
        setupButtons()
        setupDataLabel()
    }

    func setupWindow() {
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        window = NSWindow(contentRect: screenSize, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "AirPods Motion Data"
        window.makeKeyAndOrderFront(nil)
    }

    func setupButtons() {
        // 시작 버튼
        startButton = NSButton(frame: NSRect(x: 100, y: 400, width: 100, height: 40))
        startButton.title = "Start Recording"
        startButton.action = #selector(startRecording)
        window.contentView?.addSubview(startButton)

        // 중지 버튼
        stopButton = NSButton(frame: NSRect(x: 220, y: 400, width: 100, height: 40))
        stopButton.title = "Stop Recording"
        stopButton.action = #selector(stopRecording)
        window.contentView?.addSubview(stopButton)

        // 저장 버튼
        saveButton = NSButton(frame: NSRect(x: 340, y: 400, width: 100, height: 40))
        saveButton.title = "Save Data"
        saveButton.action = #selector(saveDataButtonTapped)
        window.contentView?.addSubview(saveButton)
    }

    func setupDataLabel() {
        // 실시간 모션 데이터를 표시하는 라벨
        dataLabel = NSTextField(frame: NSRect(x: 100, y: 200, width: 600, height: 150))
        dataLabel.isEditable = false
        dataLabel.isBordered = false
        dataLabel.backgroundColor = .clear
        dataLabel.font = NSFont.systemFont(ofSize: 14)
        dataLabel.stringValue = "Motion data will appear here."
        window.contentView?.addSubview(dataLabel)
    }

    @objc func startRecording() {
        guard airpods.isDeviceMotionAvailable else {
            print("AirPods motion is not available")
            return
        }
        startTime = Date()
        airpods.startDeviceMotionUpdates(to: OperationQueue.current!) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                print("Error getting motion data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let timeInterval = Date().timeIntervalSince(self.startTime ?? Date())
            let quW = motion.attitude.quaternion.w
            let quX = motion.attitude.quaternion.x
            let quY = motion.attitude.quaternion.y
            let quZ = motion.attitude.quaternion.z
            let accX = motion.userAcceleration.x
            let accY = motion.userAcceleration.y
            let accZ = motion.userAcceleration.z - motion.gravity.z
            
            // 모션 데이터를 배열에 저장
            self.motionData.append((time: timeInterval, quW: quW, quX: quX, quY: quY, quZ: quZ, accX: accX, accY: accY, accZ: accZ))
            
            // dataLabel을 실시간으로 업데이트
            let displayText = """
            Time: \(timeInterval) s
            Quaternion: (\(quW), \(quX), \(quY), \(quZ))
            Accelerometer: (\(accX), \(accY), \(accZ))
            """
            DispatchQueue.main.async {
                self.dataLabel.stringValue = displayText
            }
        }
        print("Recording started")
    }

    @objc func stopRecording() {
        airpods.stopDeviceMotionUpdates()
        print("Recording stopped")
    }

    @objc func saveDataButtonTapped() {
        // CSV 파일 저장 경로 설정
        let savePanel = NSSavePanel()
        savePanel.title = "Save CSV File"
        savePanel.allowedFileTypes = ["csv"]
        savePanel.nameFieldStringValue = "motion_data_\(Date().description(with: .current)).csv" // 기본 파일명
        savePanel.begin { [weak self] result in
            if result == .OK, let url = savePanel.url {
                self?.saveMotionDataToCSV(fileURL: url)
            } else {
                print("User canceled the save panel or no URL provided.")
            }
        }
    }

    func saveMotionDataToCSV(fileURL: URL) {
        let header = "Time (s),Quaternion W,Quaternion X,Quaternion Y,Quaternion Z,Accelerometer X (g),Accelerometer Y (g),Accelerometer Z (g)\n"
        let csvData = motionData.map { "\($0.time),\($0.quW),\($0.quX),\($0.quY),\($0.quZ),\($0.accX),\($0.accY),\($0.accZ)" }.joined(separator: "\n")
        let fullData = header + csvData

        do {
            try fullData.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Data saved to \(fileURL)")
        } catch {
            print("Failed to save file: \(error.localizedDescription)")
        }
    }
}
