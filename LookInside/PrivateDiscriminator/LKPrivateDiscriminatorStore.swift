import AppKit
import Combine
import Foundation
import LookInsidePrivateDiscriminator

struct LKPrivateDiscriminatorModuleStatus: Identifiable, Hashable {
    let module: String
    let isEnabled: Bool
    let importedCSVPath: String?
    let autosavedCSVPath: String?
    let sourceFolderPath: String?
    let importedRecordCount: Int?
    let autosavedRecordCount: Int?
    let diagnostic: String?

    var id: String { module }

    var sourceSummary: String {
        var parts: [String] = []
        if importedCSVPath != nil {
            if let importedRecordCount {
                parts.append(
                    String(
                        format: NSLocalizedString("imported %ld", comment: ""),
                        importedRecordCount
                    )
                )
            } else {
                parts.append(NSLocalizedString("imported", comment: ""))
            }
        }
        if autosavedCSVPath != nil {
            if let autosavedRecordCount {
                parts.append(
                    String(
                        format: NSLocalizedString("autosaved %ld", comment: ""),
                        autosavedRecordCount
                    )
                )
            } else {
                parts.append(NSLocalizedString("autosaved", comment: ""))
            }
        }
        if parts.isEmpty {
            return NSLocalizedString("no CSV", comment: "")
        }
        let separator = NSLocalizedString(" / ", comment: "Separator between imported/autosaved CSV sources")
        return parts.joined(separator: separator)
    }
}

struct LKPrivateDiscriminatorInvalidDiagnostic: Identifiable, Hashable {
    let module: String
    let source: String
    let message: String

    var id: String { module + ":" + source }
}

@objc(LKPrivateDiscriminatorStore)
final class LKPrivateDiscriminatorStore: NSObject, ObservableObject {
    @objc(shared) static let shared = LKPrivateDiscriminatorStore()

    @Published private(set) var featureEnabled = false
    @Published private(set) var autosaveEnabled = false
    @Published private(set) var moduleStatuses: [LKPrivateDiscriminatorModuleStatus] = []
    @Published private(set) var invalidDiagnostics: [LKPrivateDiscriminatorInvalidDiagnostic] = []
    @Published private(set) var lastSettingsError: String?
    @Published private(set) var isUpdatingDefaultLibrary = false
    @Published private(set) var lastDefaultLibraryUpdateMessage: String?

    @objc var isFeatureEnabled: Bool { featureEnabled }

    let storageDirectoryURL: URL
    let importedDirectoryURL: URL
    let autosavedDirectoryURL: URL

    private let configURL: URL
    private var configuration = Configuration()
    private var loadedIndexesByModule: [String: [LoadedModuleIndex]] = [:]
    private let verificationCache = PrivateDiscriminatorVerificationCache(bucketCount: 20)
    private var activeGuessTasksByID: [String: Process] = [:]
    private var guessStatesByID: [String: GuessState] = [:]
    private var cancelledGuessIDs: Set<String> = []

    private override init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        storageDirectoryURL = appSupport.appendingPathComponent("LookInside/private_disc", isDirectory: true)
        importedDirectoryURL = storageDirectoryURL.appendingPathComponent("imported", isDirectory: true)
        autosavedDirectoryURL = storageDirectoryURL.appendingPathComponent("autosaved", isDirectory: true)
        configURL = storageDirectoryURL.appendingPathComponent("config.json", isDirectory: false)
        super.init()
        reloadFromDisk()
    }

    func reloadFromDisk() {
        do {
            try ensureStorageDirectories()
            configuration = try readConfiguration()
            featureEnabled = configuration.featureEnabled
            autosaveEnabled = configuration.autosaveEnabled
            rebuildIndexes()
            lastSettingsError = nil
        } catch {
            lastSettingsError = error.localizedDescription
        }
    }

    func setFeatureEnabled(_ enabled: Bool) {
        configuration.featureEnabled = enabled
        persistConfigurationAndReload()
    }

    func setAutosaveEnabled(_ enabled: Bool) {
        configuration.autosaveEnabled = enabled
        persistConfigurationAndReload()
    }

    func updateDefaultLibrary() {
        guard !isUpdatingDefaultLibrary else {
            return
        }

        isUpdatingDefaultLibrary = true
        lastDefaultLibraryUpdateMessage = NSLocalizedString("Updating default library…", comment: "")
        lastSettingsError = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }

            do {
                let results = try self.downloadDefaultLibraryIndexes()
                DispatchQueue.main.async {
                    self.isUpdatingDefaultLibrary = false
                    if results.contains(where: { $0.didChange }) {
                        let summary = results
                            .map { "\($0.module): \($0.recordCount)" }
                            .joined(separator: ", ")
                        self.lastDefaultLibraryUpdateMessage = String(
                            format: NSLocalizedString("Updated default library: %@.", comment: ""),
                            summary
                        )
                    } else {
                        self.lastDefaultLibraryUpdateMessage = NSLocalizedString(
                            "Default library is already up to date.",
                            comment: ""
                        )
                    }
                    self.reloadFromDisk()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isUpdatingDefaultLibrary = false
                    self.lastDefaultLibraryUpdateMessage = nil
                    self.lastSettingsError = error.localizedDescription
                }
            }
        }
    }

    func setModule(_ module: String, enabled: Bool) {
        guard PrivateDiscriminatorModuleIndex.isValidModuleName(module) else {
            return
        }
        var disabledModules = Set(configuration.disabledModules)
        if enabled {
            disabledModules.remove(module)
        } else {
            disabledModules.insert(module)
        }
        configuration.disabledModules = disabledModules.sorted()
        persistConfigurationAndReload()
    }

    func importModule(named module: String, from folderURL: URL) throws {
        let trimmedModule = module.trimmingCharacters(in: .whitespacesAndNewlines)
        guard PrivateDiscriminatorModuleIndex.isValidModuleName(trimmedModule) else {
            throw LKPrivateDiscriminatorStoreError.invalidModuleName(trimmedModule)
        }

        try ensureStorageDirectories()
        let filenames = try swiftFilenames(in: folderURL)
        let now = Date()
        let existingRecords = existingImportedRecordsByFilename(for: trimmedModule)

        let records = filenames.map { filename -> PrivateDiscriminatorRecord in
            let existing = existingRecords[filename]
            return PrivateDiscriminatorRecord(
                id: Self.privateDiscriminatorID(module: trimmedModule, filename: filename),
                filename: filename,
                created_at: existing?.created_at ?? now,
                updated_at: now,
                created_by: existing?.created_by ?? .imported,
                updated_by: .imported
            )
        }

        let csvText = try PrivateDiscriminatorCSV.write(records)
        let targetURL = importedCSVURL(for: trimmedModule)
        try csvText.write(to: targetURL, atomically: true, encoding: .utf8)

        configuration.importSources[trimmedModule] = folderURL.standardizedFileURL.path
        configuration.disabledModules.removeAll { $0 == trimmedModule }
        persistConfigurationAndReload()
    }

    func reimportModule(_ module: String) throws {
        guard let path = configuration.importSources[module], !path.isEmpty else {
            throw LKPrivateDiscriminatorStoreError.missingImportSource(module)
        }
        try importModule(named: module, from: URL(fileURLWithPath: path, isDirectory: true))
    }

    func removeModule(_ module: String) throws {
        try ensureStorageDirectories()
        let fileManager = FileManager.default
        for url in [importedCSVURL(for: module), autosavedCSVURL(for: module)] where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        configuration.importSources.removeValue(forKey: module)
        configuration.disabledModules.removeAll { $0 == module }
        persistConfigurationAndReload()
    }

    func revealStorageDirectory() {
        try? ensureStorageDirectories()
        NSWorkspace.shared.activateFileViewerSelecting([storageDirectoryURL])
    }

    func revealModule(_ module: String) {
        let candidates = [importedCSVURL(for: module), autosavedCSVURL(for: module)]
        let existing = candidates.filter { FileManager.default.fileExists(atPath: $0.path) }
        if existing.isEmpty {
            revealStorageDirectory()
        } else {
            NSWorkspace.shared.activateFileViewerSelecting(existing)
        }
    }

    @objc(displayTitleForDisplayItem:fallback:)
    func displayTitle(for item: LookinDisplayItem, fallback: String?) -> String? {
        guard featureEnabled, let fallback, !fallback.isEmpty else {
            return fallback
        }
        let cleaned = Self.cleanedDisplayText(fallback)
        return cleaned.isEmpty ? fallback : cleaned
    }

    @objc(isPrivateDisplayItem:)
    func isPrivateDisplayItem(_ item: LookinDisplayItem) -> Bool {
        guard featureEnabled else {
            return false
        }
        return parsedPrivateDiscriminator(for: item) != nil
    }

    @objc(appendingPrivateDiscriminatorGroupToGroups:forDisplayItem:)
    func appendingPrivateDiscriminatorGroup(to groups: [LookinAttributesGroup], for item: LookinDisplayItem) -> [LookinAttributesGroup] {
        guard featureEnabled, let descriptor = dashboardDescriptor(for: item) else {
            return groups
        }
        let filteredGroups = groups.filter { $0.userCustomTitle != Self.dashboardTitle }
        let dashboardGroup = makeDashboardGroup(for: item, descriptor: descriptor)
        guard let classGroupIndex = filteredGroups.firstIndex(where: { $0.identifier == LookinAttrGroup_Class }) else {
            return filteredGroups + [dashboardGroup]
        }

        var result = filteredGroups
        result.insert(dashboardGroup, at: filteredGroups.index(after: classGroupIndex))
        return result
    }

    @objc(submitPrivateDiscriminatorForDisplayItem:module:filename:error:)
    func submitPrivateDiscriminator(for item: LookinDisplayItem, module: String, filename: String, error: NSErrorPointer) -> Bool {
        do {
            guard let parsed = parsedPrivateDiscriminator(for: item) else {
                throw LKPrivateDiscriminatorStoreError.missingPrivateDiscriminator
            }
            let trimmedModule = module.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedFilename = filename.trimmingCharacters(in: .whitespacesAndNewlines)
            let verification = verificationCache.verify(id: parsed.id, module: trimmedModule, filename: trimmedFilename)
            guard verification.isMatch else {
                throw LKPrivateDiscriminatorStoreError.verificationFailed(Self.message(for: verification))
            }

            try saveRecord(
                id: parsed.id,
                module: trimmedModule,
                filename: trimmedFilename,
                author: .user
            )
            return true
        } catch let caughtError as NSError {
            error?.pointee = caughtError
            return false
        }
    }

    @objc(importPrivateDiscriminatorFromCodebaseForDisplayItem:window:error:)
    func importPrivateDiscriminatorFromCodebase(for item: LookinDisplayItem, window: NSWindow?, error: NSErrorPointer) -> Bool {
        do {
            guard let parsed = parsedPrivateDiscriminator(for: item) else {
                throw LKPrivateDiscriminatorStoreError.missingPrivateDiscriminator
            }
            guard let module = promptForModuleName(defaultModule: parsed.moduleHint, window: window) else {
                return false
            }

            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.prompt = NSLocalizedString("Import", comment: "")
            panel.message = String(
                format: NSLocalizedString("Choose the local Swift source folder for %@.", comment: ""),
                module
            )

            let response = panel.runModal()
            window?.makeKey()
            guard response == .OK, let url = panel.url else {
                return false
            }

            try importModule(named: module, from: url)
            return true
        } catch let caughtError as NSError {
            error?.pointee = caughtError
            return false
        }
    }

    @objc(beginSwiftPDGuessForDisplayItem:window:)
    func beginSwiftPDGuess(for item: LookinDisplayItem, window: NSWindow?) {
        guard let parsed = parsedPrivateDiscriminator(for: item) else {
            return
        }
        guard activeGuessTasksByID[parsed.id] == nil else {
            return
        }
        guard let executableURL = swiftPDGuessExecutableURL() else {
            presentSwiftPDGuessInstallAlert(window: window)
            return
        }
        guard let request = promptForSwiftPDGuessRequest(parsed: parsed, window: window) else {
            return
        }

        let task = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        task.executableURL = executableURL
        task.arguments = [
            parsed.id,
            request.words.joined(separator: ","),
            "--prefix",
            request.module,
            "--max-count",
            String(request.maxCount),
        ]
        task.standardOutput = stdout
        task.standardError = stderr

        activeGuessTasksByID[parsed.id] = task
        guessStatesByID[parsed.id] = .running
        cancelledGuessIDs.remove(parsed.id)
        postDashboardStateDidChange()

        task.terminationHandler = { [weak self, weak stdout, weak stderr] process in
            let stdoutData = stdout?.fileHandleForReading.readDataToEndOfFile() ?? Data()
            let stderrData = stderr?.fileHandleForReading.readDataToEndOfFile() ?? Data()
            let stdoutText = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderrText = String(data: stderrData, encoding: .utf8) ?? ""

            DispatchQueue.main.async {
                self?.finishSwiftPDGuess(
                    id: parsed.id,
                    module: request.module,
                    process: process,
                    stdout: stdoutText,
                    stderr: stderrText
                )
            }
        }

        do {
            try task.run()
        } catch {
            activeGuessTasksByID.removeValue(forKey: parsed.id)
            guessStatesByID[parsed.id] = .failed(
                String(
                    format: NSLocalizedString("Failed to launch swift-pd-guess: %@", comment: ""),
                    error.localizedDescription
                )
            )
            postDashboardStateDidChange()
        }
    }

    @objc(cancelSwiftPDGuessForDisplayItem:)
    func cancelSwiftPDGuess(for item: LookinDisplayItem) {
        guard let parsed = parsedPrivateDiscriminator(for: item),
              let task = activeGuessTasksByID[parsed.id]
        else {
            return
        }
        cancelledGuessIDs.insert(parsed.id)
        task.terminate()
    }

    private func persistConfigurationAndReload() {
        do {
            try ensureStorageDirectories()
            try writeConfiguration(configuration)
            reloadFromDisk()
        } catch {
            lastSettingsError = error.localizedDescription
        }
    }

    private func ensureStorageDirectories() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: importedDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: autosavedDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func readConfiguration() throws -> Configuration {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return Configuration()
        }
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(Configuration.self, from: data)
    }

    private func writeConfiguration(_ configuration: Configuration) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(configuration.normalized())
        try data.write(to: configURL, options: .atomic)
    }

    private func rebuildIndexes() {
        loadedIndexesByModule = [:]
        var builders: [String: ModuleStatusBuilder] = [:]
        var diagnostics: [LKPrivateDiscriminatorInvalidDiagnostic] = []

        for (module, sourcePath) in configuration.importSources {
            builders[module, default: ModuleStatusBuilder(module: module)].sourceFolderPath = sourcePath
        }

        collectCSVFiles(in: importedDirectoryURL).forEach { module, url in
            builders[module, default: ModuleStatusBuilder(module: module)].importedCSVPath = url.path
        }
        collectCSVFiles(in: autosavedDirectoryURL).forEach { module, url in
            builders[module, default: ModuleStatusBuilder(module: module)].autosavedCSVPath = url.path
        }

        let disabledModules = Set(configuration.disabledModules)
        if configuration.featureEnabled {
            for module in builders.keys.sorted() where !disabledModules.contains(module) {
                if let path = builders[module]?.importedCSVPath {
                    loadIndex(module: module, source: .imported, path: path, builders: &builders, diagnostics: &diagnostics)
                }
                if let path = builders[module]?.autosavedCSVPath {
                    loadIndex(module: module, source: .autosaved, path: path, builders: &builders, diagnostics: &diagnostics)
                }
            }
        }

        moduleStatuses = builders.values
            .map { $0.status(disabledModules: disabledModules) }
            .sorted { $0.module.localizedStandardCompare($1.module) == .orderedAscending }
        invalidDiagnostics = diagnostics.sorted {
            if $0.module == $1.module {
                return $0.source < $1.source
            }
            return $0.module.localizedStandardCompare($1.module) == .orderedAscending
        }
    }

    private func collectCSVFiles(in directoryURL: URL) -> [(module: String, url: URL)] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return urls.compactMap { url in
            guard url.pathExtension.lowercased() == "csv" else {
                return nil
            }
            let module = url.deletingPathExtension().lastPathComponent
            guard PrivateDiscriminatorModuleIndex.isValidModuleName(module) else {
                return nil
            }
            return (module, url)
        }
    }

    private func loadIndex(
        module: String,
        source: LoadedModuleIndex.Source,
        path: String,
        builders: inout [String: ModuleStatusBuilder],
        diagnostics: inout [LKPrivateDiscriminatorInvalidDiagnostic]
    ) {
        do {
            let text = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
            let index = try PrivateDiscriminatorModuleIndex.read(moduleName: module, csvText: text)
            loadedIndexesByModule[module, default: []].append(LoadedModuleIndex(source: source, index: index))
            switch source {
            case .imported:
                builders[module]?.importedRecordCount = index.records.count
            case .autosaved:
                builders[module]?.autosavedRecordCount = index.records.count
            case .fallback:
                break
            }
        } catch {
            let diagnostic = LKPrivateDiscriminatorInvalidDiagnostic(
                module: module,
                source: source.rawValue,
                message: String(describing: error)
            )
            diagnostics.append(diagnostic)
            builders[module]?.diagnostics.append(diagnostic.message)
        }
    }

    private func downloadDefaultLibraryIndexes() throws -> [DefaultLibraryUpdateResult] {
        let downloads = try Self.defaultLibraryModules.map { module -> DefaultLibraryDownload in
            let csvText = try downloadCSVText(for: module)
            let index = try PrivateDiscriminatorModuleIndex.read(moduleName: module.name, csvText: csvText)
            let normalizedCSVText = try PrivateDiscriminatorCSV.write(index.records)
            return DefaultLibraryDownload(
                module: module.name,
                recordCount: index.records.count,
                csvText: normalizedCSVText
            )
        }

        try ensureStorageDirectories()

        return try downloads.map { download in
            let destinationURL = importedCSVURL(for: download.module)
            let existingText = try? String(contentsOf: destinationURL, encoding: .utf8)
            guard existingText != download.csvText else {
                return DefaultLibraryUpdateResult(
                    module: download.module,
                    recordCount: download.recordCount,
                    didChange: false
                )
            }

            try download.csvText.write(to: destinationURL, atomically: true, encoding: .utf8)
            return DefaultLibraryUpdateResult(
                module: download.module,
                recordCount: download.recordCount,
                didChange: true
            )
        }
    }

    private func downloadCSVText(for module: DefaultLibraryModule) throws -> String {
        var capturedData: Data?
        var capturedError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: module.url) { data, response, error in
            defer { semaphore.signal() }

            if let error {
                capturedError = LKPrivateDiscriminatorStoreError.defaultLibraryDownloadFailed(
                    module.name,
                    error.localizedDescription
                )
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                capturedError = LKPrivateDiscriminatorStoreError.defaultLibraryDownloadFailed(
                    module.name,
                    NSLocalizedString("No response received.", comment: "")
                )
                return
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                capturedError = LKPrivateDiscriminatorStoreError.defaultLibraryDownloadFailed(
                    module.name,
                    "HTTP \(httpResponse.statusCode)"
                )
                return
            }

            guard let data, !data.isEmpty else {
                capturedError = LKPrivateDiscriminatorStoreError.defaultLibraryDownloadFailed(
                    module.name,
                    NSLocalizedString("Empty download payload.", comment: "")
                )
                return
            }

            capturedData = data
        }
        task.resume()
        semaphore.wait()

        if let capturedError {
            throw capturedError
        }

        guard let capturedData, let text = String(data: capturedData, encoding: .utf8) else {
            throw LKPrivateDiscriminatorStoreError.defaultLibraryDownloadFailed(
                module.name,
                NSLocalizedString("Unable to decode CSV as UTF-8.", comment: "")
            )
        }
        return text
    }

    private func importedCSVURL(for module: String) -> URL {
        importedDirectoryURL.appendingPathComponent(module + ".csv", isDirectory: false)
    }

    private func autosavedCSVURL(for module: String) -> URL {
        autosavedDirectoryURL.appendingPathComponent(module + ".csv", isDirectory: false)
    }

    private func swiftFilenames(in folderURL: URL) throws -> [String] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw LKPrivateDiscriminatorStoreError.unreadableFolder(folderURL.path)
        }

        var filenames: Set<String> = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true, fileURL.pathExtension.lowercased() == "swift" else {
                continue
            }
            filenames.insert(fileURL.lastPathComponent)
        }
        return filenames.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private func existingImportedRecordsByFilename(for module: String) -> [String: PrivateDiscriminatorRecord] {
        let url = importedCSVURL(for: module)
        guard let text = try? String(contentsOf: url, encoding: .utf8),
              let records = try? PrivateDiscriminatorCSV.read(text)
        else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: records.map { ($0.filename, $0) })
    }

    private func existingAutosavedRecords(for module: String) throws -> [PrivateDiscriminatorRecord] {
        let url = autosavedCSVURL(for: module)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        return try PrivateDiscriminatorCSV.read(text)
    }

    private func saveRecord(id: String, module: String, filename: String, author: PrivateDiscriminatorRecordAuthor) throws {
        try ensureStorageDirectories()

        var records = try existingAutosavedRecords(for: module)
        let now = Date()
        let existing = records.first { $0.id == id || $0.filename == filename }
        records.removeAll { $0.id == id || $0.filename == filename }
        records.append(
            PrivateDiscriminatorRecord(
                id: id,
                filename: filename,
                created_at: existing?.created_at ?? now,
                updated_at: now,
                created_by: existing?.created_by ?? author,
                updated_by: author
            )
        )

        let csvText = try PrivateDiscriminatorCSV.write(records)
        try csvText.write(to: autosavedCSVURL(for: module), atomically: true, encoding: .utf8)

        configuration.disabledModules.removeAll { $0 == module }
        persistConfigurationAndReload()
        postDashboardStateDidChange()
    }

    private func dashboardDescriptor(for item: LookinDisplayItem) -> DashboardDescriptor? {
        guard let parsed = parsedPrivateDiscriminator(for: item) else {
            return nil
        }

        if let module = parsed.moduleHint,
           !configuration.disabledModules.contains(module),
           let indexes = loadedIndexesByModule[module]
        {
            for loadedIndex in indexes {
                if let record = loadedIndex.index.record(forID: parsed.id) {
                    return makeMatchedDashboardDescriptor(parsed: parsed, module: module, record: record, source: loadedIndex.source)
                }
            }
        }

        for module in loadedIndexesByModule.keys.sorted()
            where module != parsed.moduleHint && !configuration.disabledModules.contains(module)
        {
            for loadedIndex in loadedIndexesByModule[module] ?? [] {
                if let record = loadedIndex.index.record(forID: parsed.id) {
                    return makeMatchedDashboardDescriptor(parsed: parsed, module: module, record: record, source: loadedIndex.source)
                }
            }
        }

        return DashboardDescriptor(
            id: parsed.id,
            module: "",
            filename: "",
            source: nil,
            isMatched: false,
            isVerified: false,
            warning: nil,
            className: parsed.className,
            guessState: dashboardGuessState(for: parsed.id, isMatched: false)
        )
    }

    private func makeMatchedDashboardDescriptor(
        parsed: ParsedDiscriminator,
        module: String,
        record: PrivateDiscriminatorRecord,
        source: LoadedModuleIndex.Source
    ) -> DashboardDescriptor {
        let verification = verificationCache.verify(id: parsed.id, module: module, filename: record.filename)
        return DashboardDescriptor(
            id: parsed.id,
            module: module,
            filename: record.filename,
            source: source,
            isMatched: true,
            isVerified: verification.isMatch,
            warning: verification.isMatch ? nil : Self.message(for: verification),
            className: parsed.className,
            guessState: dashboardGuessState(for: parsed.id, isMatched: true)
        )
    }

    private func dashboardGuessState(for id: String, isMatched: Bool) -> GuessState? {
        guard let guessState = guessStatesByID[id] else {
            return nil
        }
        guard isMatched else {
            return guessState
        }
        if case .succeeded = guessState {
            return guessState
        }
        return nil
    }

    private func parsedPrivateDiscriminator(for item: LookinDisplayItem) -> ParsedDiscriminator? {
        for text in candidateTexts(for: item) {
            guard let id = Self.privateDiscriminatorID(in: text) else {
                continue
            }
            return ParsedDiscriminator(
                id: id,
                moduleHint: Self.moduleHint(in: text),
                className: Self.cleanedClassName(from: text)
            )
        }
        return nil
    }

    private func candidateTexts(for item: LookinDisplayItem) -> [String] {
        var texts: [String] = []

        func append(_ value: String?) {
            guard let value, !value.isEmpty, !texts.contains(value) else {
                return
            }
            texts.append(value)
        }

        append(item.customInfo?.title)
        append(item.customInfo?.subtitle)
        append(item.customDisplayTitle)
        append(item.danceuiSource)

        for object in [
            item.viewObject,
            item.layerObject,
            item.windowObject,
            item.hostViewControllerObject,
            item.hostWindowControllerObject,
        ] {
            appendTexts(from: object, into: &texts)
        }

        return texts
    }

    private func appendTexts(from object: LookinObject?, into texts: inout [String]) {
        guard let object else {
            return
        }

        func append(_ value: String?) {
            guard let value, !value.isEmpty, !texts.contains(value) else {
                return
            }
            texts.append(value)
        }

        if let rawName = object.rawClassName(), !rawName.isEmpty {
            append(rawName)
            append(LKSwiftDemangler.completedParse(input: rawName))
            append(LKSwiftDemangler.simpleParse(input: rawName))
        }
        append(object.specialTrace)

        for className in object.classChainList ?? [] {
            append(className)
            append(LKSwiftDemangler.completedParse(input: className))
            append(LKSwiftDemangler.simpleParse(input: className))
        }
    }

    private func fallbackFilename(for parsed: ParsedDiscriminator) -> String? {
        guard let className = parsed.className else {
            return nil
        }
        for filename in Self.filenameCandidates(from: className) {
            if Self.privateDiscriminatorID(module: "", filename: filename) == parsed.id {
                return filename
            }
        }
        return nil
    }

    private func makeDashboardGroup(for item: LookinDisplayItem, descriptor: DashboardDescriptor) -> LookinAttributesGroup {
        let attribute = LookinAttribute()
        attribute.identifier = Self.dashboardAttributeIdentifier
        attribute.displayTitle = NSLocalizedString("Discriminator Details", comment: "")
        attribute.attrType = .customObj
        attribute.value = LKPrivateDiscriminatorDashboardPayload(descriptor: descriptor)
        attribute.targetDisplayItem = item

        let section = LookinAttributesSection()
        section.identifier = LookinAttrSec_UserCustom
        section.attributes = [attribute]

        let group = LookinAttributesGroup()
        group.identifier = LookinAttrGroup_UserCustom
        group.userCustomTitle = Self.dashboardTitle
        group.attrSections = [section]
        return group
    }

    private static func privateDiscriminatorID(in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = privateIDRegex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let idRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[idRange]).uppercased()
    }

    private static func moduleHint(in text: String) -> String? {
        let nsText = text as NSString
        guard let idMatch = privateIDRegex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) else {
            return nil
        }
        let prefix = nsText.substring(with: NSRange(location: 0, length: idMatch.range.location))
        let prefixRange = NSRange(location: 0, length: (prefix as NSString).length)
        guard let moduleMatch = modulePrefixRegex.firstMatch(in: prefix, options: [], range: prefixRange),
              let range = Range(moduleMatch.range(at: 1), in: prefix)
        else {
            return nil
        }
        let module = String(prefix[range])
        return PrivateDiscriminatorModuleIndex.isValidModuleName(module) ? module : nil
    }

    private static func cleanedDisplayText(_ text: String) -> String {
        var result = text
        for regex in privateDisplayCleanupRegexes {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        return result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanedClassName(from text: String) -> String? {
        var result = cleanedDisplayText(text)
        result = genericParameterRegex.stringByReplacingMatches(
            in: result,
            range: NSRange(result.startIndex..., in: result),
            withTemplate: ""
        )
        result = result.replacingOccurrences(of: "(", with: " ")
        result = result.replacingOccurrences(of: ")", with: " ")
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if let dot = result.lastIndex(of: ".") {
            result = String(result[result.index(after: dot)...])
        }
        result = result.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        return result.isEmpty ? nil : result
    }

    private static func filenameCandidates(from className: String) -> [String] {
        var candidates: [String] = []
        var seen: Set<String> = []

        func append(_ filename: String) {
            guard !filename.isEmpty, seen.insert(filename).inserted else {
                return
            }
            candidates.append(filename)
        }

        let leaf = cleanedClassName(from: className) ?? className
        append(leaf + ".swift")

        let words = Array(splitWords(from: leaf).prefix(6))
        guard !words.isEmpty else {
            return candidates
        }
        append(words.joined() + ".swift")

        for count in 1 ... min(4, words.count) {
            for permutation in permutations(words, count: count) {
                append(permutation.joined() + ".swift")
            }
        }
        return candidates
    }

    private static func splitWords(from className: String) -> [String] {
        let range = NSRange(className.startIndex..., in: className)
        return camelCaseWordRegex.matches(in: className, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: className) else {
                return nil
            }
            return String(className[matchRange])
        }
    }

    private static func permutations(_ values: [String], count: Int) -> [[String]] {
        guard count > 0 else {
            return [[]]
        }
        guard count < values.count else {
            return [values]
        }

        var result: [[String]] = []
        func walk(_ prefix: [String], _ remaining: [String]) {
            if prefix.count == count {
                result.append(prefix)
                return
            }
            for index in remaining.indices {
                var nextRemaining = remaining
                let value = nextRemaining.remove(at: index)
                walk(prefix + [value], nextRemaining)
            }
        }
        walk([], values)
        return result
    }

    private static func privateDiscriminatorID(module: String, filename: String) -> String {
        PrivateDiscriminatorVerificationCache.privateDiscriminatorID(module: module, filename: filename)
    }

    private static let defaultLibraryModules = [
        DefaultLibraryModule(name: "SwiftUI"),
        DefaultLibraryModule(name: "SwiftUICore"),
    ]

    private func promptForModuleName(defaultModule: String?, window: NSWindow?) -> String? {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Import Private Discriminator Module", comment: "")
        alert.informativeText = NSLocalizedString("Enter the Swift module name for this source folder.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.placeholderString = NSLocalizedString("ModuleName", comment: "")
        textField.stringValue = defaultModule ?? ""
        alert.accessoryView = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        let module = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return module.isEmpty ? nil : module
    }

    private func promptForSwiftPDGuessRequest(parsed: ParsedDiscriminator, window: NSWindow?) -> GuessRequest? {
        let defaultWords = Self.defaultGuessWords(for: parsed)

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Guess with swift-pd-guess", comment: "")
        alert.informativeText = NSLocalizedString(
            "Enter a module name, comma-separated candidate words, and a maximum word count.",
            comment: ""
        )
        alert.addButton(withTitle: NSLocalizedString("Run", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

        let moduleField = NSTextField(frame: .zero)
        moduleField.placeholderString = NSLocalizedString("ModuleName", comment: "")
        moduleField.stringValue = parsed.moduleHint ?? ""

        let wordsField = NSTextField(frame: .zero)
        wordsField.placeholderString = defaultWords.joined(separator: ",")

        let maxCountField = NSTextField(frame: .zero)
        maxCountField.placeholderString = "4"

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(
            Self.labeledField(title: NSLocalizedString("Module", comment: ""), field: moduleField)
        )
        stackView.addArrangedSubview(
            Self.labeledField(title: NSLocalizedString("Words", comment: ""), field: wordsField)
        )
        stackView.addArrangedSubview(
            Self.labeledField(title: NSLocalizedString("Max Count", comment: ""), field: maxCountField)
        )
        stackView.frame = NSRect(x: 0, y: 0, width: 360, height: 108)
        alert.accessoryView = stackView

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        let module = moduleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawWords = wordsField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = rawWords.isEmpty
            ? defaultWords
            : rawWords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let maxCount = Int(maxCountField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 4

        guard PrivateDiscriminatorModuleIndex.isValidModuleName(module), !words.isEmpty else {
            return nil
        }
        return GuessRequest(module: module, words: words, maxCount: max(1, maxCount))
    }

    private static func labeledField(title: String, field: NSTextField) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.widthAnchor.constraint(equalToConstant: 72).isActive = true

        field.widthAnchor.constraint(equalToConstant: 280).isActive = true

        let row = NSStackView(views: [label, field])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        return row
    }

    private static func defaultGuessWords(for parsed: ParsedDiscriminator) -> [String] {
        var words: [String] = []
        var seen: Set<String> = []

        func append(_ word: String) {
            let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else {
                return
            }
            words.append(trimmed)
        }

        if let className = parsed.className {
            append(className)
            splitWords(from: className).forEach(append)
        }
        if words.isEmpty {
            append("_")
        }
        return words
    }

    private func swiftPDGuessExecutableURL() -> URL? {
        let fileManager = FileManager.default
        let candidates = [
            "/usr/local/bin/swift-pd-guess",
            "/opt/homebrew/bin/swift-pd-guess",
        ]
        for path in candidates where fileManager.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        let environmentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for directory in environmentPath.split(separator: ":") {
            let path = String(directory) + "/swift-pd-guess"
            if fileManager.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    private func presentSwiftPDGuessInstallAlert(window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("swift-pd-guess is not installed", comment: "")
        alert.informativeText = NSLocalizedString(
            "Download the GitHub release binary and place it at /usr/local/bin/swift-pd-guess. You may need administrator permission and chmod +x.",
            comment: ""
        )
        alert.addButton(withTitle: NSLocalizedString("Open Releases", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/OpenSwiftUIProject/swift-pd-guess/releases")!)
        }
    }

    private func finishSwiftPDGuess(id: String, module: String, process: Process, stdout: String, stderr: String) {
        activeGuessTasksByID.removeValue(forKey: id)
        if cancelledGuessIDs.remove(id) != nil {
            guessStatesByID[id] = .cancelled
            postDashboardStateDidChange()
            return
        }

        guard process.terminationStatus == 0 else {
            guessStatesByID[id] = .failed(
                stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? NSLocalizedString("swift-pd-guess failed.", comment: "")
                    : stderr
            )
            postDashboardStateDidChange()
            return
        }

        guard let rawMatch = Self.parseSwiftPDGuessMatch(from: stdout, module: module) else {
            guessStatesByID[id] = .failed(NSLocalizedString("No match found.", comment: ""))
            postDashboardStateDidChange()
            return
        }

        let verification = verificationCache.verify(id: id, module: module, filename: rawMatch)
        guard verification.isMatch else {
            guessStatesByID[id] = .failed(Self.message(for: verification))
            postDashboardStateDidChange()
            return
        }

        do {
            try saveRecord(
                id: id,
                module: module,
                filename: rawMatch,
                author: .imported
            )
            guessStatesByID[id] = .succeeded(
                String(format: NSLocalizedString("Success: %@", comment: ""), rawMatch)
            )
        } catch {
            guessStatesByID[id] = .failed(
                String(
                    format: NSLocalizedString("Found %@, but save failed: %@", comment: ""),
                    rawMatch,
                    error.localizedDescription
                )
            )
        }
        postDashboardStateDidChange()
    }

    private static func parseSwiftPDGuessMatch(from output: String, module: String) -> String? {
        for line in output.components(separatedBy: .newlines) {
            let prefix = "Found match:"
            guard line.hasPrefix(prefix) else {
                continue
            }
            var value = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            value = URL(fileURLWithPath: value).lastPathComponent
            if value.hasPrefix(module) {
                value.removeFirst(module.count)
            }
            return value.isEmpty ? nil : value
        }
        return nil
    }

    private static func message(for verification: PrivateDiscriminatorVerificationResult) -> String {
        switch verification.failureReason {
        case .invalidID:
            return NSLocalizedString("Invalid private discriminator ID.", comment: "")
        case .invalidModuleName:
            return NSLocalizedString("Invalid module name.", comment: "")
        case .invalidFilename:
            return NSLocalizedString("Invalid basename-only filename.", comment: "")
        case .mismatch:
            return NSLocalizedString("Verification failed: module + filename does not produce this ID.", comment: "")
        case nil:
            return NSLocalizedString("Verified.", comment: "")
        }
    }

    private func postDashboardStateDidChange() {
        NotificationCenter.default.post(name: Self.dashboardStateDidChangeNotification, object: self)
    }

    private static var dashboardTitle: String {
        NSLocalizedString("Private Discriminator", comment: "")
    }
    private static let dashboardAttributeIdentifier = "lookinside.private_discriminator.field"
    private static let dashboardStateDidChangeNotification = Notification.Name("LKPrivateDiscriminatorDashboardStateDidChange")

    private static let privateIDRegex = try! NSRegularExpression(pattern: #"\$?([0-9A-Fa-f]{32})"#)
    private static let modulePrefixRegex = try! NSRegularExpression(pattern: #"\b([A-Za-z_][A-Za-z0-9_]*)\."#)
    private static let genericParameterRegex = try! NSRegularExpression(pattern: #"<[^<>]*>"#)
    private static let camelCaseWordRegex = try! NSRegularExpression(pattern: #"[A-Z]+(?=[A-Z][a-z]|[0-9]|\b)|[A-Z]?[a-z]+|[0-9]+"#)
    private static let privateDisplayCleanupRegexes = [
        try! NSRegularExpression(pattern: #"\s*\(\s*in\s+\$?[0-9A-Fa-f]{32}\s*\)"#, options: [.caseInsensitive]),
        try! NSRegularExpression(pattern: #"\s+\bin\s+\$?[0-9A-Fa-f]{32}\b"#, options: [.caseInsensitive]),
    ]
}

private struct Configuration: Codable, Equatable {
    var featureEnabled = false
    var autosaveEnabled = false
    var disabledModules: [String] = []
    var importSources: [String: String] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        featureEnabled = try container.decodeIfPresent(Bool.self, forKey: .featureEnabled) ?? false
        autosaveEnabled = try container.decodeIfPresent(Bool.self, forKey: .autosaveEnabled) ?? false
        disabledModules = try container.decodeIfPresent([String].self, forKey: .disabledModules) ?? []
        importSources = try container.decodeIfPresent([String: String].self, forKey: .importSources) ?? [:]
    }

    func normalized() -> Configuration {
        var copy = self
        copy.disabledModules = Array(Set(disabledModules)).sorted()
        copy.importSources = Dictionary(uniqueKeysWithValues: importSources.sorted { $0.key < $1.key })
        return copy
    }
}

private struct LoadedModuleIndex {
    enum Source: String {
        case imported
        case autosaved
        case fallback

        var localizedDisplayName: String {
            switch self {
            case .imported:
                return NSLocalizedString("imported", comment: "")
            case .autosaved:
                return NSLocalizedString("autosaved", comment: "")
            case .fallback:
                return NSLocalizedString("fallback", comment: "")
            }
        }
    }

    let source: Source
    let index: PrivateDiscriminatorModuleIndex
}

private struct DefaultLibraryModule {
    let name: String

    var url: URL {
        URL(string: "https://raw.githubusercontent.com/LookInsideApp/LookInsidePrivateDiscriminator/main/Resources/PrivateDiscriminator/\(name).csv")!
    }
}

private struct DefaultLibraryDownload {
    let module: String
    let recordCount: Int
    let csvText: String
}

private struct DefaultLibraryUpdateResult {
    let module: String
    let recordCount: Int
    let didChange: Bool
}

private struct ParsedDiscriminator {
    let id: String
    let moduleHint: String?
    let className: String?
}

private struct DashboardDescriptor {
    let id: String
    let module: String
    let filename: String
    let source: LoadedModuleIndex.Source?
    let isMatched: Bool
    let isVerified: Bool
    let warning: String?
    let className: String?
    let guessState: GuessState?
}

private struct GuessRequest {
    let module: String
    let words: [String]
    let maxCount: Int
}

private enum GuessState {
    case running
    case succeeded(String)
    case failed(String)
    case cancelled

    var statusText: String {
        switch self {
        case .running:
            return NSLocalizedString("Running swift-pd-guess…", comment: "")
        case let .succeeded(message):
            return message
        case let .failed(message):
            return String(format: NSLocalizedString("Failed: %@", comment: ""), message)
        case .cancelled:
            return NSLocalizedString("Cancelled.", comment: "")
        }
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }
}

@objc(LKPrivateDiscriminatorDashboardPayload)
final class LKPrivateDiscriminatorDashboardPayload: NSObject {
    @objc let discriminatorID: String
    @objc let module: String
    @objc let filename: String
    @objc let source: String
    @objc let displayClassName: String
    @objc let isMatched: Bool
    @objc let isVerified: Bool
    @objc let warningText: String?
    @objc let guessStatusText: String?
    @objc let isGuessRunning: Bool
    @objc let isGuessFailed: Bool

    fileprivate init(descriptor: DashboardDescriptor) {
        discriminatorID = descriptor.id
        module = descriptor.module
        filename = descriptor.filename
        source = descriptor.source?.localizedDisplayName ?? ""
        displayClassName = descriptor.className ?? ""
        isMatched = descriptor.isMatched
        isVerified = descriptor.isVerified
        warningText = descriptor.warning
        guessStatusText = descriptor.guessState?.statusText
        isGuessRunning = descriptor.guessState?.isRunning ?? false
        isGuessFailed = descriptor.guessState?.isFailed ?? false
        super.init()
    }
}

private struct ModuleStatusBuilder {
    let module: String
    var importedCSVPath: String?
    var autosavedCSVPath: String?
    var sourceFolderPath: String?
    var importedRecordCount: Int?
    var autosavedRecordCount: Int?
    var diagnostics: [String] = []

    func status(disabledModules: Set<String>) -> LKPrivateDiscriminatorModuleStatus {
        LKPrivateDiscriminatorModuleStatus(
            module: module,
            isEnabled: !disabledModules.contains(module),
            importedCSVPath: importedCSVPath,
            autosavedCSVPath: autosavedCSVPath,
            sourceFolderPath: sourceFolderPath,
            importedRecordCount: importedRecordCount,
            autosavedRecordCount: autosavedRecordCount,
            diagnostic: diagnostics.first
        )
    }
}

private enum LKPrivateDiscriminatorStoreError: LocalizedError {
    case invalidModuleName(String)
    case unreadableFolder(String)
    case missingImportSource(String)
    case missingPrivateDiscriminator
    case verificationFailed(String)
    case defaultLibraryDownloadFailed(String, String)

    var errorDescription: String? {
        switch self {
        case let .invalidModuleName(module):
            return String(format: NSLocalizedString("Invalid module name: %@", comment: ""), module)
        case let .unreadableFolder(path):
            return String(format: NSLocalizedString("Unable to read Swift files in %@.", comment: ""), path)
        case let .missingImportSource(module):
            return String(
                format: NSLocalizedString("No saved source folder for %@. Import it once before reimporting.", comment: ""),
                module
            )
        case .missingPrivateDiscriminator:
            return NSLocalizedString("No private discriminator ID found for this item.", comment: "")
        case let .verificationFailed(message):
            return message
        case let .defaultLibraryDownloadFailed(module, message):
            return String(
                format: NSLocalizedString("Failed to download %@: %@", comment: ""),
                module,
                message
            )
        }
    }
}
