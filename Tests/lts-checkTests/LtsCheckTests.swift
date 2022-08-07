/*
 * LtsCheckTests.swift
 * Created by François Lamboley on 2022/07/23.
 */

import XCTest
import class Foundation.Bundle



final class LtsCheckTests : XCTestCase {
	
	func testExample() throws {
		let (exitCode, exitReason, stdout, stderr) = try runTargetExecutable("lts-check")
		XCTAssertTrue(stdout.isEmpty)
		XCTAssertFalse(stderr.isEmpty)
		XCTAssertEqual(exitReason, .exit)
		XCTAssertNotEqual(exitCode, 0)
	}
	
}
