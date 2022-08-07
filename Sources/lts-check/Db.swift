/*
 * Db.swift
 * Created by François Lamboley on 2022/08/06.
 */

import Foundation

import StreamReader



struct Db {
	
	/** Keys are relative paths. */
	var entries: [String: DbEntry] = [:]
	
	init(entries: [String: DbEntry]) {
		self.entries = entries
	}
	
	init(dbPath: String) throws {
		guard FileManager.default.fileExists(atPath: dbPath) else {
			self.init(entries: [:])
			return
		}
		
		let fh = try FileHandle(forReadingFrom: URL(fileURLWithPath: dbPath))
		try self.init(stream: FileHandleReader(stream: fh, bufferSize: 1024, bufferSizeIncrement: 512))
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
		if !fm.fileExists(atPath: dbPath) {
			fm.createFile(atPath: dbPath, contents: nil)
		}
		
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
	
	private static let currentVersion = 1
	private static let header = Data("LTSC\n".utf8)
	private static let separator = Data([0xff] + "\n".utf8)
	
	private struct VersionInfo : Codable {
		
		var version: Int
		
	}
	
}
