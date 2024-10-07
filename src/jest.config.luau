type Serialize = (
	value: unknown,
	config: unknown,
	indentation: number,
	depth: number,
	references: unknown,
	printer: Serialize
) -> string
type Serializer = {
	serialize: Serialize,
	test: (value: unknown) -> boolean,
}
type JestConfiguration = {
	clearmocks: boolean?,
	displayName: {
		color: string,
		name: string,
	} | nil | string,
	projects: {Instance}?,
	rootDir: Instance?,
	setupFiles: {ModuleScript}?,
	setupFilesAfterEnv: {ModuleScript}?,
	slowTestThreshold: number?,
	snapshotFormat: {
		callToJSON: boolean?,
		escapeRegex: boolean?,
		escapeString: boolean?,
		highlight: boolean?,
		indent: number?,
		maxDepth: number?,
		maxWidth: number?,
		min: boolean?,
		printBasicPrototype: boolean?,
		printFunctionName: boolean?,
		printInstanceDefaults: boolean?,
		theme: {[string]: string}?,
	}?,
	snapshotSerializers: {Serializer}?,
	testFailureExitCode: number?,
	testMatch: {string}?,
	testPathIgnorePatterns: {string}?,
	testRegex: {{string} | string}?,
	testTimeout: number?,
	verbose: boolean?,
}

local JestConfiguration: JestConfiguration = {
	displayName = "DataStructures";
	testMatch = {"**/__tests__/*.test"};
}
return JestConfiguration
