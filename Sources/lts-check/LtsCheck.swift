import Foundation

import ArgumentParser



@main
struct LtsCheck : AsyncParsableCommand {
	
	@Argument
	var regexFilter: Regex<String>?
	
	func run() async throws {
	}
	
}


extension Regex : ExpressibleByArgument {
	
	public init?(argument: String) {
		guard let r = try? Self.init(argument) else {
			return nil
		}
		self = r
	}
	
}
