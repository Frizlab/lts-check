/*
 * DbEntry.swift
 * Created by François Lamboley on 2022/08/06.
 */

import CryptoKit
import Foundation

import StreamReader



struct DbEntry : Codable {
	
	enum ChecksumAlgo : String, Equatable, Codable, CustomStringConvertible {
		
		case sha256
		
		var description: String {
			return rawValue
		}
		
	}
	
	/** The path relative to the db location. */
	var relativePath: String
	
	var size: Int
	var creationDate: Date
	
	var checksum: String
	var checksumAlgo: ChecksumAlgo
	
	init(relativePath: String, relativeRef: URL) throws {
		let url = URL(fileURLWithPath: relativePath, relativeTo: relativeRef)
		
		let properties = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
		guard let s = properties.fileSize else {throw Err.cannotGetFileSize}
		guard let cd = properties.creationDate else {throw Err.cannotGetCreationDate}
		
		/* TODO: relative path computation */
		self.relativePath = relativePath
		
		self.size = s
		self.creationDate = cd
		
		self.checksumAlgo = .sha256
		self.checksum = try Self.computeChecksum(of: url, algo: checksumAlgo)
	}
	
	/** Returns `nil` if the check does not fail. */
	func check(mode: CheckMode, relativeRef: URL) throws -> CheckFailure? {
		let checkedURL = URL(fileURLWithPath: relativePath, relativeTo: relativeRef)
		if mode.checkExistence {
			var isDir = ObjCBool(true)
			guard FileManager.default.fileExists(atPath: checkedURL.path, isDirectory: &isDir),
					!isDir.boolValue
			else {
				return .existence
			}
		}
		if mode.checkProperties {
			let properties = try checkedURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
			guard let actualSize = properties.fileSize else {
				throw Err.cannotGetFileSize
			}
			guard actualSize == size else {
				return .size(expected: size, actual: actualSize)
			}
			guard let actualCreationDate = properties.creationDate else {
				throw Err.cannotGetCreationDate
			}
			guard actualCreationDate == creationDate else {
				return .creationDate(expected: creationDate, actual: actualCreationDate)
			}
		}
		if mode.checkData {
			let actualChecksum = try Self.computeChecksum(of: checkedURL, algo: checksumAlgo)
			guard actualChecksum == checksum else {
				return .checksum(algo: checksumAlgo, expected: checksum, actual: actualChecksum)
			}
		}
		return nil
	}
	
	private static func computeChecksum(of url: URL, algo: ChecksumAlgo) throws -> String {
		switch algo {
			case .sha256:
				var hasher = SHA256()
				let bufferSize = 512 * 1024 * 1024
				let reader = try FileHandleReader(stream: FileHandle(forReadingFrom: url), bufferSize: bufferSize, bufferSizeIncrement: 1/* 0 is not allowed. */)
				var count = 0
				repeat {
					try autoreleasepool{
						count = try reader.readData(size: bufferSize, allowReadingLess: true, { hasher.update(bufferPointer: $0); return $0.count })
					}
				} while count > 0
				return hasher.finalize().reduce("", { $0 + String(format: "%02x", $1) }).lowercased()
		}
	}
	
}
