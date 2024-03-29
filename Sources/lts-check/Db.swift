/*
 * Db.swift
 * Created by François Lamboley on 2022/08/06.
 */

import Foundation

import StreamReader
import SwiftyRelativePath



struct Db {
	
	/** Keys are relative paths. */
	var entries: [String: DbEntry] = [:]
	
	init(entries: [String: DbEntry] = [:]) {
		self.entries = entries
	}
	
	init(dbPath: String) throws {
		guard FileManager.default.fileExists(atPath: dbPath) else {
			self.init(entries: [:])
			return
		}
		
		let fh = try FileHandle(forReadingFrom: URL(fileURLWithPath: dbPath))
		try self.init(stream: FileHandleReader(stream: fh, bufferSize: 5 * 1024 * 1024, bufferSizeIncrement: 3 * 1024 * 1024))
	}
	
	init(stream: StreamReader) throws {
		let jsonDecoder = JSONDecoder()
		
		/* Parse the header (standard 4-char for a file type). */
		let header = try stream.readData(size: Self.header.count, allowReadingLess: true)
		guard header.isEmpty || header == Self.header else {
			throw Err.invalidDbHeader
		}
		guard !header.isEmpty else {
			return
		}
		
		/* Parse the version info (a JSON). */
		let versionInfo = try stream.readData(upTo: [Self.separator], matchingMode: .anyMatchWins, includeDelimiter: false).data
		_ = try stream.readData(size: Self.separator.count)
		guard try jsonDecoder.decode(VersionInfo.self, from: versionInfo).version == Self.currentVersion else {
			throw Err.unsupportedDbVersion
		}
		
		/* Parse the entries. */
		while try !stream.peekData(size: 1, allowReadingLess: true).isEmpty {
			let entryData = try stream.readData(upTo: [Self.separator], matchingMode: .anyMatchWins, includeDelimiter: false).data
			_ = try stream.readData(size: Self.separator.count)
			let entry = try jsonDecoder.decode(DbEntry.self, from: entryData)
			guard entries[entry.relativePath] == nil else {
				throw Err.duplicatePathInDb(entry.relativePath)
			}
			entries[entry.relativePath] = entry
		}
	}
	
	func write(to dbPath: String) throws {
		let fm = FileManager.default
		if fm.fileExists(atPath: dbPath) {try fm.removeItem(atPath: dbPath)}
		fm.createFile(atPath: dbPath, contents: nil)
		
		let fh = try FileHandle(forWritingTo: URL(fileURLWithPath: dbPath))
		try write(to: fh)
	}
	
	func write(to stream: FileHandle) throws {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
		
		try stream.write(contentsOf: Self.header)
		
		try stream.write(contentsOf: jsonEncoder.encode(VersionInfo(version: Self.currentVersion)))
		try stream.write(contentsOf: Self.separator)
		
		for (_, entry) in entries {
			try stream.write(contentsOf: jsonEncoder.encode(entry))
			try stream.write(contentsOf: Self.separator)
		}
	}
	
	@discardableResult
	mutating func addEntries(from checkedPaths: [String], relativeRef: URL, pathRegexFilter: NSRegularExpression?, negativePathRegexFilter: NSRegularExpression?) throws -> Int {
		return try checkedPaths.reduce(0, { try $0 + addEntries(from: $1, relativeRef: relativeRef, pathRegexFilter: pathRegexFilter, negativePathRegexFilter: negativePathRegexFilter) })
	}
	
	@discardableResult
	mutating func addEntries(from checkedPath: String, relativeRef originalRelativeRef: URL, pathRegexFilter: NSRegularExpression?, negativePathRegexFilter: NSRegularExpression?) throws -> Int {
		let relativeRef: URL
		let originalRelativeRefIsDir = (try? originalRelativeRef.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
		if !originalRelativeRefIsDir {
			relativeRef = originalRelativeRef.deletingLastPathComponent()
			guard let parentIsDir = try relativeRef.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
				throw Err.cannotGetDirectoryStatus
			}
			guard parentIsDir else {
				throw Err.internalError
			}
		} else {
			relativeRef = originalRelativeRef
		}
		
		let fm = FileManager.default
		guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: checkedPath), includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .creationDateKey]) else {
			throw Err.cannotEnumerateFiles
		}
		var res = 0
		for case let fileURL as URL in enumerator {
			let isDirectory = try fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
			guard let isLink = try fileURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink else {
				throw Err.cannotGetSymbolicLinkStatus
			}
			guard !isLink else {
				LtsCheck.logger.trace("Skipping link", metadata: ["path": "\(fileURL.path)"])
				continue
			}
			
			guard let unModifiedRelativePath = fileURL.absoluteURL.relativePath(from: relativeRef.absoluteURL) else {
				throw Err.cannotGetRelativePath
			}
			assert(!unModifiedRelativePath.hasPrefix("/"))
			let addSlash = isDirectory && !unModifiedRelativePath.hasSuffix("/")
			let relativePath: String
			if !unModifiedRelativePath.hasPrefix("../") {
				relativePath = "./" + unModifiedRelativePath + (addSlash ? "/" : "")
			} else {
				relativePath = unModifiedRelativePath + (addSlash ? "/" : "")
			}
			
			let relativePathNSRange = NSRange(location: 0, length: (relativePath as NSString).length)
			guard pathRegexFilter?.firstMatch(in: relativePath, range: relativePathNSRange) != nil || pathRegexFilter == nil,
					negativePathRegexFilter?.firstMatch(in: relativePath, range: relativePathNSRange) == nil
			else {
				LtsCheck.logger.trace("Skipping file", metadata: ["path": "\(relativePath)"])
				if isDirectory {
					enumerator.skipDescendants()
				}
				continue
			}
			
			guard !isDirectory, entries[relativePath] == nil else {
				continue
			}
			
			LtsCheck.logger.debug("Computing and adding entry", metadata: ["path": "\(relativePath)"])
			let entry = try DbEntry(relativePath: relativePath, relativeRef: relativeRef)
			entries[relativePath] = entry
			res += 1
		}
		return res
	}
	
	private static let currentVersion = 1
	private static let header = Data("LTSC\n".utf8)
	private static let separator = Data([0xff] + "\n".utf8)
	
	private struct VersionInfo : Codable {
		
		var version: Int
		
	}
	
}
