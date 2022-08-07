/*
 *  Errors.swift
 * Created by François Lamboley on 2022/08/07.
 */

import Foundation



enum LtsCheckError : Error {
	
	case invalidDbHeader
	case unsupportedDbVersion
	case duplicatePathInDb(String)
	
	case cannotGetFileSize
	case cannotGetCreationDate
	case cannotGetDirectoryStatus
	case cannotGetSymbolicLinkStatus
	
	case cannotEnumerateFiles
	case cannotGetRelativePath
	
	case internalError
	
}

typealias Err = LtsCheckError
