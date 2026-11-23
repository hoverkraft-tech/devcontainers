# asdf (asdf)

A feature to install asdf (after changes of 0.16.0 version)

## Example Usage

```json
"features": {
    "ghcr.io/hoverkraft-tech/devcontainers/asdf:1": {}
}
```

## Options

| Options ID   | Description                        | Type   | Default Value |
| ------------ | ---------------------------------- | ------ | ------------- |
| asdf_version | Version of asdf binary to install. | string | latest        |

<!-- Included verbatim in the generated feature README. -->
<!-- jscpd:ignore-start -->
<!-- markdownlint-disable MD041 -->

## Using the asdf feature

Add `ghcr.io/hoverkraft-tech/devcontainers/asdf:1` to your dev container's
`features` object, then rebuild the container. The feature installs asdf and
adds its shims to the shell's `PATH`.

The default `asdf_version` is `latest`. To select an asdf release explicitly:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/hoverkraft-tech/devcontainers/asdf:1": {
      "asdf_version": "v0.17.0"
    }
  }
}
```

See the options above for the complete feature configuration.
The tag after `asdf:` selects the feature version; `asdf_version` selects the
installed asdf binary.

To use a private copy of a feature from GitHub Codespaces, grant the codespace
access to its source repository and packages:

```json
{
  "customizations": {
    "codespaces": {
      "repositories": {
        "your-organization/your-features": {
          "permissions": {
            "packages": "read",
            "contents": "read"
          }
        }
      }
    }
  }
}
```

Other clients need registry credentials with read access to the package.

<!-- jscpd:ignore-end -->

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/hoverkraft-tech/devcontainers/blob/main/src/asdf/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
