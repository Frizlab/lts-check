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
	
	enum Action : String, ExpressibleByArgument {
		
		/** Only list the files in the db, one path per line. */
		case listFiles
		
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
		case checkAndUpdate
		/**
		 Check the db and add new files, and update files that are found to be inconsistent with the db.
		 
		 Essentially the same as checking the db, then re-running the tool with the `rebuild` action,
		  except the files already in the db and consistent are only read once.
		 
		 Files that are missing from the fs _are_ removed from the db. */
		case checkAndUpdateWithOverride
		
		/** If a file is in the db but missing on the fs, remove it from the db. */
		case removeMissingFiles
		
	}
	
	enum CheckMode : String, ExpressibleByArgument {
		
		/** Verify the files existence, their properties (size, modification date, other) and their checksums. */
		case full
		/** Check the files existence and their properties, but ignore the data. */
		case properties
		/** Only check the files existence. */
		case existence

	}
	
	static /*lazy*/ var logger: Logger = {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		
		var ret = Logger(label: "main")
		ret.logLevel = .debug
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
	 
	 The matching is done on the full relative path, which is always guaranteed to start with “`./`”. */
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
	
	@Argument
	var dbFilePath: String
	
	@Argument
	var checkedPaths: [String]
	
	func run() async throws {
		if #available(macOS 13, *) {
			Self.logger.info("Note to the dev: use Regex instead of NSRegularExpression!")
		}
		
		print(dbFilePath)
		print(checkedPaths)
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
