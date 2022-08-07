/*
 * Helpers.swift
 * Created by François Lamboley on 2022/08/07.
 */

import Foundation
import XCTest



extension XCTestCase {
	
	/** Important: I think this function only works if the output is not too big… */
	func runTargetExecutable(_ name: String, args: String...) throws -> (Int32, Process.TerminationReason, Data, Data) {
		/* Mac Catalyst won't have `Process`, but it is supported for executables. */
#if !targetEnvironment(macCatalyst)
		let binaryURL = productsDirectory.appendingPathComponent(name)
		
		let process = Process()
//		if #available(macOS 13.0, *) {
//			process.currentDirectoryURL = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appending(component: "TestsData", directoryHint: .isDirectory)
//		} else {
			process.currentDirectoryURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData")
//		}
		process.executableURL = binaryURL
		process.arguments = args
		
		let pipeStdout = Pipe()
		let pipeStderr = Pipe()
		process.standardOutput = pipeStdout
		process.standardError = pipeStderr
		process.standardInput = nil
		
		try process.run()
		process.waitUntilExit()
		
		let stdoutdata = pipeStdout.fileHandleForReading.readDataToEndOfFile()
		let stderrdata = pipeStderr.fileHandleForReading.readDataToEndOfFile()
		return (process.terminationStatus, process.terminationReason, stdoutdata, stderrdata)
#else
		struct NoProcessClass : Error, LocalizedError {var errorDescription: String {"This test must not run on macCatalyst as macCatalyst does not have access to the Process class."}}
		throw NoProcessClass()
#endif
	}
	
	/** Returns path to the built products directory. */
	private var productsDirectory: URL {
#if os(macOS)
		for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
			return bundle.bundleURL.deletingLastPathComponent()
		}
		fatalError("couldn't find the products directory")
#else
		return Bundle.main.bundleURL
#endif
	}
	
}
