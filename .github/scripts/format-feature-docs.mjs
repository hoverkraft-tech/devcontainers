import { readdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { format } from "prettier";

for (const entry of await readdir("src", { withFileTypes: true })) {
	if (!entry.isDirectory()) continue;
	const path = join("src", entry.name, "README.md");
	const markdown = await readFile(path, "utf8");
	// The official generator's table header violates the shared terminology rule.
	const formatted = await format(
		markdown.replace("| Options Id |", "| Options ID |"),
		{
			parser: "markdown",
		},
	);
	await writeFile(path, formatted);
}
