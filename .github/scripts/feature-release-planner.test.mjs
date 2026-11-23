import assert from "node:assert/strict";
import { test } from "node:test";
import { FeatureReleasePlanner } from "./feature-release-planner.mjs";

const repository = { owner: "example", repo: "features" };
const published = { id: "asdf", version: "1.0.0" };
const unpublished = { id: "another-feature", version: "2.0.0" };
const github = {
	rest: {
		git: {
			async getRef({ ref }) {
				if (ref === "tags/feature_asdf_1.0.0") return { data: {} };
				throw Object.assign(new Error("Not found"), { status: 404 });
			},
		},
	},
};

test("plans only unpublished feature versions using the publisher's tag convention", async () => {
	const planner = new FeatureReleasePlanner(github, repository);
	assert.deepEqual(await planner.plan([published, unpublished]), [
		{ ...unpublished, tag: "feature_another-feature_2.0.0" },
	]);
});

test("scheduled runs have no release when every declared version is already published", async () => {
	const planner = new FeatureReleasePlanner(github, repository);
	assert.deepEqual(await planner.plan([published]), []);
});

test("API failures fail planning instead of treating a published version as new", async () => {
	const failure = Object.assign(new Error("Forbidden"), { status: 403 });
	const unavailableGithub = {
		rest: {
			git: {
				getRef: async () => {
					throw failure;
				},
			},
		},
	};
	const planner = new FeatureReleasePlanner(unavailableGithub, repository);
	await assert.rejects(planner.plan([published]), failure);
});

test("rejects metadata without a feature version before planning a release", async () => {
	const planner = new FeatureReleasePlanner(github, repository);
	await assert.rejects(
		planner.plan([{ id: "asdf" }]),
		/must declare an id and version/,
	);
});
