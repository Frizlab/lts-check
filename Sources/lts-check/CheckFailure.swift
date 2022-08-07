/*
 * CheckFailure.swift
 * Created by François Lamboley on 2022/08/07.
 */

import Foundation



enum CheckFailure : Equatable {
	
	case existence
	case size(expected: Int, actual: Int)
	case creationDate(expected: Date, actual: Date)
	case checksum(algo: DbEntry.ChecksumAlgo, expected: String, actual: String)
	
}
