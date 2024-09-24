--!optimize 2
--!strict

local GreenTea = require("@packages/GreenTea")
local PathFileSystem = require("@packages/PathFileSystem")
local serde = require("@lune/serde")

export type Result<T, E> = {
	Success: true,
	Value: T,
} | {
	Success: false,
	Error: E,
}

local isWallyPackage = GreenTea.build({
	dependencies = GreenTea.optional({[GreenTea.string()] = GreenTea.string()});
	["dev-dependencies"] = GreenTea.optional({[GreenTea.string()] = GreenTea.string()});
	["server-dependencies"] = GreenTea.optional({[GreenTea.string()] = GreenTea.string()});
	package = {
		authors = GreenTea.optional(GreenTea.array(GreenTea.string()));
		description = GreenTea.optional(GreenTea.string());
		exclude = GreenTea.optional(GreenTea.array(GreenTea.string()));
		include = GreenTea.optional(GreenTea.array(GreenTea.string()));
		license = GreenTea.optional(GreenTea.union(GreenTea.literal("MIT"), GreenTea.literal("Apache-2.0"))) :: nil | "MIT" | "Apache-2.0";
		name = GreenTea.string();
		private = GreenTea.optional(GreenTea.boolean());
		realm = GreenTea.union(GreenTea.literal("shared"), GreenTea.literal("server")) :: "shared" | "server";
		registry = GreenTea.string();
		version = GreenTea.string();
	};
})
type WallyPackage = typeof(isWallyPackage:type())

local WALLY_TOML_PATH = PathFileSystem.Path.new("wally.toml")

local function ReadWallyToml(): Result<WallyPackage, string>
	if not PathFileSystem.IsFileSafe(WALLY_TOML_PATH) then
		return {
			Success = false;
			Error = `Failed to read {WALLY_TOML_PATH} (not a file)`;
		}
	end

	local readSuccess, fileSource = pcall(PathFileSystem.ReadFile, WALLY_TOML_PATH)
	if not readSuccess then
		return {
			Success = false;
			Error = `Failed to read {WALLY_TOML_PATH} - {fileSource}`;
		}
	end

	local decodeSuccess, toml: WallyPackage = pcall(serde.decode, "toml" :: "toml", fileSource)
	if not decodeSuccess then
		return {
			Success = false;
			Error = `Failed to decode {WALLY_TOML_PATH} - {toml}`;
		}
	end

	local typeSuccess, typeError = isWallyPackage:matches(toml)
	if not typeSuccess then
		return {
			Success = false;
			Error = `Failed to type check {WALLY_TOML_PATH} - {typeError}`;
		}
	end

	return {
		Success = true;
		Value = toml;
	}
end

return ReadWallyToml
