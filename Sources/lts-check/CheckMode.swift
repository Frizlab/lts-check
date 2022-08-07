/*
 * CheckMode.swift
 * Created by François Lamboley on 2022/08/07.
 */

import Foundation

import ArgumentParser



enum CheckMode : String, ExpressibleByArgument {
	
	/** Verify the files existence, their properties (size, creation date, other) and their checksums. */
	case full
	/** Check only the contents of the file (implicitly checks the existence of the file). */
	case data
	/** Check the files existence and their properties, but ignore the data. */
	case properties
	/** Only check the files existence. */
	case existence
	
	var checkExistence: Bool {
		switch self {
			case .full, .existence:  return true
			case .data, .properties: return false
		}
	}
	
	var checkProperties: Bool {
		switch self {
			case .full, .properties: return true
			case .data, .existence:  return false
		}
	}
	
	var checkData: Bool {
		switch self {
			case .full, .data:            return true
			case .properties, .existence: return false
		}
	}
	
}
