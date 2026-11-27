# Usage guide for instructors

## Why this tool exists

ADAPT errors are often opaque. This renderer shows line level errors and supports fast iteration
before you import into ADAPT.

## Quickstart workflow

Use the same cycle every time: run, check, adjust, rerun.

- Put your problem under `private/` on your computer.
- Open the file in the renderer and set a seed.
- Render, fix issues, and repeat until it looks right.
- Import the final file into ADAPT.

## Run the renderer locally

Use the [README quick start](../README.md#quick-start) to build the Podman image and render the
bundled DNA question. You can also start with the ADAPT preview and use the local editor for
problems that need debugging.

### Native development setup

For a native setup, use Node.js 24.11 or later, Perl, and the system and Perl dependencies
listed in [Dockerfile](../Dockerfile) and [cpanfile](../cpanfile). From the renderer checkout,
install PG and build the browser assets.

```bash
git clone --depth 1 --branch PG-2.17+ https://github.com/openwebwork/pg.git lib/PG
cp conf/pg_config.yml lib/PG/conf/pg_config.yml
(cd public && npm ci)
(cd lib/PG/htdocs && npm install)
morbo -l http://127.0.0.1:3000 script/render_app
```

Copy [render_app.conf.dist](../render_app.conf.dist) to `render_app.conf` when you need local
configuration overrides.

## Reproducibility and the seed

The seed matters because it lets you reproduce a broken variant exactly. If a render looks
wrong, reuse the same seed until you have fixed the issue.

## Where files live

Files in `private/` on your computer appear inside the tool as `private/`.
For example, `private/myproblem.pg` is the same as your local file
`private/myproblem.pg`.

Use the `.pg` extension when opening or saving PG source in the editor, including source that
uses PGML. For access to the [Open Problem Library](https://github.com/openwebwork/webwork-open-problem-library),
place its checkout at `webwork-open-problem-library/` in the renderer root before building the
container or starting a native server. Its `OpenProblemLibrary/` directory appears as `Library/`
in the browser.

## Student view checks

These settings help you decide if you are debugging or reviewing what students see.

- `isInstructor`: switch between student and instructor output.
- `showHints` and `showSolutions`: verify what is visible to students.
- `outputFormat`: confirm the simplest format before using more complex formats.

## When to use local testing

| Situation | Use local testing |
| --- | --- |
| ADAPT says "error" with no details | Render locally to see line level errors |
| Randomized problem behaves inconsistently | Set a seed and render several variants |
| You changed macros or contexts | Render once locally before importing |
| You are trying a new interaction type | Confirm it renders in the simplest format first |

## Troubleshooting basics

- Check `http://localhost:3000/health` to confirm the renderer is up.
- If it is down, check container logs with `podman-compose logs -f`.
- Two common failures are the wrong file path and missing macros.

## Maintainers only

If you maintain the renderer, start with the [code architecture guide](CODE_ARCHITECTURE.md)
and the [file structure guide](FILE_STRUCTURE.md).
