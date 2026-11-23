export class FeatureReleasePlanner {
	constructor(github, repository) {
		this.github = github;
		this.repository = repository;
	}

	async plan(features) {
		const releases = [];
		for (const { id, version } of features) {
			if (
				typeof id !== "string" ||
				!id.trim() ||
				typeof version !== "string" ||
				!version.trim()
			) {
				throw new Error("Each feature must declare an id and version.");
			}
			// Match the immutable version tags created by devcontainers/action.
			const tag = `feature_${id}_${version}`;
			try {
				await this.github.rest.git.getRef({
					...this.repository,
					ref: `tags/${tag}`,
				});
			} catch (error) {
				if (error.status !== 404) throw error;
				releases.push({ id, version, tag });
			}
		}
		return releases;
	}
}
