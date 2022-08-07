/*
 * DbEntry.swift
 * Created by François Lamboley on 2022/08/06.
 */

import Foundation

import CryptoKit



struct DbEntry : Codable {
	
	/** The path relative to the db location. */
	var relativePath: String
	
	var size: Int
//	var checksum: any Digest
	var checksumAlpgo: ChecksumAlgo
	
	enum ChecksumAlgo : Int, Codable {
		
		case sha256
		
	}
	
}
