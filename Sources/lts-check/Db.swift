/*
 * Db.swift
 * Created by François Lamboley on 2022/08/06.
 */

import Foundation

import StreamReader



struct Db {
	
	/** Keys are relative paths. */
	var entries: [String: DbEntry] = [:]
	
}
