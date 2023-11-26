/*
 * LtsCheck.swift
 * Created by François Lamboley on 2022/07/23.
 */

import Foundation

import ArgumentParser
import CLTLogger
import Logging



@main
struct LtsCheck : AsyncParsableCommand {
	
	enum Action : String, CaseIterable, ExpressibleByArgument {
		
		/** Only list the files in the db, one path per line. */
		case listFiles = "list-files"
		
		/**
		 Only check the db; report inconsistencies w/ actual files.
		 
		 Files missing in the db are not reported. */
		case check
		/**
		 Re-create the db from scratch; ignore the current db.
		 
		 Essentially the same as deleting the db manually and run the tool w/ checkAndUpdate. */
		case rebuild
		/**
		 Check the db and add new files.
		 
		 Files missing in the fs are reported as missing and _not_ removed from the db. */
		case checkAndUpdate = "check-and-update"
		/**
		 Check the db and add new files, and update files that are found to be inconsistent with the db.
		 
		 Essentially the same as checking the db, then re-running the tool with the `rebuild` action,
		  except the files already in the db and consistent are only read once.
		 
		 Files that are missing from the fs _are_ removed from the db. */
		case checkAndUpdateWithOverride = "check-and-update-with-override"
		
		/** If a file is in the db but missing on the fs, remove it from the db. */
		case removeMissingFiles = "remove-missing-files"
		
	}
	
	static /*lazy*/ var logger: Logger = {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		
		var ret = Logger(label: "main")
		ret.logLevel = .info
		return ret
	}()
	
	@Flag
	var verbose: Bool = false
	
	@Option
	var action: Action = .checkAndUpdate
	
	@Option
	var checkMode: CheckMode = .full
	
	/**
	 Only files matching the regex are considered.
	 If the regex is `nil`, all files are considered.
	 
	 The matching is done on the full relative path, which is always guaranteed to start with “`./`”.
	 If the relative path is a directory, the path is guaranteed to end with a slash.
	 
	 - Important: If a directory do not match, all of its descendants will be skipped. */
	@Option @RegexByArg
	var pathRegexFilter: NSRegularExpression? = nil
	
	/** Of all the files matching the ``pathRegexFilter``, only those _not_ matching this regex are considered. */
	@Option @RegexByArg
	var negativePathRegexFilter: NSRegularExpression? = nil
	
	/**
	 All paths will be relative to this one.
	 If set to `nil`, will be equal to the db file path. */
	@Option
	var forcedRelativeReference: String?
	
	@Argument(completion: .file(extensions: ["ltsc"]))
	var dbFilePath: String
	
	@Argument(completion: .directory)
	var checkedPaths: [String]
	
	func run() async throws {
		if verbose {
			Self.logger.logLevel = .debug
		}
		
		if #available(macOS 13, *) {
			Self.logger.info("Note to the dev: use Regex instead of NSRegularExpression!")
		}
		
		let relativeRef = URL(fileURLWithPath: forcedRelativeReference ?? dbFilePath)
		
		switch action {
			case .listFiles:
				let db = try Db(dbPath: dbFilePath)
				for (path, _) in db.entries.sorted(by: { $0.key < $1.key }) {
					print(path)
				}
				
			case .removeMissingFiles:
				var db = try Db(dbPath: dbFilePath)
				let fm = FileManager.default
				db.entries = db.entries.filter{ relativePath, _ in
					let url = URL(fileURLWithPath: relativePath, relativeTo: relativeRef)
					
					var isDir = ObjCBool(false)
					if !fm.fileExists(atPath: url.path, isDirectory: &isDir) || isDir.boolValue {
						Self.logger.info("Removing path from db", metadata: ["path": "\(relativePath)"])
						return false
					}
					return true
				}
				try db.write(to: dbFilePath)
				
			case .check:
				let db = try Db(dbPath: dbFilePath)
				for (_, entry) in db.entries {
					if let failure = try entry.check(mode: checkMode, relativeRef: relativeRef) {
						print("\(entry.relativePath): check failed: \(failure)")
					}
				}
				
			case .checkAndUpdateWithOverride:
				var db = try Db(dbPath: dbFilePath)
				db.entries = try db.entries.filter{ _, entry in
					if let failure = try entry.check(mode: checkMode, relativeRef: relativeRef) {
						print("\(entry.relativePath): check failed: \(failure)")
						return false
					}
					return true
				}
				try db.addEntries(from: checkedPaths, relativeRef: relativeRef, pathRegexFilter: pathRegexFilter, negativePathRegexFilter: negativePathRegexFilter)
				try db.write(to: dbFilePath)
				
			case .checkAndUpdate:
				var db = try Db(dbPath: dbFilePath)
				for (_, entry) in db.entries {
					if let failure = try entry.check(mode: checkMode, relativeRef: relativeRef) {
						print("\(entry.relativePath): check failed: \(failure)")
					}
				}
				try db.addEntries(from: checkedPaths, relativeRef: relativeRef, pathRegexFilter: pathRegexFilter, negativePathRegexFilter: negativePathRegexFilter)
				try db.write(to: dbFilePath)
				
			case .rebuild:
				var db = Db()
				try db.addEntries(from: checkedPaths, relativeRef: relativeRef, pathRegexFilter: pathRegexFilter, negativePathRegexFilter: negativePathRegexFilter)
				try db.write(to: dbFilePath)
		}
	}
	
	struct Err : Error, CustomStringConvertible {
		var message: String
		var description: String {return message}
	}
	
}


@propertyWrapper
struct RegexByArg : ExpressibleByArgument {
	
	var wrappedValue: NSRegularExpression?
	
	init(wrappedValue: NSRegularExpression?) {
		self.wrappedValue = wrappedValue
	}
	
	init?(argument: String) {
		guard let regex = try? NSRegularExpression(pattern: argument, options: []) else {
			return nil
		}
		self.wrappedValue = regex
	}
	
}
