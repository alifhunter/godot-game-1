extends Node

const PRODUCT_NAME := "Buy High Sell Low Stock Trading Simulator"
const VERSION := "0.1.0-ea"
const BUILD_NUMBER := "2026.05.24.1"
const BUILD_CHANNEL := "Steam Platform RC"
const BUILD_DATE := "2026-05-24"


func get_product_name() -> String:
	return PRODUCT_NAME


func get_version_string() -> String:
	return VERSION


func get_build_number() -> String:
	return BUILD_NUMBER


func get_build_channel() -> String:
	return BUILD_CHANNEL


func get_build_date() -> String:
	return BUILD_DATE


func get_short_display_string() -> String:
	return "Build %s" % BUILD_NUMBER


func get_display_string() -> String:
	return "%s %s  |  Build %s" % [PRODUCT_NAME, VERSION, BUILD_NUMBER]


func get_bug_report_context() -> String:
	return "%s\nChannel: %s\nBuild date: %s" % [
		get_display_string(),
		BUILD_CHANNEL,
		BUILD_DATE
	]
