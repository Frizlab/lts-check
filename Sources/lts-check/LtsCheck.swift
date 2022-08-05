import Foundation

import ArgumentParser
import CLTLogger
import Logging



@main
struct LtsCheck : AsyncParsableCommand {
	
	static /*lazy*/ var logger: Logger = {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		
		var ret = Logger(label: "main")
		ret.logLevel = .debug
		return ret
	}()
	
	@Option @RegexByArg
	var pathRegexFilter: NSRegularExpression? = nil
	
	func run() async throws {
		if #available(macOS 13, *) {
			Self.logger.info("Note to the dev: use Regex instead of NSRegularExpression!")
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
